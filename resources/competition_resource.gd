# resources/competition_resource.gd
extends ActivityResource
class_name CompetitionResource

@export var competition_type: GlobalEnums.CompetitionType = GlobalEnums.CompetitionType.STRENGTH_CONTEST
@export var difficulty: GlobalEnums.CompetitionDifficulty = GlobalEnums.CompetitionDifficulty.MEDIUM
@export var entry_fee: int = 50
@export var first_place_gold: int = 200
@export var second_place_gold: int = 100
@export var third_place_gold: int = 50
@export var winner_tag_id: String = ""  # Optional: Award special tag to 1st place
@export var num_ai_opponents: int = 3   # Number of AI creatures to compete against

# Competition results data structure
class CompetitionResult:
	var creature: CreatureData
	var score: int
	var placement: int  # 1st, 2nd, 3rd, etc.
	var is_player_creature: bool

	func _init(p_creature: CreatureData, p_score: int, p_is_player: bool = true):
		creature = p_creature
		score = p_score
		is_player_creature = p_is_player

# Override: Run competition when activity executes
func run_activity(creature: CreatureData) -> void:
	print("Starting competition: ", activity_name, " for ", creature.creature_name)

	# Charge entry fee
	SignalBus.gold_change_requested.emit(-entry_fee)
	print("Paid entry fee: %d gold" % entry_fee)

	# Generate AI opponents
	var competitors: Array[CompetitionResult] = []
	competitors.append(CompetitionResult.new(creature, calculate_score(creature), true))

	for i in range(num_ai_opponents):
		var ai_creature = _generate_ai_opponent()
		competitors.append(CompetitionResult.new(ai_creature, calculate_score(ai_creature), false))

	# Sort by score (highest first)
	competitors.sort_custom(func(a, b): return a.score > b.score)

	# Assign placements
	for i in range(competitors.size()):
		competitors[i].placement = i + 1

	# Award prizes
	_award_prizes(competitors)

	# Emit competition completed signal
	SignalBus.competition_completed.emit(self, competitors)

# Calculate competition score based on type and creature stats
func calculate_score(creature: CreatureData) -> int:
	var base_score: int = 0

	match competition_type:
		GlobalEnums.CompetitionType.STRENGTH_CONTEST:
			base_score = creature.strength * 3  # STR heavily weighted
			base_score += creature.agility * 1

		GlobalEnums.CompetitionType.SPEED_RACE:
			base_score = creature.agility * 3   # AGI heavily weighted
			base_score += creature.strength * 1

		GlobalEnums.CompetitionType.PUZZLE_TOURNAMENT:
			base_score = creature.intelligence * 3  # INT heavily weighted
			base_score += creature.agility * 1

		GlobalEnums.CompetitionType.TRIATHLON:
			base_score = creature.strength + creature.agility + creature.intelligence

	# Add randomness (±20% variance)
	var variance = randf_range(0.8, 1.2)
	base_score = int(base_score * variance)

	return max(base_score, 1)  # Minimum score of 1

