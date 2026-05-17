extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var buffs_container: VBoxContainer = %BuffsContainer
@onready var slot_label: Label = %SlotLabel
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton

var _tower: Node = null


func _ready() -> void:
	visible = false
	EventBus.tower_clicked.connect(_on_tower_clicked)
	EventBus.tower_buffs_changed.connect(_on_buffs_changed)
	EventBus.tower_sold.connect(_on_tower_sold)
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(close)


func _on_tower_clicked(tower: Node) -> void:
	_tower = tower
	_refresh()
	visible = true


func _on_buffs_changed(tower: Node) -> void:
	if tower == _tower:
		_refresh()


func _on_tower_sold(tower: Node, _refund: int) -> void:
	if tower == _tower:
		close()


func _on_sell_pressed() -> void:
	if _tower and _tower.has_method("sell"):
		_tower.sell()


func close() -> void:
	if not visible:
		return
	visible = false
	_tower = null
	EventBus.tower_inspector_closed.emit()


func _refresh() -> void:
	if _tower == null or _tower.base_data == null or _tower.effective_data == null:
		return
	var base: TowerData = _tower.base_data
	var eff: TowerData = _tower.effective_data
	title_label.text = base.display_name
	subtitle_label.text = _attack_subtitle(eff)
	_clear(stats_container)
	_build_stat_rows(base, eff)
	_clear(buffs_container)
	_build_buff_rows()
	_refresh_slot()


func _attack_subtitle(eff: TowerData) -> String:
	var element_name := eff.element.display_name if eff.element else "Neutral"
	var kind_name := ""
	match eff.attack_kind:
		TowerData.AttackKind.HOMING: kind_name = "Homing"
		TowerData.AttackKind.LINEAR_PIERCE: kind_name = "Linear Pierce"
		TowerData.AttackKind.BEAM_CHAIN: kind_name = "Beam Chain"
		TowerData.AttackKind.CLOUD_DROP: kind_name = "Cloud Drop"
	var anti_air := "  · Anti-Air" if eff.can_target_flying else ""
	return "%s · %s%s" % [element_name, kind_name, anti_air]


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _build_stat_rows(base: TowerData, eff: TowerData) -> void:
	_add_stat_row("Damage", float(base.damage), float(eff.damage), "%.0f")
	_add_stat_row("Range", base.range_radius, eff.range_radius, "%.0f")
	_add_stat_row("Fire Rate", base.fire_rate, eff.fire_rate, "%.2f/s")
	var base_dps := float(base.damage) * base.fire_rate
	var eff_dps := float(eff.damage) * eff.fire_rate
	_add_stat_row("DPS", base_dps, eff_dps, "%.1f")
	if eff.splash_radius > 0.0 or base.splash_radius > 0.0:
		_add_stat_row("Splash", base.splash_radius, eff.splash_radius, "%.0f")
	if eff.armor_pen > 0.0 or base.armor_pen > 0.0:
		_add_stat_row("Armor Pen", base.armor_pen * 100.0, eff.armor_pen * 100.0, "%.0f%%")
	if eff.crit_chance > 0.0 or base.crit_chance > 0.0:
		_add_stat_row("Crit Chance", base.crit_chance * 100.0, eff.crit_chance * 100.0, "%.0f%%")
		_add_stat_row("Crit Multi", base.crit_multiplier, eff.crit_multiplier, "%.1fx")


func _add_stat_row(label: String, base_val: float, eff_val: float, fmt: String) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "%s" % label
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)
	var val := Label.new()
	var base_str := fmt % base_val
	var eff_str := fmt % eff_val
	if absf(eff_val - base_val) < 0.001:
		val.text = base_str
	else:
		val.text = "%s → %s" % [base_str, eff_str]
		if eff_val > base_val:
			val.modulate = Color(0.4, 1.0, 0.5)
		else:
			val.modulate = Color(1.0, 0.5, 0.4)
	row.add_child(val)
	stats_container.add_child(row)


func _build_buff_rows() -> void:
	if _tower == null:
		return
	var instance: Array[TowerBuff] = _tower.instance_buffs
	var slot: TowerBuff = _tower.slot_buff
	var class_buffs: Array[TowerBuff] = BuffRegistry.get_buffs_for(_tower.base_data)
	if instance.is_empty() and slot == null and class_buffs.is_empty():
		var none := Label.new()
		none.text = "  (no active buffs)"
		none.modulate = Color(0.6, 0.6, 0.6)
		buffs_container.add_child(none)
		return
	for buff in class_buffs:
		_add_buff_row(buff, "class")
	for buff in instance:
		_add_buff_row(buff, "instance")
	if slot:
		_add_buff_row(slot, "slot")


func _add_buff_row(buff: TowerBuff, source: String) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "• %s  [%s]" % [buff.display_name, source]
	name_label.modulate = buff.icon_color if buff.icon_color != Color(0, 0, 0, 0) else Color.WHITE
	row.add_child(name_label)
	buffs_container.add_child(row)
	if buff.description != "":
		var desc := Label.new()
		desc.text = "   %s" % buff.description
		desc.add_theme_font_size_override("font_size", 11)
		desc.modulate = Color(0.85, 0.85, 0.85)
		buffs_container.add_child(desc)


func _refresh_slot() -> void:
	if _tower == null:
		return
	if _tower.slot_buff:
		slot_label.text = "Slot: %s" % _tower.slot_buff.display_name
	else:
		slot_label.text = "Slot: (empty)"
