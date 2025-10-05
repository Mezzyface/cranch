extends Node

const TINO_CREATURE = preload("res://scenes/entities/tino_creature.tscn")

func _ready():
	# Spawn 2 Tinos on the center platform
	_spawn_tino()
	_spawn_tino()

func _spawn_tino():
	var tino = TINO_CREATURE.instantiate()
	add_child(tino)

	# Position on center platform with random X position
	# Platform appears to be from x=400 to x=1520, y=432 (27 tiles * 16px)
	var random_x = randf_range(500, 1420)
	tino.position = Vector2(random_x, 400)

	# Set platform bounds on the movement controller
	# Adjust these values based on your actual platform size
	var movement_controller = tino.get_node_or_null("WanderMovementController")
	if movement_controller:
		movement_controller.platform_bounds = Vector2(400, 1520)

	print("Tino spawned at: ", tino.position)
