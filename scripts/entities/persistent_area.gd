class_name PersistentArea
extends Node2D

@export var lifetime: float = 4.0
@export var radius: float = 60.0
@export var tick_interval: float = 0.5
@export var damage_per_tick: int = 2
@export var status_template: StatusEffect = null
@export var area_color: Color = Color(0.5, 0.85, 0.3, 0.4)

var _time_remaining: float = 0.0
var _tick_acc: float = 0.0
var _enemies_inside: Array[Enemy] = []

@onready var area: Area2D = $Area
@onready var collision_shape: CollisionShape2D = $Area/CollisionShape2D
@onready var visual: Polygon2D = $Visual


func configure(p_radius: float, p_lifetime: float, p_damage: int, p_tick: float, p_status: StatusEffect, p_color: Color) -> void:
	radius = p_radius
	lifetime = p_lifetime
	damage_per_tick = p_damage
	tick_interval = p_tick
	status_template = p_status
	area_color = p_color
	if is_node_ready():
		_apply_config()


func _ready() -> void:
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)
	_apply_config()


func _apply_config() -> void:
	_time_remaining = lifetime
	_tick_acc = 0.0
	# Size collision shape
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	# Generate visual polygon
	visual.color = area_color
	visual.polygon = _make_circle(radius, 24)


func _make_circle(r: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var ang: float = float(i) * TAU / float(sides)
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	return pts


func _process(delta: float) -> void:
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		queue_free()
		return
	_tick_acc += delta
	while _tick_acc >= tick_interval:
		_tick_acc -= tick_interval
		_apply_tick()


func _apply_tick() -> void:
	_enemies_inside = _enemies_inside.filter(func(e): return is_instance_valid(e))
	for enemy in _enemies_inside:
		if damage_per_tick > 0:
			enemy.take_dot_damage(damage_per_tick)
		if status_template:
			enemy.apply_status(status_template)


func _on_area_entered(other: Area2D) -> void:
	var enemy := other.get_parent() as Enemy
	if enemy and not _enemies_inside.has(enemy):
		_enemies_inside.append(enemy)
		# Apply once on entry (covers the case where an enemy passes through
		# faster than tick_interval).
		if status_template:
			enemy.apply_status(status_template)


func _on_area_exited(other: Area2D) -> void:
	var enemy := other.get_parent() as Enemy
	if enemy:
		_enemies_inside.erase(enemy)
