class_name Tower
extends Node2D

@export var base_data: TowerData
## Used for HOMING and CLOUD_DROP attack kinds.
@export var homing_projectile_scene: PackedScene
## Used for LINEAR_PIERCE.
@export var linear_projectile_scene: PackedScene

## Computed at runtime: base_data + all applied buffs (instance + slot + class).
## All gameplay code reads from this, not base_data.
var effective_data: TowerData

var instance_buffs: Array[TowerBuff] = []
var slot_buff: TowerBuff = null
var grid_cell: Vector2i = Vector2i(-1, -1)

var _enemies_in_range: Array[Node] = []
var _cooldown: float = 0.0
var _ambient_particles: Node2D = null

@onready var body: Sprite2D = $Body
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle


func configure(tower_data: TowerData) -> void:
	base_data = tower_data
	if is_node_ready():
		_apply_visual_from_data()
		_recompute_effective_data()


func _ready() -> void:
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	BuffRegistry.class_buffs_changed.connect(_recompute_effective_data)
	if base_data:
		_apply_visual_from_data()
		_recompute_effective_data()


func _apply_visual_from_data() -> void:
	if body and base_data.sprite:
		body.texture = base_data.sprite
	# Ambient particle overlay — idempotent: drop the previous instance if any.
	if _ambient_particles and is_instance_valid(_ambient_particles):
		_ambient_particles.queue_free()
		_ambient_particles = null
	if base_data.ambient_particles_scene:
		_ambient_particles = base_data.ambient_particles_scene.instantiate()
		add_child(_ambient_particles)


# ─── Buff layer ───────────────────────────────────────────────────────────

func add_instance_buff(buff: TowerBuff) -> void:
	if buff == null or instance_buffs.has(buff):
		return
	instance_buffs.append(buff)
	_recompute_effective_data()


func remove_instance_buff(buff: TowerBuff) -> void:
	if instance_buffs.has(buff):
		instance_buffs.erase(buff)
		_recompute_effective_data()


func equip_slot(buff: TowerBuff) -> TowerBuff:
	var previous := slot_buff
	slot_buff = buff
	_recompute_effective_data()
	return previous


func unequip_slot() -> TowerBuff:
	var previous := slot_buff
	slot_buff = null
	_recompute_effective_data()
	return previous


func all_active_buffs() -> Array[TowerBuff]:
	var all: Array[TowerBuff] = []
	all.append_array(instance_buffs)
	if slot_buff:
		all.append(slot_buff)
	all.append_array(BuffRegistry.get_buffs_for(base_data))
	return all


func _recompute_effective_data() -> void:
	if base_data == null:
		return
	effective_data = base_data.duplicate() as TowerData
	var buffs := all_active_buffs()

	# Additives first
	for b in buffs:
		effective_data.range_radius += b.add_range
		effective_data.damage += b.add_damage
		effective_data.armor_pen += b.add_armor_pen
		effective_data.crit_chance += b.add_crit_chance
		effective_data.crit_multiplier += b.add_crit_multiplier

	# Percentile modifiers (additive within category)
	var range_pct := 0.0
	var damage_pct := 0.0
	var fire_rate_pct := 0.0
	var projectile_speed_pct := 0.0
	for b in buffs:
		range_pct += b.add_range_pct
		damage_pct += b.add_damage_pct
		fire_rate_pct += b.add_fire_rate_pct
		projectile_speed_pct += b.add_projectile_speed_pct
	effective_data.range_radius *= (1.0 + range_pct)
	effective_data.damage = int(round(float(effective_data.damage) * (1.0 + damage_pct)))
	effective_data.fire_rate *= (1.0 + fire_rate_pct)
	effective_data.projectile_speed *= (1.0 + projectile_speed_pct)

	# Imbues
	for b in buffs:
		if b.imbue_status and effective_data.on_hit_status == null:
			effective_data.on_hit_status = b.imbue_status
			effective_data.status_chance = b.imbue_status_chance
		if b.imbue_splash_radius > 0.0:
			effective_data.splash_radius = maxf(effective_data.splash_radius, b.imbue_splash_radius)
		if b.grants_anti_air:
			effective_data.can_target_flying = true

	# Cap pen/crit chance at sane values
	effective_data.armor_pen = clampf(effective_data.armor_pen, 0.0, 1.0)
	effective_data.crit_chance = clampf(effective_data.crit_chance, 0.0, 1.0)

	_resize_range_area()
	EventBus.tower_buffs_changed.emit(self)


