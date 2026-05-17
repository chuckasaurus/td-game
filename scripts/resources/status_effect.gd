class_name StatusEffect
extends Resource

## Unique identifier (e.g. &"wet", &"burning", &"slowed").
@export var id: StringName = &""
@export var display_name: String = ""
@export var duration: float = 3.0
## Seconds between on_tick calls. 0 = no periodic tick.
@export var tick_interval: float = 0.0
## Generic magnitude (slow factor, damage amount, etc.) — meaning is per-subclass.
@export var magnitude: float = 0.0
## True = re-applying increases stack_count instead of just refreshing duration.
@export var stackable: bool = false
@export var icon_color: Color = Color(1, 1, 1, 1)


## Override in subclasses. Called once when the status is first applied to an enemy.
func on_apply(_enemy: Node, _instance: StatusInstance) -> void:
	pass


## Override in subclasses. Called every `tick_interval` seconds.
func on_tick(_enemy: Node, _instance: StatusInstance) -> void:
	pass


## Override in subclasses. Called when the status expires or is removed.
func on_expire(_enemy: Node, _instance: StatusInstance) -> void:
	pass
