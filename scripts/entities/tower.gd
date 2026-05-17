class_name Tower
extends Node2D

@export var data: TowerData
## Used for HOMING and CLOUD_DROP attack kinds.
@export var homing_projectile_scene: PackedScene
## Used for LINEAR_PIERCE.
@export var linear_projectile_scene: PackedScene

var _enemies_in_range: Array[Node] = []
var _cooldown: float = 0.0

@onready var body: Polygon2D = $Body
@onready var body_accent: Polygon2D = $BodyAccent
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle


func configure(tower_data: TowerData) -> void:
	data = tower_data
	if is_node_ready():
		_apply_data()


func _ready() -> void:
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	if data:
		_apply_data()


func _apply_data() -> void:
	var shape := range_shape.shape as CircleShape2D
	if shape:
		shape.radius = data.range_radius
	if data.element and body:
		var c := data.element.color
		body.color = c
		if body_accent:
			body_accent.color = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 1)


func _process(delta: float) -> void:
	if data == null:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	if _cooldown <= 0.0:
		var target := _pick_target()
		if target:
			_fire(target)
			_cooldown = 1.0 / maxf(0.01, data.fire_rate)


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
		if e.data.is_flying and not data.can_target_flying:
			continue
		if e.has_status(&"stunned"):
			continue
		if e.progress_ratio > best_progress:
			best = e
			best_progress = e.progress_ratio
	return best


# ─── Attack dispatcher ────────────────────────────────────────────────────

func _fire(target: Enemy) -> void:
	match data.attack_kind:
		TowerData.AttackKind.LINEAR_PIERCE:
			_fire_linear(target)
		TowerData.AttackKind.BEAM_CHAIN:
			_fire_beam_chain(target)
		_:
			# HOMING and CLOUD_DROP both use the homing carrier projectile
			_fire_homing(target)


func _fire_homing(target: Enemy) -> void:
	if homing_projectile_scene == null:
		return
	var proj := homing_projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position if muzzle else global_position
	if proj.has_method("launch"):
		proj.launch(target, data)


func _fire_linear(target: Enemy) -> void:
	if linear_projectile_scene == null:
		return
	var origin: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - origin).normalized()
	var proj := linear_projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = origin
	if proj.has_method("launch"):
		proj.launch(dir, data)


func _fire_beam_chain(primary: Enemy) -> void:
	var origin: Vector2 = muzzle.global_position if muzzle else global_position
	var hit_chain: Array[Enemy] = []
	_zap(primary, 1.0, origin)
	hit_chain.append(primary)
	var prev_pos := primary.global_position
	var remaining: int = data.chain_targets - 1 if data.chain_targets > 0 else 0
	var current_decay := 1.0
	while remaining > 0:
		current_decay *= data.chain_decay
		var next := _find_nearest_chain_target(prev_pos, hit_chain)
		if next == null:
			break
		_zap(next, current_decay, prev_pos)
		hit_chain.append(next)
		prev_pos = next.global_position
		remaining -= 1


func _zap(enemy: Enemy, dmg_mult: float, beam_from: Vector2) -> void:
	var base_hit := DamageHit.from_tower(data)
	var hit := DamageHit.new()
	hit.amount = int(round(float(base_hit.amount) * dmg_mult))
	hit.element_id = base_hit.element_id
	hit.armor_pen = base_hit.armor_pen
	hit.crit_chance = base_hit.crit_chance
	hit.crit_multiplier = base_hit.crit_multiplier
	hit.on_hit_status = base_hit.on_hit_status
	enemy.take_damage(hit)
	_spawn_beam_segment(beam_from, enemy.global_position, data.projectile_color)


func _find_nearest_chain_target(from: Vector2, exclude: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if not (e is Enemy) or not is_instance_valid(e):
			continue
		if exclude.has(e):
			continue
		if e.data.is_flying and not data.can_target_flying:
			continue
		if e.has_status(&"stunned"):
			continue
		var d := from.distance_to(e.global_position)
		if d <= data.chain_range and d < best_dist:
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
