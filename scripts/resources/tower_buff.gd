class_name TowerBuff
extends Resource

enum Source { INSTANCE, SLOT, CLASS }

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color(1, 1, 1, 1)

## --- Targeting (used by class buffs; ignored for instance / slot buffs) ---
## Empty StringName / -1 = match any.
@export var target_class_id: StringName = &""
@export var target_element_id: StringName = &""
@export var target_attack_kind: int = -1

## --- Stat modifiers ---
@export var add_range: float = 0.0
@export var add_range_pct: float = 0.0
@export var add_damage: int = 0
@export var add_damage_pct: float = 0.0
@export var add_fire_rate_pct: float = 0.0
@export var add_projectile_speed_pct: float = 0.0
@export var add_armor_pen: float = 0.0
@export var add_crit_chance: float = 0.0
@export var add_crit_multiplier: float = 0.0

## --- Imbues (add behavior the tower may not otherwise have) ---
@export var imbue_status: StatusEffect = null
@export var imbue_status_chance: float = 1.0
@export var imbue_splash_radius: float = 0.0
@export var grants_anti_air: bool = false


## Returns true if this class-wide buff matches the given TowerData.
func matches(tower_data: TowerData) -> bool:
	if target_class_id != &"" and target_class_id != tower_data.class_id:
		return false
	if target_element_id != &"":
		if tower_data.element == null or tower_data.element.id != target_element_id:
			return false
	if target_attack_kind != -1 and target_attack_kind != tower_data.attack_kind:
		return false
	return true
