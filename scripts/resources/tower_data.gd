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

## --- Behaviour flags driven by tower.gd ---

## > 0 = AoE splash damage at the projectile's impact point.
@export var splash_radius: float = 0.0
## > 0 = projectile chains to nearby enemies after first hit.
@export var chain_targets: int = 0
## Damage decay per chain jump (0..1).
@export var chain_decay: float = 0.7
