@tool
extends EditorScript

# Run this script in Godot Editor: File -> Run
# It will create SpriteFrames resources for all new creatures

const CREATURES = {
	"guard_robot": "guard_robot.tres",
	"fire_pyrope": "fire_pyrope.tres",
	"illusionary_raccoon": "illusionary_raccoon.tres",
	"ore_muncher": "ore_muncher.tres",
	"neon_bat": "neon_bat.tres",
	"toy_trojan": "toy_trojan.tres",
	"robo": "robo.tres",
	"froscola": "froscola.tres",
	"grizzly": "grizzly.tres",
	"blazin_sparkinstone_bugs": "blazin_sparkinstone_bugs.tres",
	"stoplight_ghost": "stoplight_ghost.tres",
	"haunted_river_rock": "haunted_river_rock.tres",
	"hedgehog": "hedgehog.tres",
	"delinquent_chick": "delinquent_chick.tres",
	"ooze_waste": "ooze_waste.tres",
	"krip": "krip.tres",
	"grave_robber_hunting_dog": "grave_robber_hunting_dog.tres"
}

func _run():
	print("Creating SpriteFrames for new creatures...")

	for folder_name in CREATURES.keys():
		var resource_name = CREATURES[folder_name]
		create_sprite_frames(folder_name, resource_name)

	print("Done! SpriteFrames created for all creatures.")

func create_sprite_frames(folder_name: String, resource_file: String):
	var base_path = "res://assets/sprites/creatures/" + folder_name + "/"
	var sprite_frames = SpriteFrames.new()

	# Get stand frames
	var stand_frames = get_frames_with_prefix(base_path, "stand_")
	if stand_frames.is_empty():
		print("Warning: No stand frames found for " + folder_name)
		return

	# Get move frames (or chase frames as fallback)
	var move_frames = get_frames_with_prefix(base_path, "move_")
	if move_frames.is_empty():
		move_frames = get_frames_with_prefix(base_path, "chase_")

	if move_frames.is_empty():
		print("Warning: No move/chase frames found for " + folder_name)
		return

	# Create idle animation
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 8.0)

	for frame_path in stand_frames:
		var texture = load(frame_path)
		if texture:
			sprite_frames.add_frame("idle", texture)

	# Create walk animations for all 4 directions (using same move frames)
	for direction in ["walk-down", "walk-left", "walk-right", "walk-up", "idle-down", "idle-left", "idle-right", "idle-up"]:
		sprite_frames.add_animation(direction)
		sprite_frames.set_animation_loop(direction, true)

		# Use move frames for walk, stand frames for idle-*
		var frames_to_use = move_frames if direction.begins_with("walk") else stand_frames
		var speed = 8.0 if direction.begins_with("walk") else 6.0
		sprite_frames.set_animation_speed(direction, speed)

		for frame_path in frames_to_use:
			var texture = load(frame_path)
			if texture:
				sprite_frames.add_frame(direction, texture)

	# Save the resource
	var save_path = base_path + resource_file
	var result = ResourceSaver.save(sprite_frames, save_path)

	if result == OK:
		print("✓ Created: " + save_path)
	else:
		print("✗ Failed to save: " + save_path + " (Error: " + str(result) + ")")

func get_frames_with_prefix(base_path: String, prefix: String) -> Array[String]:
	var frames: Array[String] = []
	var dir = DirAccess.open(base_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.begins_with(prefix) and file_name.ends_with(".png"):
				frames.append(base_path + file_name)
			file_name = dir.get_next()

		dir.list_dir_end()
		frames.sort()
	else:
		print("Error: Could not open directory: " + base_path)

	return frames
