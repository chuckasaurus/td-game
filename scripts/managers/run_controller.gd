class_name RunController
extends Node

## All elements eligible to appear in draft pools. Set in the editor.
@export var element_pool: Array[ElementData] = []
@export var draft_panel_path: NodePath = ^"../HUD/ElementDraftPanel"
## Number of options shown in each draft.
@export var draft_size: int = 3
## Wave index (0-based) after which the second draft fires.
## Default: wave_completed(3) = after wave 4 → 2nd draft fires before wave 5.
@export var second_draft_after_wave_index: int = 3

var _draft_panel: ElementDraftPanel = null


func _ready() -> void:
	_draft_panel = get_node_or_null(draft_panel_path) as ElementDraftPanel
	if _draft_panel == null:
		push_error("RunController could not resolve draft_panel_path=%s" % str(draft_panel_path))
	# Start a fresh run on scene entry.
	GameState.reset_run()
	EventBus.wave_completed.connect(_on_wave_completed)
	# Initial draft on game start.
	call_deferred("_trigger_draft", "Pick Your First Element", "This shapes the first half of your run.")


func _on_wave_completed(wave_index: int) -> void:
	if wave_index == second_draft_after_wave_index and GameState.drafted_elements.size() == 1:
		_trigger_draft("Pick Your Second Element", "The mid-run pivot — combine with your first.")


func _trigger_draft(title: String, subtitle: String) -> void:
	if _draft_panel == null:
		return
	var available: Array[ElementData] = []
	for e in element_pool:
		if not GameState.has_drafted(e.id):
			available.append(e)
	if available.is_empty():
		return
	available.shuffle()
	var options: Array = []
	for i in mini(draft_size, available.size()):
		options.append(available[i])
	get_tree().paused = true
	GameState.phase = GameState.Phase.DRAFTING
	_draft_panel.show_draft(title, subtitle, options, _on_element_chosen)


func _on_element_chosen(element: ElementData) -> void:
	GameState.add_drafted_element(element)
	get_tree().paused = false
	# Restore to a sensible pre-wave phase.
	if GameState.current_wave == 0:
		GameState.phase = GameState.Phase.PREPARING
	else:
		GameState.phase = GameState.Phase.BETWEEN_WAVES
