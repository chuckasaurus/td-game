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
	EventBus.tower_sold.connect(_on_tower_sold)
	EventBus.tower_clicked.connect(_on_tower_clicked)


func _unhandled_input(event: InputEvent) -> void:
	if grid == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_tower_data == null:
			# Clicking empty grid with no build selection closes the inspector.
			EventBus.tower_inspector_closed.emit()
			return
		var world_pos := grid.get_global_mouse_position()
		var cell := grid.world_to_cell(world_pos)
		_attempt_build(cell)


func _on_tower_button_selected(tower_data: Resource) -> void:
	_selected_tower_data = tower_data as TowerData
	if grid:
		if _selected_tower_data:
			var color: Color = _selected_tower_data.element.color if _selected_tower_data.element else Color(0.95, 0.85, 0.55, 1)
			grid.set_preview_range(_selected_tower_data.range_radius, color)
		else:
			grid.set_preview_range(0.0, Color.WHITE)


func _on_tower_clicked(_tower: Node) -> void:
	# When player selects an existing tower, drop any pending placement.
	_selected_tower_data = null
	if grid:
		grid.set_preview_range(0.0, Color.WHITE)


func _on_tower_sold(tower: Node, refund: int) -> void:
	GameState.add_gold(refund)
	if grid and tower is Tower:
		var cell: Vector2i = tower.grid_cell
		if cell.x >= 0 and cell.y >= 0:
			grid.clear_occupied(cell)


func _attempt_build(cell: Vector2i) -> void:
	if not grid.is_buildable(cell):
		return
	if not GameState.spend_gold(_selected_tower_data.cost):
		return
	var tower := tower_scene.instantiate() as Tower
	var parent: Node = towers_container if towers_container else get_tree().current_scene
	parent.add_child(tower)
	tower.global_position = grid.cell_to_world_center(cell)
	tower.grid_cell = cell
	tower.configure(_selected_tower_data)
	grid.set_occupied(cell, tower)
	EventBus.tower_placed.emit(tower)
