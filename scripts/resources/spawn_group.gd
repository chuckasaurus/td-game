class_name SpawnGroup
extends Resource

@export var enemy: EnemyData
@export var count: int = 10
## Seconds between spawns within this group.
@export var spawn_interval: float = 0.8
## Delay relative to the moment the wave's pre_wave_delay finished AND prior
## groups completed. Groups within a wave run sequentially.
@export var initial_delay: float = 0.0
