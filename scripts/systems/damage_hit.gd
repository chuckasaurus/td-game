class_name DamageHit
extends RefCounted

var amount: int = 0
var element_id: StringName = &""
## Fraction of damage that bypasses the armor pool, 0..1.
var armor_pen: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.0
## Status effect template to apply on hit. Null = no status.
var on_hit_status: StatusEffect = null


static func from_tower(tower_data: TowerData) -> DamageHit:
	var hit := DamageHit.new()
	hit.amount = tower_data.damage
	hit.element_id = tower_data.element.id if tower_data.element else &""
	hit.armor_pen = tower_data.armor_pen
	hit.crit_chance = tower_data.crit_chance
	hit.crit_multiplier = tower_data.crit_multiplier
	# Roll status chance at fire time so each shot independently rolls (e.g.
	# Boulder's 15% stun chance).
	if tower_data.on_hit_status and randf() <= tower_data.status_chance:
		hit.on_hit_status = tower_data.on_hit_status
	return hit
