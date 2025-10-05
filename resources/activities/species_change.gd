# resources/activities/species_change.gd
extends ActivityResource
class_name SpeciesChangeActivity

@export var target_species: GlobalEnums.Species = GlobalEnums.Species.KRIP

func _init():
	activity_name = "Magical Transformation"
	description = "Changes creature's species"
	duration_weeks = 2

func run_activity(creature: CreatureData) -> void:
	var old_species = creature.species
	creature.species = target_species
	print(creature.creature_name, " transformed from ", GlobalEnums.Species.keys()[old_species], " to ", GlobalEnums.Species.keys()[target_species], "!")

	# Emit signal for visual updates
	if SignalBus.has_signal("creature_species_changed"):
		SignalBus.creature_species_changed.emit(creature)

func can_run(creature: CreatureData) -> bool:
	# Can't transform to same species
	return creature.species != target_species

func get_preview_text(creature: CreatureData) -> String:
	return "Will transform to " + GlobalEnums.Species.keys()[target_species]
