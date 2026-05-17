class_name Projectile
extends Area2D

const PERSISTENT_AREA_SCENE: PackedScene = preload("res://scenes/entities/persistent_area.tscn")

var _target: Enemy = null
var _speed: float = 400.0
var _hit: DamageHit = null
var _splash_radius: float = 0.0
var _last_dir: Vector2 = Vector2.ZERO
var _life_remaining: float = 3.0

# CLOUD_DROP fields (set when carrier is a cloud-spawning tower)
var _spawns_cloud: bool = false
var _cloud_radius: float = 0.0
var _cloud_duration: float = 0.0
var _cloud_damage: int = 0
var _cloud_tick: float = 0.5
var _cloud_status: StatusEffect = null
var _cloud_color: Color = Color(1, 1, 1, 0.4)

@onready var body: Polygon2D = $Body


func launch(target: Enemy, tower_data: TowerData) -> void:
	_target = target
	_speed = tower_data.projectile_speed
	_hit = DamageHit.from_tower(tower_data)
	_splash_radius = tower_data.splash_radius
	if body:
		body.color = tower_data.projectile_color
	if tower_data.attack_kind == TowerData.AttackKind.CLOUD_DROP:
		_spawns_cloud = true
		_cloud_radius = tower_data.cloud_radius
		_cloud_duration = tower_data.cloud_duration
		_cloud_damage = tower_data.cloud_damage_per_tick
		_cloud_tick = tower_data.cloud_tick_interval
		_cloud_status = tower_data.on_hit_status
		var base_color: Color = tower_data.element.color if tower_data.element else Color.WHITE
		_cloud_color = Color(base_color.r, base_color.g, base_color.b, 0.35)
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
	# Splash to other enemies in radius (HOMING only — cloud-drops are zone-based)
	if _splash_radius > 0.0 and not _spawns_cloud:
		for n in get_tree().get_nodes_in_group(&"enemies"):
			if n == primary or not (n is Enemy) or not is_instance_valid(n):
				continue
			if n.global_position.distance_to(global_position) <= _splash_radius:
				n.take_damage(_hit)
	# CLOUD_DROP: spawn persistent area at impact point
	if _spawns_cloud:
		var cloud := PERSISTENT_AREA_SCENE.instantiate() as PersistentArea
		get_tree().current_scene.add_child(cloud)
		cloud.global_position = global_position
		cloud.configure(_cloud_radius, _cloud_duration, _cloud_damage, _cloud_tick, _cloud_status, _cloud_color)
