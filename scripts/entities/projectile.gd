class_name Projectile
extends Area2D

var _target: Enemy = null
var _speed: float = 400.0
var _hit: DamageHit = null
var _splash_radius: float = 0.0
var _last_dir: Vector2 = Vector2.ZERO
var _life_remaining: float = 3.0

@onready var body: Polygon2D = $Body


func launch(target: Enemy, tower_data: TowerData) -> void:
	_target = target
	_speed = tower_data.projectile_speed
	_hit = DamageHit.from_tower(tower_data)
	_splash_radius = tower_data.splash_radius
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


func _on_body_entered(node: Node) -> void:
	_try_hit(node)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())


func _try_hit(node: Node) -> void:
	if node is Enemy and node == _target:
		_resolve_hit(node)
		queue_free()


func _resolve_hit(primary: Enemy) -> void:
	primary.take_damage(_hit)
	# AoE splash: hit other enemies within radius.
	if _splash_radius > 0.0:
		var enemies_in_scene := get_tree().get_nodes_in_group(&"enemies")
		# Fallback: walk the path's children if no group set.
		if enemies_in_scene.is_empty():
			for n in get_tree().current_scene.find_children("", "PathFollow2D", true, false):
				enemies_in_scene.append(n)
		for n in enemies_in_scene:
			if n == primary or not (n is Enemy) or not is_instance_valid(n):
				continue
			if n.global_position.distance_to(global_position) <= _splash_radius:
				n.take_damage(_hit)