# Generate AI opponent based on difficulty
func _generate_ai_opponent() -> CreatureData:
	var ai = CreatureData.new()
	ai.creature_name = _generate_random_name()
	ai.species = _get_random_species()

	# Set primary stat based on difficulty and competition type
	# Stats now range 10-1000, with trained creatures reaching higher values
	var primary_stat: int
	var secondary_stats: int

	match difficulty:
		GlobalEnums.CompetitionDifficulty.EASY:
			primary_stat = randi_range(30, 100)     # Untrained creatures
			secondary_stats = randi_range(15, 40)
		GlobalEnums.CompetitionDifficulty.MEDIUM:
			primary_stat = randi_range(150, 300)    # Partially trained
			secondary_stats = randi_range(50, 100)
		GlobalEnums.CompetitionDifficulty.HARD:
			primary_stat = randi_range(400, 600)    # Well-trained
			secondary_stats = randi_range(100, 200)
		GlobalEnums.CompetitionDifficulty.EXPERT:
			primary_stat = randi_range(700, 1000)   # Maxed/near-maxed
			secondary_stats = randi_range(150, 300)

	# Distribute stats based on competition type
	match competition_type:
		GlobalEnums.CompetitionType.STRENGTH_CONTEST:
			ai.strength = primary_stat
			ai.agility = secondary_stats
			ai.intelligence = secondary_stats

		GlobalEnums.CompetitionType.SPEED_RACE:
			ai.agility = primary_stat
			ai.strength = secondary_stats
			ai.intelligence = secondary_stats

		GlobalEnums.CompetitionType.PUZZLE_TOURNAMENT:
			ai.intelligence = primary_stat
			ai.strength = secondary_stats
			ai.agility = secondary_stats

		GlobalEnums.CompetitionType.TRIATHLON:
			# Balanced stats for triathlon
			var balanced_stat = primary_stat * 0.7  # Slightly lower than pure specialists
			ai.strength = int(balanced_stat)
			ai.agility = int(balanced_stat)
			ai.intelligence = int(balanced_stat)

	return ai

# Award prizes to top 3 finishers
func _award_prizes(results: Array[CompetitionResult]) -> void:
	for result in results:
		if not result.is_player_creature:
			continue  # Only award player creatures

		var prize_gold = 0
		match result.placement:
			1:
				prize_gold = first_place_gold
				# Award winner tag if specified
				if not winner_tag_id.is_empty():
					_award_tag(result.creature, winner_tag_id)
			2:
				prize_gold = second_place_gold
			3:
				prize_gold = third_place_gold

		if prize_gold > 0:
			SignalBus.gold_change_requested.emit(prize_gold)
			print("%s placed %d and won %d gold!" % [result.creature.creature_name, result.placement, prize_gold])

# Award achievement tag to creature
func _award_tag(creature: CreatureData, tag_id: String) -> void:
	# Check if creature already has this tag
	if creature.has_tag(tag_id):
		return

	# Load tag resource
	var tag_path = "res://resources/tags/%s.tres" % tag_id
	if ResourceLoader.exists(tag_path):
		var tag = load(tag_path) as TagResource
		if tag:
			creature.tags.append(tag)
			SignalBus.creature_tag_added.emit(creature, tag_id)
			print("Awarded tag '%s' to %s!" % [tag.tag_name, creature.creature_name])

# Helper: Random AI names
func _generate_random_name() -> String:
	var names = ["Bolt", "Shadow", "Striker", "Flash", "Thunder", "Blaze", "Storm", "Frost", "Viper", "Titan"]
	return names[randi() % names.size()]

# Helper: Random species for AI
func _get_random_species() -> GlobalEnums.Species:
	var species_list = [
		GlobalEnums.Species.GUARD_ROBOT,
		GlobalEnums.Species.FIRE_PYROPE,
		GlobalEnums.Species.NEON_BAT,
		GlobalEnums.Species.KRIP,
		GlobalEnums.Species.GRIZZLY
	]
	return species_list[randi() % species_list.size()]

# Override: Preview text for UI
func get_preview_text(creature: CreatureData) -> String:
	var type_name = ""
	match competition_type:
		GlobalEnums.CompetitionType.STRENGTH_CONTEST:
			type_name = "Strength Contest"
		GlobalEnums.CompetitionType.SPEED_RACE:
			type_name = "Speed Race"
		GlobalEnums.CompetitionType.PUZZLE_TOURNAMENT:
			type_name = "Puzzle Tournament"
		GlobalEnums.CompetitionType.TRIATHLON:
			type_name = "Triathlon"

	return "%s\nEntry Fee: %d gold\n1st Prize: %d gold" % [type_name, entry_fee, first_place_gold]

# Override: Check if creature can compete (must have entry fee)
func can_run(creature: CreatureData) -> bool:
	if not GameManager.player_data:
		return false

	# Check if player has enough gold for entry fee
	if GameManager.player_data.gold < entry_fee:
		print("Not enough gold to enter competition. Need: ", entry_fee)
		return false

	return true
