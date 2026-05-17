class_name TowerData
extends Resource

enum AttackKind { HOMING, LINEAR_PIERCE, BEAM_CHAIN, CLOUD_DROP }

@export var display_name: String = "Tower"
@export var cost: int = 20
@export var damage: int = 10
@export var range_radius: float = 150.0
## Shots per second.
@export var fire_rate: float = 1.0
@export var projectile_speed: float = 400.0
@export var sprite: Texture2D
@export var projectile_color: Color = Color(1, 1, 0.4)

## Element (null for the universal Arrow Tower).
@export var element: ElementData
## Status applied on hit (null = no status).
@export var on_hit_status: StatusEffect
## Probability (0..1) that the on_hit_status actually applies on each hit.
## Used for "chance to stun" / "chance to crit-status" mechanics.
@export var status_chance: float = 1.0

## Fraction of damage that bypasses the armor pool, 0..1.
@export var armor_pen: float = 0.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.0

## Whether this tower can target flying enemies. Set on Arrow, Fire, Electric,
## Air, and any combo containing those elements.
@export var can_target_flying: bool = false

## --- Attack delivery shape ---

@export var attack_kind: AttackKind = AttackKind.HOMING

## > 0 = AoE splash damage at the projectile's impact point (HOMING only).
@export var splash_radius: float = 0.0

# LINEAR_PIERCE — projectile rolls in a straight line from fire position.
@export var linear_speed: float = 280.0
@export var linear_lifetime: float = 1.8
## Damage multiplier applied per pierce. 1.0 = no falloff, 0.7 = -30% per pierce.
@export var linear_pierce_falloff: float = 1.0

# BEAM_CHAIN — instant-hit zap that chains to nearby enemies.
@export var chain_targets: int = 0
## Damage multiplier per chain jump (compounds).
@export var chain_decay: float = 0.7
## Max distance from the previous link to chain to the next enemy.
@export var chain_range: float = 200.0

# CLOUD_DROP — lobbed projectile spawns a persistent area on impact.
@export var cloud_radius: float = 60.0
@export var cloud_duration: float = 4.0
@export var cloud_tick_interval: float = 0.5
@export var cloud_damage_per_tick: int = 2
