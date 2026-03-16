extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_count: int = 5
@export var target_y: float = 658.0
@export var first_target_x: float = 490.0
@export var spacing_x: float = 140.0
@export var offscreen_offset_x: float = 300.0

# Quantos inimigos entram por "grupo" (sorteado entre min e max)
@export var min_per_group: int = 2
@export var max_per_group: int = 3

# Tempo entre cada grupo entrar
@export var interval_between_groups: float = 1.2

func _ready() -> void:
	add_to_group("enemy_spawner")

func start_spawning() -> void:
	var remaining = spawn_count

	while remaining > 0:
		# Sorteia quantos entram nesse grupo
		var group_size = randi_range(min_per_group, max_per_group)
		group_size = min(group_size, remaining)

		for i in range(group_size):
			_spawn_enemy()

		remaining -= group_size

		if remaining > 0:
			await get_tree().create_timer(interval_between_groups).timeout

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()

	# Posição X aleatória entre os inimigos possíveis
	var random_index = randi_range(0, spawn_count - 1)
	var target_x = first_target_x + (random_index * spacing_x)
	var target_pos = Vector2(target_x, target_y)

	enemy.global_position = target_pos + Vector2(offscreen_offset_x, 0)
	enemy.set_meta("entry_target", target_pos)
	add_child(enemy)
