class_name LinearProjectile
extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 280.0
var _lifetime: float = 1.8
var _hit_template: DamageHit = null
var _pierce_falloff: float = 1.0
var _hit_already: Array[Enemy] = []

@onready var body: Polygon2D = $Body


func launch(start_direction: Vector2, tower_data: TowerData) -> void:
	_direction = start_direction.normalized() if start_direction.length() > 0.0 else Vector2.RIGHT
	_speed = tower_data.linear_speed
	_lifetime = tower_data.linear_lifetime
	_pierce_falloff = tower_data.linear_pierce_falloff
	_hit_template = DamageHit.from_tower(tower_data)
	if body:
		body.color = tower_data.projectile_color
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	global_position += _direction * _speed * delta
	rotation = _direction.angle()


func _on_area_entered(other: Area2D) -> void:
	_try_hit(other.get_parent() as Enemy)


func _on_body_entered(node: Node) -> void:
	if node is Enemy:
		_try_hit(node)


func _try_hit(enemy: Enemy) -> void:
	if enemy == null or _hit_already.has(enemy) or not is_instance_valid(enemy):
		return
	_hit_already.append(enemy)
	# Build a hit with falloff applied for this pierce index
	var pierces := _hit_already.size() - 1
	var falloff_mult := pow(_pierce_falloff, pierces)
	var hit := DamageHit.new()
	hit.amount = int(round(float(_hit_template.amount) * falloff_mult))
	hit.element_id = _hit_template.element_id
	hit.armor_pen = _hit_template.armor_pen
	hit.crit_chance = _hit_template.crit_chance
	hit.crit_multiplier = _hit_template.crit_multiplier
	hit.on_hit_status = _hit_template.on_hit_status
	enemy.take_damage(hit)
