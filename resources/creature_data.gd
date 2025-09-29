# scripts/creature_data.gd
extends Resource
class_name CreatureData

@export var creature_name: String = "Unnamed"
@export var strength: int = 10
@export var agility: int = 10
@export var intelligence: int = 10
@export var species: GlobalEnums.Species
