class_name WaveData
extends Resource

@export var enemy: EnemyData
@export var count: int = 10
## Seconds between spawns within this wave.
@export var spawn_interval: float = 0.8
## Seconds to wait before the first enemy of this wave spawns.
@export var pre_wave_delay: float = 2.0
## Gold awarded when this wave is fully cleared.
@export var clear_bonus: int = 25
