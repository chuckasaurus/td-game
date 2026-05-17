class_name BuildManager
extends Node

@export var tower_scene: PackedScene
@export var grid_node: NodePath = ^"../GridManager"
@export var towers_container_node: NodePath = ^"../Towers"

var grid: GridManager = null
var towers_container: Node = null
var _selected_tower_data: TowerData = null


func _ready() -> void:
	grid = get_node_or_null(grid_node) as GridManager
	towers_container = get_node_or_null(towers_container_node)
	if grid == null:
		push_error("BuildManager could not resolve grid_node=%s" % str(grid_node))
	if towers_container == null:
		push_warning("BuildManager towers_container not found; defaulting to current scene")
	EventBus.tower_button_selected.connect(_on_tower_button_selected)


func _unhandled_input(event: InputEvent) -> void:
	if grid == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_tower_data == null:
			return
		var world_pos := grid.get_global_mouse_position()
		var cell := grid.world_to_cell(world_pos)
		_attempt_build(cell)


func _on_tower_button_selected(tower_data: Resource) -> void:
	_selected_tower_data = tower_data as TowerData


func _attempt_build(cell: Vector2i) -> void:
	if not grid.is_buildable(cell):
		return
	if not GameState.spend_gold(_selected_tower_data.cost):
		return
	var tower := tower_scene.instantiate() as Node2D
	var parent: Node = towers_container if towers_container else get_tree().current_scene
	parent.add_child(tower)
	tower.global_position = grid.cell_to_world_center(cell)
	if tower.has_method("configure"):
		tower.configure(_selected_tower_data)
	grid.set_occupied(cell, tower)
	EventBus.tower_placed.emit(tower)
