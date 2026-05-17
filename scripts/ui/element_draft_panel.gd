class_name ElementDraftPanel
extends Control

@onready var title_label: Label = %DraftTitle
@onready var subtitle_label: Label = %DraftSubtitle
@onready var options_container: HBoxContainer = %OptionsContainer

var _on_choice: Callable


func _ready() -> void:
	visible = false
	# Stay interactive while the rest of the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_draft(title: String, subtitle: String, options: Array, on_choice: Callable) -> void:
	_on_choice = on_choice
	title_label.text = title
	subtitle_label.text = subtitle
	_clear_options()
	for element in options:
		if element is ElementData:
			_add_option_card(element)
	visible = true


func _clear_options() -> void:
	for c in options_container.get_children():
		c.queue_free()


func _add_option_card(element: ElementData) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 280)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.custom_minimum_size = Vector2(200, 260)
	card.add_child(vbox)

	var color_rect := ColorRect.new()
	color_rect.color = element.color
	color_rect.custom_minimum_size = Vector2(200, 80)
	vbox.add_child(color_rect)

	var name_label := Label.new()
	name_label.text = element.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = element.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(200, 100)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	var choose_btn := Button.new()
	choose_btn.text = "Choose"
	choose_btn.custom_minimum_size = Vector2(200, 40)
	choose_btn.pressed.connect(_on_choose.bind(element))
	vbox.add_child(choose_btn)

	options_container.add_child(card)


func _on_choose(element: ElementData) -> void:
	visible = false
	if _on_choice.is_valid():
		_on_choice.call(element)
