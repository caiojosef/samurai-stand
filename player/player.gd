extends Node2D

@export var max_health: int = 1000
@export var move_speed: float = 110
@export var attack_speed_percent: int = 50
@export var speed_percent: float = 100.0
@export var attack_range: float = 90.0
@export var stop_offset_x: float = -60.0
@export var attack_damage: int = 35
@export var max_chase_x: float = 200

var current_health: int = 0
var is_dead: bool = false
var is_attacking: bool = false
var is_returning: bool = false
var attack_index: int = 0

var start_position: Vector2
var entering_scene: bool = true
var entry_speed: float = 120

var pending_damage: int = 0
@onready var health_bar: ProgressBar = $HealthBar
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var enemy: Node2D = get_tree().get_first_node_in_group("enemy") as Node2D
@onready var attack_area: Area2D = $AttackArea
@onready var spawn_delay: Timer = $SpawnDelay


func _ready() -> void:
	add_to_group("player")
	randomize()

	start_position = global_position

	# player começa fora da tela (lado esquerdo)
	global_position = start_position + Vector2(-300, 0)

	current_health = max_health
	_update_health_bar()
	player_sprite.play("walking")

	update_attack_speed()

func get_current_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy: Node2D = null
	var closest_distance := INF

	for e in enemies:
		if not e.has_method("is_enemy_dead"):
			continue

		if e.is_enemy_dead():
			continue

		var dist = global_position.distance_to(e.global_position)

		if dist < closest_distance:
			closest_distance = dist
			closest_enemy = e as Node2D

	return closest_enemy
	
func damage_enemies_in_range() -> void:
	var areas = attack_area.get_overlapping_areas()
	var damaged_enemies: Array = []

	for area in areas:
		if area == null:
			continue

		var enemy_node = area.get_parent()

		if enemy_node == null:
			continue

		if not enemy_node.is_in_group("enemy"):
			continue

		if not enemy_node.has_method("is_enemy_dead"):
			continue

		if enemy_node.is_enemy_dead():
			continue

		if damaged_enemies.has(enemy_node):
			continue

		damaged_enemies.append(enemy_node)

		var damage = randi_range(10, 100)
		enemy_node.take_damage(damage)
	
func damage_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if e.has_method("is_enemy_dead") and not e.is_enemy_dead():
			var damage = randi_range(10, 100)
			e.take_damage(damage)
	
func update_attack_speed() -> void:
	var base_fps = 8
	var bonus = int(attack_speed_percent / 10) * 4
	var final_fps = base_fps + bonus

	player_sprite.sprite_frames.set_animation_speed("attack1", final_fps)
	player_sprite.sprite_frames.set_animation_speed("attack2", final_fps)
	player_sprite.sprite_frames.set_animation_speed("attack3", final_fps)

func _process(delta: float) -> void:
	if entering_scene:
		var direction = (start_position - global_position).normalized()
		global_position += direction * entry_speed * delta

		if global_position.distance_to(start_position) < 5:
			global_position = start_position
			entering_scene = false
			player_sprite.play("idle")

			spawn_delay.start()

		return
	if is_dead:
		return

	enemy = get_current_enemy()

	if enemy == null:
		is_attacking = false
		is_returning = true

		var distance_to_start = global_position.distance_to(start_position)

		if distance_to_start > 5.0:
			player_sprite.flip_h = true
			global_position.x -= move_speed * delta

			if player_sprite.animation != "walking":
				player_sprite.play("walking")
		else:
			global_position = start_position
			is_returning = false
			player_sprite.flip_h = false
			player_sprite.play("idle")

		return

	is_returning = false
	player_sprite.flip_h = false

	var target_position = enemy.global_position + Vector2(stop_offset_x, 0)
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target > attack_range:
		if is_attacking:
			return

		var direction = (target_position - global_position).normalized()
		var next_position = global_position + direction * move_speed * delta

		if next_position.x >= max_chase_x:
			global_position.x = max_chase_x

			if player_sprite.animation != "idle" and not is_attacking:
				player_sprite.play("idle")
		else:
			global_position = next_position

			if player_sprite.animation != "walking":
				player_sprite.play("walking")

				if player_sprite.animation != "walking":
					player_sprite.play("walking")
	else:
		if not is_attacking:
			attack_enemy()

func _update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health

func _play_from_start(anim_name: String) -> void:
	player_sprite.stop()
	player_sprite.play(anim_name)
	player_sprite.frame = 0

func attack_enemy() -> void:
	if is_dead:
		return

	if enemy == null:
		return

	if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
		return

	if is_attacking:
		return

	is_attacking = true

	if attack_index == 0:
		_play_from_start("attack1")
		attack_index = 1
	else:
		_play_from_start("attack2")
		attack_index = 0

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount

	if current_health <= 0:
		current_health = 0
		die()

	_update_health_bar()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	health_bar.visible = false
	_play_from_start("dead")

func is_player_dead() -> bool:
	return is_dead

func _on_player_sprite_animation_finished() -> void:
	if player_sprite.animation in ["attack1", "attack2", "attack3"] and not is_dead:
		damage_enemies_in_range()

		is_attacking = false
		enemy = get_current_enemy()

		if enemy == null:
			is_returning = true
			return

		var target_position = enemy.global_position + Vector2(stop_offset_x, 0)
		var distance_to_target = global_position.distance_to(target_position)

		if distance_to_target <= attack_range:
			attack_enemy()

	elif player_sprite.animation == "dead":
		player_sprite.stop()
		player_sprite.frame = player_sprite.sprite_frames.get_frame_count("dead") - 1


func _on_spawn_delay_timeout():
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")

	if spawner != null and spawner.has_method("start_spawning"):
		spawner.start_spawning()
