extends Node2D

@export var max_health: int = 1000
var current_health: int = 0
var is_dead: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite

func _ready() -> void:
	current_health = max_health
	_update_health_bar()
	player_sprite.play("idle")

func _update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health

func _play_from_start(anim_name: String) -> void:
	player_sprite.stop()
	player_sprite.play(anim_name)
	player_sprite.frame = 0

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount

	if current_health < 0:
		current_health = 0

	_update_health_bar()

	if current_health == 0:
		die()
	else:
		_play_from_start("hurt")

func die() -> void:
	if is_dead:
		return

	is_dead = true
	health_bar.visible = false
	_play_from_start("dead")
	
func is_player_dead() -> bool:
	return is_dead

func _on_player_sprite_animation_finished() -> void:
	if player_sprite.animation == "hurt" and not is_dead:
		player_sprite.play("idle")
