class_name ArmorShredStatus
extends StatusEffect

## How much current_armor to chunk off when applied. Does not regenerate.
@export var shred_amount: int = 15


func on_apply(enemy: Node, _instance: StatusInstance) -> void:
	if "current_armor" in enemy:
		enemy.current_armor = maxi(0, enemy.current_armor - shred_amount)
		if enemy.has_method("_refresh_armor_bar"):
			enemy._refresh_armor_bar()
