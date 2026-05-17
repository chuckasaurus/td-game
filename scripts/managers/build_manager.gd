class_name BuildManager
extends Node

@export var tower_scene: PackedScene
@export var towers_container: Node

var _selected_tower_data: TowerData = null


func _ready() -> void:
	EventBus.tower_button_selected.connect(_on_tower_button_selected)
	EventBus.build_slot_selected.connect(_on_build_slot_selected)


func _on_tower_button_selected(tower_data: Resource) -> void:
	_selected_tower_data = tower_data as TowerData


func _on_build_slot_selected(slot: Node) -> void:
	if _selected_tower_data == null:
		return
	if slot.has_method("is_occupied") and slot.is_occupied():
		return
	if not GameState.spend_gold(_selected_tower_data.cost):
		return
	var tower := tower_scene.instantiate() as Node2D
	var parent: Node = towers_container if towers_container else get_tree().current_scene
	parent.add_child(tower)
	tower.global_position = slot.global_position
	if tower.has_method("configure"):
		tower.configure(_selected_tower_data)
	if slot.has_method("set_occupied"):
		slot.set_occupied(tower)
	EventBus.tower_placed.emit(tower)
