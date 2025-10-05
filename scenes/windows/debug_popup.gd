extends AcceptDialog

var player_data: PlayerData

func _ready():
	# Set up the dialog
	title = "Debug Info"
	dialog_text = ""
	add_cancel_button("Close")
	print("Debug ready")

func set_player_data(data: PlayerData):
	player_data = data
	update_display()

func update_display():
	if not player_data:
		dialog_text = "No player data available"
		return

	var info = "=== PLAYER DATA ===\n"
	info += "Gold: %d\n" % player_data.gold
	info += "Total Creatures: %d\n\n" % player_data.creatures.size()

	# Display each creature
	for i in range(player_data.creatures.size()):
		var creature = player_data.creatures[i]
		info += "=== CREATURE %d ===\n" % (i + 1)
		info += "Name: %s\n" % creature.creature_name
		info += "Species: %s\n" % _get_species_name(creature.species)
		info += "Strength: %d\n" % creature.strength
		info += "Agility: %d\n" % creature.agility
		info += "Intelligence: %d\n\n" % creature.intelligence

	dialog_text = info

func _get_species_name(species: GlobalEnums.Species) -> String:
	# Use GlobalEnums.Species.keys() to get the enum name
	var species_keys = GlobalEnums.Species.keys()
	if species >= 0 and species < species_keys.size():
		# Convert enum name to readable format (e.g., GUARD_ROBOT -> Guard Robot)
		return species_keys[species].replace("_", " ").capitalize()
	return "Unknown"
