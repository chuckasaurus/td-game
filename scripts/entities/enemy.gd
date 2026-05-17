class_name Enemy
extends PathFollow2D

const FROZEN_TEMPLATE: StatusEffect = preload("res://data/statuses/frozen.tres")

signal hp_changed(current: int, max_hp: int)
signal armor_changed(current: int, max_armor: int)
signal died(enemy: Enemy)

@export var data: EnemyData

var current_hp: int = 0
var current_armor: int = 0
var _is_dead: bool = false
var _statuses: Array[StatusInstance] = []

@onready var body: Polygon2D = $Body
@onready var hp_bar: ProgressBar = $Bars/HpBar
@onready var armor_bar: ProgressBar = $Bars/ArmorBar


func _ready() -> void:
	loop = false
	rotates = false
	if data:
		_apply_data()


func configure(enemy_data: EnemyData) -> void:
	data = enemy_data
	if is_node_ready():
		_apply_data()


func _apply_data() -> void:
	current_hp = data.max_hp
	current_armor = data.max_armor
	if body:
		body.color = data.color_tint
		# Flying enemies float visually above the path.
		body.position = Vector2(0, -32) if data.is_flying else Vector2.ZERO
	_refresh_hp_bar()
	_refresh_armor_bar()


func _process(delta: float) -> void:
	if _is_dead or data == null:
		return
	_process_statuses(delta)
	var mult := _current_speed_mult()
	if mult > 0.0:
		progress += data.speed * mult * delta
		if progress_ratio >= 1.0:
			_escape()


# ─── Status handling ──────────────────────────────────────────────────────

func _process_statuses(delta: float) -> void:
	var expired: Array[StatusInstance] = []
	for instance in _statuses:
		if instance.tick(self, delta):
			expired.append(instance)
	for instance in expired:
		instance.effect.on_expire(self, instance)
		_statuses.erase(instance)


func _current_speed_mult() -> float:
	if has_status(&"stunned"):
		return 0.0
	var mult := 1.0
	for instance in _statuses:
		match instance.effect.id:
			&"frozen":
				mult = minf(mult, 0.05)
			&"slowed":
				mult = minf(mult, 1.0 - instance.effect.magnitude)
	return mult


func apply_status(template: StatusEffect) -> void:
	if template == null:
		return
	var existing := _find_status(template.id)
	if existing:
		existing.refresh()
		return
	var instance := StatusInstance.new(template)
	_statuses.append(instance)
	template.on_apply(self, instance)


func has_status(id: StringName) -> bool:
	return _find_status(id) != null


func remove_status(id: StringName) -> void:
	var inst := _find_status(id)
	if inst:
		inst.effect.on_expire(self, inst)
		_statuses.erase(inst)


func _find_status(id: StringName) -> StatusInstance:
	for i in _statuses:
		if i.effect.id == id:
			return i
	return null


# ─── Damage ───────────────────────────────────────────────────────────────

func take_damage(hit: DamageHit) -> void:
	if _is_dead or hit == null:
		return
	var amt := float(hit.amount)
	# Crit roll
	if hit.crit_chance > 0.0 and randf() < hit.crit_chance:
		amt *= hit.crit_multiplier
	# Wet + Electric amp
	if has_status(&"wet") and hit.element_id == &"electric":
		amt *= 1.5
	# Magic resistance vs status-bearing hits
	if data.magic_resistant and hit.on_hit_status != null:
		amt *= 0.5
	var amount := int(round(amt))
	# Armor pen: some damage skips the armor pool entirely.
	var bypass := int(round(float(amount) * hit.armor_pen))
	var to_armor_pool := amount - bypass
	_direct_damage(bypass)
	if _is_dead:
		return
	if current_armor > 0 and to_armor_pool > 0:
		var absorbed := mini(current_armor, to_armor_pool)
		current_armor -= absorbed
		to_armor_pool -= absorbed
		_refresh_armor_bar()
	_direct_damage(to_armor_pool)
	if _is_dead:
		return
	# Status application
	if hit.on_hit_status:
		apply_status(hit.on_hit_status)
	# Frozen trigger: Wet + Ice hit = auto-freeze
	if hit.element_id == &"ice" and has_status(&"wet"):
		apply_status(FROZEN_TEMPLATE)


func take_dot_damage(amount: int) -> void:
	# DoT ticks chip HP directly, bypassing armor and status routing.
	if _is_dead:
		return
	_direct_damage(amount)


func apply_knockback(units: float) -> void:
	progress = maxf(0.0, progress - units)


func _direct_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = maxi(0, current_hp - amount)
	_refresh_hp_bar()
	if current_hp <= 0:
		_die()


func _refresh_hp_bar() -> void:
	if hp_bar and data:
		hp_bar.max_value = data.max_hp
		hp_bar.value = current_hp
	hp_changed.emit(current_hp, data.max_hp if data else 0)


func _refresh_armor_bar() -> void:
	if armor_bar and data:
		armor_bar.max_value = maxi(1, data.max_armor)
		armor_bar.value = current_armor
		armor_bar.visible = data.max_armor > 0
	armor_changed.emit(current_armor, data.max_armor if data else 0)


# ─── Lifecycle ────────────────────────────────────────────────────────────

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	EventBus.enemy_killed.emit(self, data.gold_reward)
	died.emit(self)
	queue_free()


func _escape() -> void:
	if _is_dead:
		return
	_is_dead = true
	EventBus.enemy_escaped.emit(self)
	queue_free()
