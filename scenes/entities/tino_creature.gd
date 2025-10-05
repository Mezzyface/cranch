extends CharacterBody2D

@onready var movement_controller = $WanderMovementController

func _physics_process(delta):
	if movement_controller:
		movement_controller.process_movement(delta)
