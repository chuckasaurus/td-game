class_name WaveSpawner
extends Node

@export var waves: Array = []
@export var enemy_scene: PackedScene
## Path to the Path2D used for enemy movement. Defaults to a sibling node.
@export var path_node: NodePath = ^"../EnemyPath"

var path: Path2D = null

var _alive_count: int = 0
var _wave_in_progress: bool = false
var _current_wave_index: int = -1
var _spawned_this_wave: int = 0
var _target_spawn_count: int = 0


func _ready() -> void:
	path = get_node_or_null(path_node) as Path2D
	if path == null:
		push_error("WaveSpawner could not resolve path_node=%s" % str(path_node))
	if enemy_scene == null:
		push_error("WaveSpawner missing enemy_scene")
	if waves.is_empty():
		push_warning("WaveSpawner has no waves configured")
	EventBus.enemy_killed.connect(_on_enemy_removed)
	EventBus.enemy_escaped.connect(_on_enemy_removed)


func has_more_waves() -> bool:
	return _current_wave_index + 1 < waves.size()


func get_upcoming_waves(n: int) -> Array:
	var upcoming: Array = []
	var start := _current_wave_index + (1 if _wave_in_progress else 1)
	for i in range(start, mini(start + n, waves.size())):
		upcoming.append(waves[i])
	return upcoming


func get_current_wave_index() -> int:
	return _current_wave_index


func start_next_wave() -> void:
	if _wave_in_progress or not has_more_waves():
		return
	if path == null or enemy_scene == null:
		push_error("WaveSpawner cannot start: missing path or enemy_scene")
		return
	_current_wave_index += 1
	GameState.current_wave = _current_wave_index + 1
	GameState.phase = GameState.Phase.WAVE_ACTIVE
	_wave_in_progress = true
	_spawned_this_wave = 0
	_alive_count = 0
	var wave: WaveData = waves[_current_wave_index] as WaveData
	if wave == null:
		push_error("Wave at index %d is not a WaveData" % _current_wave_index)
		_wave_in_progress = false
		return
	_target_spawn_count = wave.total_count()
	EventBus.wave_started.emit(_current_wave_index)
	if wave.pre_wave_delay > 0.0:
		await get_tree().create_timer(wave.pre_wave_delay).timeout
	_spawn_loop(wave)


func _spawn_loop(wave: WaveData) -> void:
	for group in wave.spawn_groups:
		if group == null or not _wave_in_progress:
			continue
		if group.initial_delay > 0.0:
			await get_tree().create_timer(group.initial_delay).timeout
		for i in group.count:
			if not _wave_in_progress:
				return
			_spawn_one(group.enemy)
			_spawned_this_wave += 1
			if i < group.count - 1:
				await get_tree().create_timer(group.spawn_interval).timeout


func _spawn_one(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		push_warning("Wave has null enemy data in a spawn group")
		return
	var enemy := enemy_scene.instantiate()
	path.add_child(enemy)
	enemy.progress = 0.0
	enemy.add_to_group(&"enemies")
	if enemy.has_method("configure"):
		enemy.configure(enemy_data)
	_alive_count += 1
	EventBus.enemy_spawned.emit(enemy)


func _on_enemy_removed(_enemy: Node, _gold: int = 0) -> void:
	if not _wave_in_progress:
		return
	_alive_count -= 1
	_check_wave_end()


func _check_wave_end() -> void:
	var wave: WaveData = waves[_current_wave_index] as WaveData
	if _spawned_this_wave >= _target_spawn_count and _alive_count <= 0:
		_wave_in_progress = false
		GameState.add_gold(wave.clear_bonus)
		EventBus.wave_completed.emit(_current_wave_index)
		if has_more_waves():
			GameState.phase = GameState.Phase.BETWEEN_WAVES
		else:
			GameState.phase = GameState.Phase.VICTORY
			EventBus.all_waves_completed.emit()
