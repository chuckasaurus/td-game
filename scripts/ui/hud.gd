extends CanvasLayer

@export var spawner_path: NodePath
@export var available_towers: Array[Resource] = []

@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
@onready var phase_label: Label = %PhaseLabel
@onready var tower_button_container: HBoxContainer = %TowerButtons
@onready var start_wave_button: Button = %StartWaveButton
@onready var wave_track: HBoxContainer = %WaveTrack
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

	EventBus.wave_started.connect(_on_wave_event)
	EventBus.wave_completed.connect(_on_wave_event)

	start_wave_button.pressed.connect(_on_start_wave_pressed)
	_build_tower_buttons()
	call_deferred("_refresh_wave_track")


func _build_tower_buttons() -> void:
	for child in tower_button_container.get_children():
		child.queue_free()
	for tower_data in available_towers:
		if not (tower_data is TowerData):
			continue
		var btn := Button.new()
		btn.text = "%s\n%dg" % [tower_data.display_name, tower_data.cost]
		btn.custom_minimum_size = Vector2(110, 60)
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


func _on_wave_event(_idx: int) -> void:
	_refresh_wave_track()


func _refresh_wave_track() -> void:
	for child in wave_track.get_children():
		child.queue_free()
	var spawner: WaveSpawner = get_node_or_null(spawner_path)
	if spawner == null:
		return
	var upcoming := spawner.get_upcoming_waves(5)
	var current_idx := spawner.get_current_wave_index()
	for i in upcoming.size():
		var wave: WaveData = upcoming[i]
		# Wave number is 1-based; upcoming[0] is at index current_idx+1, which
		# is wave number current_idx+2 to the player.
		var wave_number := current_idx + i + 2
		wave_track.add_child(_make_wave_card(wave, wave_number))


func _make_wave_card(wave: WaveData, wave_number: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 64)
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(110, 56)
	card.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var num := Label.new()
	num.text = "W%d" % wave_number
	header.add_child(num)
	var kind_marker := _kind_marker(wave.wave_kind)
	if kind_marker != "":
		var kind_label := Label.new()
		kind_label.text = " %s" % kind_marker
		header.add_child(kind_label)

	var row := HBoxContainer.new()
	vbox.add_child(row)
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(16, 16)
	color_rect.color = wave.primary_enemy_for_ui.color_tint if wave.primary_enemy_for_ui else Color.WHITE
	row.add_child(color_rect)
	var name_label := Label.new()
	name_label.text = " %s" % wave.display_name
	name_label.add_theme_font_size_override("font_size", 11)
	row.add_child(name_label)

	return card


func _kind_marker(kind: int) -> String:
	match kind:
		WaveData.WaveKind.BOSS:
			return "☠"
		WaveData.WaveKind.DRAFT:
			return "★"
		WaveData.WaveKind.EVENT:
			return "⚑"
		_:
			return ""


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
