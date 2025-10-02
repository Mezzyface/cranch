extends Resource
class_name SaveGame

@export var gold: int = 0
@export var current_week: int = 1
@export var creatures: Array[CreatureData] = []

# Quest progress
@export var active_quest_ids: Array[String] = []
@export var completed_quest_ids: Array[String] = []

# Metadata
@export var save_date: String = ""
@export var version: String = "1.0"
