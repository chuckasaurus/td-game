extends Node

enum Phase { PREPARING, WAVE_ACTIVE, BETWEEN_WAVES, VICTORY, GAME_OVER }

signal gold_changed(new_value: int)
signal lives_changed(new_value: int)
signal phase_changed(new_phase: Phase)
signal wave_index_changed(new_value: int)

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


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


func add_gold(amount: int) -> void:
	gold += amount


func lose_life(amount: int = 1) -> void:
	lives -= amount
