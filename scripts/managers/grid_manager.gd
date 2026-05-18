class_name GridManager
extends Node2D

# Ground tile variants. Each non-path cell deterministically picks one based
# on its coordinates so the map renders identically each load. Add new
# variants to the bottom of the list to grow the rotation; do not reorder
# existing entries or cells will swap textures.
const GROUND_TILES: Array[Texture2D] = [
	preload("res://assets/sprites/tiles/ground/tile_ground_basic.png"),
]

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
var _selected_tower: Node = null


func _ready() -> void:
	_build_path_cells()
	_spawn_ground_sprites()
	EventBus.tower_clicked.connect(_on_tower_clicked)
	EventBus.tower_buffs_changed.connect(_on_tower_buffs_changed)
	EventBus.tower_sold.connect(_on_tower_sold)
	EventBus.tower_inspector_closed.connect(_on_inspector_closed)
	queue_redraw()


func _spawn_ground_sprites() -> void:
	# One Sprite2D per non-path cell. show_behind_parent renders the sprites
	# BEFORE GridManager's own _draw() output, so path-cell brown rects, grid
	# lines, hover highlights, and range rings all layer on top of the ground.
	var variant_count := GROUND_TILES.size()
	for col in range(columns):
		for row in range(rows):
			var cell := Vector2i(col, row)
			if is_path(cell):
				continue
			var sprite := Sprite2D.new()
			sprite.texture = GROUND_TILES[_ground_variant_for(cell, variant_count)]
			sprite.position = cell_to_world_center(cell)
			sprite.show_behind_parent = true
			# Pixel-art friendly: no smoothing on the upscaled tile.
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sprite)


func _ground_variant_for(cell: Vector2i, variant_count: int) -> int:
	# Deterministic per-cell variant pick. Same cell -> same variant on every
	# load. Two distinct primes per axis avoid obvious diagonal patterns.
	if variant_count <= 1:
		return 0
	var h := cell.x * 73 + cell.y * 179
	return ((h % variant_count) + variant_count) % variant_count


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


func get_occupant(cell: Vector2i) -> Node:
	return _occupied.get(cell)


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
		# Range ring preview at hover cell
		if preview_range_radius > 0.0:
			var center := cell_to_world_center(_hover_cell)
			var fill := Color(preview_range_color.r, preview_range_color.g, preview_range_color.b, 0.10)
			var outline := Color(preview_range_color.r, preview_range_color.g, preview_range_color.b, 0.7)
			draw_circle(center, preview_range_radius, fill)
			draw_arc(center, preview_range_radius, 0.0, TAU, 64, outline, 2.0)

	# Range ring around the currently-selected tower
	if _selected_tower and is_instance_valid(_selected_tower) and _selected_tower.effective_data:
		var ed: TowerData = _selected_tower.effective_data
		if ed.range_radius > 0.0:
			var sel_color: Color = ed.element.color if ed.element else Color(0.9, 0.85, 0.55, 1)
			var sel_fill := Color(sel_color.r, sel_color.g, sel_color.b, 0.08)
			var sel_outline := Color(sel_color.r, sel_color.g, sel_color.b, 0.7)
			draw_circle(_selected_tower.global_position, ed.range_radius, sel_fill)
			draw_arc(_selected_tower.global_position, ed.range_radius, 0.0, TAU, 64, sel_outline, 2.0)


func set_preview_range(radius: float, color: Color) -> void:
	preview_range_radius = radius
	preview_range_color = color
	queue_redraw()


func _on_tower_clicked(tower: Node) -> void:
	_selected_tower = tower
	queue_redraw()


func _on_tower_buffs_changed(tower: Node) -> void:
	if tower == _selected_tower:
		queue_redraw()


func _on_tower_sold(tower: Node, _refund: int) -> void:
	if tower == _selected_tower:
		_selected_tower = null
		queue_redraw()


func _on_inspector_closed() -> void:
	_selected_tower = null
	queue_redraw()
