class_name EnemyData
extends Resource

@export var display_name: String = "Creep"
@export var max_hp: int = 50
@export var max_armor: int = 0
@export var speed: float = 80.0
@export var gold_reward: int = 5
@export var sprite: Texture2D
@export var is_flying: bool = false
## Magic-resistant creeps take half damage from any hit that carries a status
## effect (Burning, Poisoned, Slowed, etc.). Pure-damage hits (Arrow, etc.) are
## unaffected.
@export var magic_resistant: bool = false
@export var color_tint: Color = Color.WHITE
