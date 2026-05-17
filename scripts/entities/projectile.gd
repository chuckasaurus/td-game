class_name Projectile
extends Area2D

var _target: Enemy = null
var _speed: float = 400.0
var _damage: int = 10
var _last_dir: Vector2 = Vector2.ZERO
var _life_remaining: float = 3.0

@onready var body: Polygon2D = $Body


func launch(target: Enemy, tower_data: TowerData) -> void:
	_target = target
	_speed = tower_data.projectile_speed
	_damage = tower_data.damage
	if body:
		body.color = tower_data.projectile_color
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return
	var dir: Vector2
	if is_instance_valid(_target):
		dir = (_target.global_position - global_position).normalized()
		_last_dir = dir
	elif _last_dir != Vector2.ZERO:
		dir = _last_dir
	else:
		queue_free()
		return
	global_position += dir * _speed * delta
	rotation = dir.angle()


func _on_body_entered(_body_node: Node) -> void:
	_try_hit(_body_node)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())


func _try_hit(node: Node) -> void:
	if node is Enemy and node == _target:
		node.take_damage(_damage)
		queue_free()
