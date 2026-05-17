class_name WaveData
extends Resource

enum WaveKind { NORMAL, BOSS, EVENT, DRAFT }

@export var display_name: String = ""
@export var wave_kind: WaveKind = WaveKind.NORMAL
## Ordered list of spawn groups. Each group runs sequentially.
@export var spawn_groups: Array[SpawnGroup] = []
## Pause before the first spawn group starts.
@export var pre_wave_delay: float = 2.0
## Gold awarded when this wave is fully cleared.
@export var clear_bonus: int = 25
## Shown on the wave-progress strip card to summarize this wave.
@export var primary_enemy_for_ui: EnemyData


func total_count() -> int:
	var total := 0
	for group in spawn_groups:
		if group != null:
			total += group.count
	return total
