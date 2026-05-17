extends Node

enum Phase { PREPARING, WAVE_ACTIVE, BETWEEN_WAVES, VICTORY, GAME_OVER, DRAFTING }

signal gold_changed(new_value: int)
signal lives_changed(new_value: int)
signal phase_changed(new_phase: Phase)
signal wave_index_changed(new_value: int)
signal drafted_elements_changed

var gold: int = 100:
	set(value):
		gold = max(0, value)
		gold_changed.emit(gold)

var lives: int = 20:
	set(value):
		lives = max(0, value)
		lives_changed.emit(lives)
		if lives == 0 and phase != Phase.GAME_OVER:
			phase = Phase.GAME_OVER

var current_wave: int = 0:
	set(value):
		current_wave = value
		wave_index_changed.emit(current_wave)

var phase: Phase = Phase.PREPARING:
	set(value):
		if phase == value:
			return
		phase = value
		phase_changed.emit(phase)

## Elements drafted for the current run.
var drafted_elements: Array[ElementData] = []


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_escaped.connect(_on_enemy_escaped)


func _on_enemy_killed(_enemy: Node, gold_reward: int) -> void:
	add_gold(gold_reward)


func _on_enemy_escaped(_enemy: Node) -> void:
	lose_life(1)


func reset_run() -> void:
	gold = 100
	lives = 20
	current_wave = 0
	phase = Phase.PREPARING
	clear_drafted_elements()


func add_drafted_element(element: ElementData) -> void:
	if element == null:
		return
	for e in drafted_elements:
		if e.id == element.id:
			return
	drafted_elements.append(element)
	drafted_elements_changed.emit()


func has_drafted(element_id: StringName) -> bool:
	for e in drafted_elements:
		if e.id == element_id:
			return true
	return false


func clear_drafted_elements() -> void:
	if drafted_elements.is_empty():
		return
	drafted_elements.clear()
	drafted_elements_changed.emit()


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


func add_gold(amount: int) -> void:
	gold += amount


func lose_life(amount: int = 1) -> void:
	lives -= amount
