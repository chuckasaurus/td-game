extends CanvasLayer

@export var spawner_path: NodePath
@export var available_towers: Array[TowerData] = []

@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
@onready var phase_label: Label = %PhaseLabel
@onready var tower_button_container: HBoxContainer = %TowerButtons
@onready var start_wave_button: Button = %StartWaveButton
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var victory_panel: PanelContainer = %VictoryPanel

var _selected_button: Button = null


func _ready() -> void:
	_refresh_gold(GameState.gold)
	_refresh_lives(GameState.lives)
	_refresh_wave(GameState.current_wave)
	_refresh_phase(GameState.phase)

	GameState.gold_changed.connect(_refresh_gold)
	GameState.lives_changed.connect(_refresh_lives)
	GameState.wave_index_changed.connect(_refresh_wave)
	GameState.phase_changed.connect(_refresh_phase)

	start_wave_button.pressed.connect(_on_start_wave_pressed)
	_build_tower_buttons()

	game_over_panel.visible = false
	victory_panel.visible = false


func _build_tower_buttons() -> void:
	for child in tower_button_container.get_children():
		child.queue_free()
	for tower_data in available_towers:
		var btn := Button.new()
		btn.text = "%s\n%dg" % [tower_data.display_name, tower_data.cost]
		btn.custom_minimum_size = Vector2(120, 60)
		btn.toggle_mode = true
		btn.pressed.connect(_on_tower_button_pressed.bind(btn, tower_data))
		tower_button_container.add_child(btn)


func _on_tower_button_pressed(btn: Button, tower_data: TowerData) -> void:
	if _selected_button and _selected_button != btn:
		_selected_button.button_pressed = false
	_selected_button = btn if btn.button_pressed else null
	EventBus.tower_button_selected.emit(tower_data if btn.button_pressed else null)


func _on_start_wave_pressed() -> void:
	var spawner: WaveSpawner = get_node_or_null(spawner_path)
	if spawner and spawner.has_method("start_next_wave"):
		spawner.start_next_wave()


func _refresh_gold(value: int) -> void:
	gold_label.text = "Gold: %d" % value


func _refresh_lives(value: int) -> void:
	lives_label.text = "Lives: %d" % value


func _refresh_wave(value: int) -> void:
	wave_label.text = "Wave: %d" % value


func _refresh_phase(p: int) -> void:
	match p:
		GameState.Phase.PREPARING:
			phase_label.text = "Preparing"
			start_wave_button.disabled = false
		GameState.Phase.WAVE_ACTIVE:
			phase_label.text = "Wave in progress"
			start_wave_button.disabled = true
		GameState.Phase.BETWEEN_WAVES:
			phase_label.text = "Between waves"
			start_wave_button.disabled = false
		GameState.Phase.VICTORY:
			phase_label.text = "Victory!"
			start_wave_button.disabled = true
			victory_panel.visible = true
		GameState.Phase.GAME_OVER:
			phase_label.text = "Game Over"
			start_wave_button.disabled = true
			game_over_panel.visible = true
