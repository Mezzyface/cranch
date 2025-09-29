# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_data: PlayerData  # Changed from separate gold/creature vars

const SAVE_PATH = "user://savegame.tres"

func _ready():
	_connect_signals()

func _connect_signals():
	SignalBus.game_started.connect(initialize_new_game)
	
func initialize_new_game():
	# Create player data container
	player_data = PlayerData.new()
	player_data.gold = 100

	# Create starter creature with proper species
	var starter_creature = CreatureData.new()
	starter_creature.creature_name = "Scuttle"
	starter_creature.species = GlobalEnums.Species.SCUTTLEGUARD
	starter_creature.strength = 10
	starter_creature.agility = 8
	starter_creature.intelligence = 6
	
	player_data.creatures.append(starter_creature)
	SignalBus.creature_added.emit(starter_creature)
	
	starter_creature = CreatureData.new()
	starter_creature.creature_name = "Squish"
	starter_creature.species = GlobalEnums.Species.SLIME
	starter_creature.strength = 10
	starter_creature.agility = 8
	starter_creature.intelligence = 6
	
	player_data.creatures.append(starter_creature)

	# Use SignalBus instead of local signals
	SignalBus.player_data_initialized.emit()
	SignalBus.creature_added.emit(starter_creature)
	SignalBus.gold_changed.emit(player_data.gold)

func advance_week():
	current_week += 1
	SignalBus.week_advanced.emit(current_week)
#
#func process_training():
	## Updated to work with creatures array
	#for creature in player_data.creatures:
		#if creature.get("assigned_facility"):
			#creature.strength += 5
			#creature.agility += 3
			#stats_changed.emit()

func get_active_creature() -> CreatureData:
	if player_data and player_data.creatures.size() > 0:
		return player_data.creatures[0]
	return null
