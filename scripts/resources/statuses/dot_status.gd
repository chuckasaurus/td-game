class_name DotStatus
extends StatusEffect

## Damage per tick. Multiplied by stack_count if stackable.
@export var damage_per_tick: int = 3


func on_tick(enemy: Node, instance: StatusInstance) -> void:
	if not enemy.has_method("take_dot_damage"):
		return
	var dmg := damage_per_tick * instance.stack_count
	enemy.take_dot_damage(dmg)
