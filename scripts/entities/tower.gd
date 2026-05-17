class_name Tower
extends Node2D

@export var data: TowerData
@export var projectile_scene: PackedScene

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
	# Color the tower body from its element (or fall back to default).
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
	# Filter: flying enemies only targetable by towers with can_target_flying;
	# stunned enemies are temporarily un-targetable.
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


func _fire(target: Enemy) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position if muzzle else global_position
	if proj.has_method("launch"):
		proj.launch(target, data)
