extends Node

# Per-run gameplay signals. Keep this file as the single source of truth
# for cross-system events so entities never hold direct references to each other.

signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node, gold_reward: int)
signal enemy_escaped(enemy: Node)

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_completed()

signal tower_placed(tower: Node)
signal tower_sold(tower: Node, refund: int)
signal request_build(tower_data: Resource, slot: Node)

signal build_slot_selected(slot: Node)
signal tower_button_selected(tower_data: Resource)
