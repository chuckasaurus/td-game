extends CanvasLayer

const EAGLE_EYE: TowerBuff = preload("res://data/buffs/eagle_eye.tres")
const POISON_ARROWS: TowerBuff = preload("res://data/buffs/poison_arrows.tres")

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
@onready var dev_eagle_eye_button: Button = %DevEagleEyeButton
@onready var dev_poison_arrows_button: Button = %DevPoisonArrowsButton

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
	EventBus.tower_clicked.connect(_on_tower_clicked_untoggle_build)
	EventBus.tower_placed.connect(_on_tower_placed)
	EventBus.cancel_build_selection.connect(_on_cancel_build_selection)
	GameState.drafted_elements_changed.connect(_build_tower_buttons)

	start_wave_button.pressed.connect(_on_start_wave_pressed)
	dev_eagle_eye_button.toggled.connect(_on_dev_eagle_toggled)
	dev_poison_arrows_button.toggled.connect(_on_dev_poison_toggled)
	_build_tower_buttons()
	call_deferred("_refresh_wave_track")


func _on_tower_clicked_untoggle_build(_tower: Node) -> void:
	_deselect_picker()


func _on_tower_placed(_tower: Node) -> void:
	# Deselect the picker after a single placement so the cursor isn't locked.
	# Hold Shift while clicking to keep building the same tower repeatedly.
	if Input.is_key_pressed(KEY_SHIFT):
		return
	_deselect_picker()


func _on_cancel_build_selection() -> void:
	_deselect_picker()


func _on_dev_eagle_toggled(pressed: bool) -> void:
	if pressed:
		BuffRegistry.add_class_buff(EAGLE_EYE)
	else:
		BuffRegistry.remove_class_buff(EAGLE_EYE)


func _on_dev_poison_toggled(pressed: bool) -> void:
	if pressed:
		BuffRegistry.add_class_buff(POISON_ARROWS)
	else:
		BuffRegistry.remove_class_buff(POISON_ARROWS)


func _build_tower_buttons() -> void:
	for child in tower_button_container.get_children():
		child.queue_free()
	_selected_button = null
	for tower_data in available_towers:
		if not (tower_data is TowerData):
			continue
		# Element-bound towers only appear if their element has been drafted.
		# Arrow Tower (no element) is always available.
		if tower_data.element != null and not GameState.has_drafted(tower_data.element.id):
			continue
		var btn := Button.new()
		btn.text = "%s\n%dg" % [tower_data.display_name, tower_data.cost]
		btn.custom_minimum_size = Vector2(110, 60)
		btn.toggle_mode = true
		# Use toggled (not pressed) so programmatic state changes also flow
		# through this handler.
		btn.toggled.connect(_on_tower_button_toggled.bind(btn, tower_data))
		tower_button_container.add_child(btn)


func _on_tower_button_toggled(toggled_on: bool, btn: Button, tower_data: TowerData) -> void:
	if toggled_on:
		if _selected_button and _selected_button != btn:
			_selected_button.set_pressed_no_signal(false)
		_selected_button = btn
		EventBus.tower_button_selected.emit(tower_data)
	else:
		if _selected_button == btn:
			_selected_button = null
		EventBus.tower_button_selected.emit(null)


func _deselect_picker() -> void:
	# Setting button_pressed = false fires the toggled signal which handles
	# state cleanup (clears _selected_button and emits tower_button_selected(null)).
	if _selected_button:
		_selected_button.button_pressed = false


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
