extends Node2D
@export var max_health: int = 100
var current_health: int = 0
var is_dead: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var enemy_sprite: AnimatedSprite2D = $EnemySprite

@onready var attack_timer: Timer = $AttackTimer
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

@export var move_speed: float = 80.0
@export var attack_range: float = 90.0

@export var stop_offset_x: float = 60.0
var start_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	start_position = global_position
	current_health = max_health
	_update_health_bar()
	enemy_sprite.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead:
		return

	if player == null:
		return

	if player.has_method("is_player_dead") and player.is_player_dead():
		reset_to_start()
		return

	var target_position = player.global_position + Vector2(stop_offset_x, 0)
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target > attack_range:
		var direction = (target_position - global_position).normalized()
		global_position += direction * move_speed * delta

		if enemy_sprite.animation != "walking":
			enemy_sprite.play("walking")
	else:
		if enemy_sprite.animation == "walking":
			enemy_sprite.play("idle")

func _update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	
func _play_from_start(anim_name: String) -> void:
	enemy_sprite.stop()
	enemy_sprite.play(anim_name)
	enemy_sprite.frame = 0

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
	
func reset_to_start() -> void:
	attack_timer.stop()
	global_position = start_position
	enemy_sprite.play("idle")
	
func attack_player() -> void:
	if is_dead:
		return

	if player == null:
		return

	if player.has_method("is_player_dead") and player.is_player_dead():
		reset_to_start()
		return

	var target_position = player.global_position + Vector2(stop_offset_x, 0)
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target > attack_range:
		return

	var damage = randi_range(10, 100)

	if player.has_method("take_damage"):
		player.take_damage(damage)

	_play_from_start("attack1")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		take_damage(10)


func _on_enemy_sprite_animation_finished() -> void:
	if enemy_sprite.animation == "hurt" and not is_dead:
		enemy_sprite.play("idle")
	elif enemy_sprite.animation == "attack1" and not is_dead:
		enemy_sprite.play("idle")


func _on_attack_timer_timeout() -> void:
	attack_player()
