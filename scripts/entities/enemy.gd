class_name Enemy
extends PathFollow2D

signal hp_changed(current: int, max_hp: int)
signal died(enemy: Enemy)

@export var data: EnemyData

var current_hp: int = 0
var _is_dead: bool = false

@onready var body: Polygon2D = $Body
@onready var hp_bar: ProgressBar = $HpBar


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
	if body:
		body.color = data.color_tint
	if hp_bar:
		hp_bar.max_value = data.max_hp
		hp_bar.value = current_hp
	hp_changed.emit(current_hp, data.max_hp)


func _process(delta: float) -> void:
	if _is_dead or data == null:
		return
	progress += data.speed * delta
	if progress_ratio >= 1.0:
		_escape()


func take_damage(amount: int) -> void:
	if _is_dead:
		return
	var final_dmg := _compute_damage_after_armor(amount)
	current_hp -= final_dmg
	if hp_bar:
		hp_bar.value = current_hp
	hp_changed.emit(current_hp, data.max_hp)
	if current_hp <= 0:
		_die()


func _compute_damage_after_armor(raw: int) -> int:
	# Simple linear armor curve: each armor point reduces 1% damage, cap 80%.
	var reduction := clampf(float(data.armor) * 0.01, 0.0, 0.8)
	return maxi(1, int(round(float(raw) * (1.0 - reduction))))


func _die() -> void:
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
