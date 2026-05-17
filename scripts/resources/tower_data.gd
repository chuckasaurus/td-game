class_name TowerData
extends Resource

@export var display_name: String = "Tower"
@export var cost: int = 20
@export var damage: int = 10
@export var range_radius: float = 150.0
## Shots per second.
@export var fire_rate: float = 1.0
@export var projectile_speed: float = 400.0
@export var sprite: Texture2D
@export var projectile_color: Color = Color(1, 1, 0.4)

# Element-specific fields (used starting in Milestone 2; safe defaults for M1).
@export var element_id: StringName = &""
@export var splash_radius: float = 0.0
@export var chain_targets: int = 0
@export var armor_pen: float = 0.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.0