func _resize_range_area() -> void:
	if range_shape == null or effective_data == null:
		return
	var shape := range_shape.shape as CircleShape2D
	if shape:
		# Duplicate the shape so per-tower resizing doesn't mutate the shared resource
		var new_shape := CircleShape2D.new()
		new_shape.radius = effective_data.range_radius
		range_shape.shape = new_shape


# ─── Targeting / firing ───────────────────────────────────────────────────

func _process(delta: float) -> void:
	if effective_data == null:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	if _cooldown <= 0.0:
		var target := _pick_target()
		if target:
			_fire(target)
			_cooldown = 1.0 / maxf(0.01, effective_data.fire_rate)


func _on_body_entered(body_node: Node) -> void:
	if body_node is Enemy:
		_enemies_in_range.append(body_node)


func _on_body_exited(body_node: Node) -> void:
	_enemies_in_range.erase(body_node)


func _on_area_entered(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy and not _enemies_in_range.has(enemy):
		_enemies_in_range.append(enemy)


func _on_area_exited(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy:
		_enemies_in_range.erase(enemy)


func _enemy_from_area(area: Area2D) -> Enemy:
	var p := area.get_parent()
	if p is Enemy:
		return p
	return null


func _pick_target() -> Enemy:
	_enemies_in_range = _enemies_in_range.filter(func(e): return is_instance_valid(e))
	if _enemies_in_range.is_empty():
		return null
	var best: Enemy = null
	var best_progress := -INF
	for e in _enemies_in_range:
		if not (e is Enemy):
			continue
		if e.data.is_flying and not effective_data.can_target_flying:
			continue
		if e.has_status(&"stunned"):
			continue
		if e.progress_ratio > best_progress:
			best = e
			best_progress = e.progress_ratio
	return best


func _fire(target: Enemy) -> void:
	match effective_data.attack_kind:
		TowerData.AttackKind.LINEAR_PIERCE:
			_fire_linear(target)
		TowerData.AttackKind.BEAM_CHAIN:
			_fire_beam_chain(target)
		_:
			_fire_homing(target)


func _fire_homing(target: Enemy) -> void:
	if homing_projectile_scene == null:
		return
	var proj := homing_projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position if muzzle else global_position
	if proj.has_method("launch"):
		proj.launch(target, effective_data)


func _fire_linear(target: Enemy) -> void:
	if linear_projectile_scene == null:
		return
	var origin: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - origin).normalized()
	var proj := linear_projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = origin
	if proj.has_method("launch"):
		proj.launch(dir, effective_data)


func _fire_beam_chain(primary: Enemy) -> void:
	var origin: Vector2 = muzzle.global_position if muzzle else global_position
	var hit_chain: Array[Enemy] = []
	_zap(primary, 1.0, origin)
	hit_chain.append(primary)
	var prev_pos := primary.global_position
	var remaining: int = effective_data.chain_targets - 1 if effective_data.chain_targets > 0 else 0
	var current_decay := 1.0
	while remaining > 0:
		current_decay *= effective_data.chain_decay
		var next := _find_nearest_chain_target(prev_pos, hit_chain)
		if next == null:
			break
		_zap(next, current_decay, prev_pos)
		hit_chain.append(next)
		prev_pos = next.global_position
		remaining -= 1


func _zap(enemy: Enemy, dmg_mult: float, beam_from: Vector2) -> void:
	var base_hit := DamageHit.from_tower(effective_data)
	var hit := DamageHit.new()
	hit.amount = int(round(float(base_hit.amount) * dmg_mult))
	hit.element_id = base_hit.element_id
	hit.armor_pen = base_hit.armor_pen
	hit.crit_chance = base_hit.crit_chance
	hit.crit_multiplier = base_hit.crit_multiplier
	hit.on_hit_status = base_hit.on_hit_status
	enemy.take_damage(hit)
	_spawn_beam_segment(beam_from, enemy.global_position, effective_data.projectile_color)


func _find_nearest_chain_target(from: Vector2, exclude: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if not (e is Enemy) or not is_instance_valid(e):
			continue
		if exclude.has(e):
			continue
		if e.data.is_flying and not effective_data.can_target_flying:
			continue
		if e.has_status(&"stunned"):
			continue
		var d := from.distance_to(e.global_position)
		if d <= effective_data.chain_range and d < best_dist:
			best = e
			best_dist = d
	return best


func _spawn_beam_segment(from: Vector2, to: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.default_color = color
	line.width = 3.0
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	get_tree().current_scene.add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(line.queue_free)


# ─── Sell ─────────────────────────────────────────────────────────────────

func sell() -> void:
	var refund: int = int(round(float(base_data.cost) * 0.75))
	# TODO: when inventory exists, return slot_buff to the inventory pool here.
	EventBus.tower_sold.emit(self, refund)
	queue_free()
