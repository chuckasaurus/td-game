class_name BuildSlot
extends Area2D

signal slot_clicked(slot: BuildSlot)

var _occupant: Node = null

@onready var marker: Sprite2D = $Marker if has_node("Marker") else null


func _ready() -> void:
	input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		EventBus.build_slot_selected.emit(self)
		slot_clicked.emit(self)


func is_occupied() -> bool:
	return _occupant != null and is_instance_valid(_occupant)


func set_occupied(occupant: Node) -> void:
	_occupant = occupant
	if marker:
		marker.visible = false


func clear() -> void:
	_occupant = null
	if marker:
		marker.visible = true
