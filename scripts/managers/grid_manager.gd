class_name GridManager
extends Node2D

## Origin (top-left corner) of the grid in world coordinates.
@export var grid_origin: Vector2 = Vector2(0, 64)
@export var cell_size: int = 64
@export var columns: int = 30
@export var rows: int = 14

## Path waypoints in CELL coordinates. Adjacent waypoints must share a row or column.
@export var path_waypoints: Array[Vector2i] = []

@export var path_color: Color = Color(0.27, 0.23, 0.18, 1)
@export var grid_line_color: Color = Color(1, 1, 1, 0.06)
@export var grid_border_color: Color = Color(1, 1, 1, 0.18)
@export var hover_ok_color: Color = Color(0.3, 1, 0.4, 0.35)
@export var hover_bad_color: Color = Color(1, 0.3, 0.3, 0.30)

## Set by BuildManager when a tower is selected. > 0 = draw range ring at hover cell.
var preview_range_radius: float = 0.0
var preview_range_color: Color = Color(1, 1, 1, 1)

var _path_cells: Dictionary = {}
var _occupied: Dictionary = {}
var _hover_cell: Vector2i = Vector2i(-9999, -9999)


func _ready() -> void:
	_build_path_cells()
	queue_redraw()


func _process(_delta: float) -> void:
	var mouse := get_global_mouse_position()
	var cell := world_to_cell(mouse)
	if cell != _hover_cell:
		_hover_cell = cell
		queue_redraw()


func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := world_pos - grid_origin
	return Vector2i(floori(local.x / float(cell_size)), floori(local.y / float(cell_size)))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(
		cell.x * cell_size + cell_size * 0.5,
		cell.y * cell_size + cell_size * 0.5
	)


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows


func is_path(cell: Vector2i) -> bool:
	return _path_cells.has(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


func is_buildable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not is_path(cell) and not is_occupied(cell)


func set_occupied(cell: Vector2i, occupant: Node) -> void:
	_occupied[cell] = occupant
	queue_redraw()


func clear_occupied(cell: Vector2i) -> void:
	_occupied.erase(cell)
	queue_redraw()


func _build_path_cells() -> void:
	_path_cells.clear()
	for i in path_waypoints.size() - 1:
		_mark_segment(path_waypoints[i], path_waypoints[i + 1])


func _mark_segment(a: Vector2i, b: Vector2i) -> void:
	if a.x == b.x:
		var lo := mini(a.y, b.y)
		var hi := maxi(a.y, b.y)
		for y in range(lo, hi + 1):
			_path_cells[Vector2i(a.x, y)] = true
	elif a.y == b.y:
		var lo := mini(a.x, b.x)
		var hi := maxi(a.x, b.x)
		for x in range(lo, hi + 1):
			_path_cells[Vector2i(x, a.y)] = true
	else:
		push_warning("Diagonal path segment from %s to %s not supported" % [a, b])


func _draw() -> void:
	var origin := grid_origin
	var size := Vector2(cell_size, cell_size)
	# Path cells: solid fill
	for cell_key in _path_cells:
		var cell: Vector2i = cell_key
		draw_rect(Rect2(origin + Vector2(cell.x * cell_size, cell.y * cell_size), size), path_color)
	# Interior grid lines (subtle)
	for x in range(1, columns):
		var xpos: float = origin.x + x * cell_size
		draw_line(Vector2(xpos, origin.y), Vector2(xpos, origin.y + rows * cell_size), grid_line_color)
	for y in range(1, rows):
		var ypos: float = origin.y + y * cell_size
		draw_line(Vector2(origin.x, ypos), Vector2(origin.x + columns * cell_size, ypos), grid_line_color)
	# Border
	draw_rect(Rect2(origin, Vector2(columns * cell_size, rows * cell_size)), grid_border_color, false, 2.0)
	# Hover highlight
	if is_in_bounds(_hover_cell):
		var hover_color := hover_ok_color if is_buildable(_hover_cell) else hover_bad_color
		var hover_top_left := origin + Vector2(_hover_cell.x * cell_size, _hover_cell.y * cell_size)
		draw_rect(Rect2(hover_top_left, size), hover_color)
		# Range ring preview
		if preview_range_radius > 0.0:
			var center := cell_to_world_center(_hover_cell)
			var fill := Color(preview_range_color.r, preview_range_color.g, preview_range_color.b, 0.10)
			var outline := Color(preview_range_color.r, preview_range_color.g, preview_range_color.b, 0.7)
			draw_circle(center, preview_range_radius, fill)
			draw_arc(center, preview_range_radius, 0.0, TAU, 64, outline, 2.0)


func set_preview_range(radius: float, color: Color) -> void:
	preview_range_radius = radius
	preview_range_color = color
	queue_redraw()
