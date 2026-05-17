class_name StatusInstance
extends RefCounted

var effect: StatusEffect
var time_remaining: float
var time_to_next_tick: float
var stack_count: int = 1


func _init(template: StatusEffect) -> void:
	effect = template
	time_remaining = template.duration
	time_to_next_tick = template.tick_interval


## Returns true when the status has expired.
func tick(enemy: Node, delta: float) -> bool:
	time_remaining -= delta
	if effect.tick_interval > 0.0:
		time_to_next_tick -= delta
		while time_to_next_tick <= 0.0 and time_remaining > 0.0:
			effect.on_tick(enemy, self)
			time_to_next_tick += effect.tick_interval
	return time_remaining <= 0.0


func refresh() -> void:
	time_remaining = effect.duration
	if effect.stackable:
		stack_count += 1
