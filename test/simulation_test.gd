# test/simulation_test.gd
extends Node

func _ready():
	print("=== SIMULATION TEST START ===")

	# Get simulation manager
	var sim_manager = get_node("/root/SimulationManager")

	# Create test creature
	var test_data = CreatureData.new()
	test_data.creature_name = "TestBot"
	test_data.species = GlobalEnums.Species.GUARD_ROBOT

	var sim_creature = SimCreature.new(test_data)
	sim_creature.container_bounds = Rect2(0, 0, 1000, 1000)
	sim_creature.position = Vector2(500, 500)

	# Register and start
	var sim_id = sim_manager.register_creature(sim_creature)
	sim_manager.start_simulation()

	# Monitor for 5 seconds
	await get_tree().create_timer(5.0).timeout

	# Check creature moved
	var final_pos = sim_manager.sim_creatures[sim_id].position
	print("Initial position: (500, 500)")
	print("Final position: ", final_pos)

	if final_pos != Vector2(500, 500):
		print("✅ PASS: Creature moved in simulation")
	else:
		print("❌ FAIL: Creature did not move")

	print("=== SIMULATION TEST END ===")
