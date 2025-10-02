# scripts/creature_data.gd
extends Resource
class_name CreatureData

@export var creature_name: String = "Unnamed"
@export var strength: int = 10
@export var agility: int = 10
@export var intelligence: int = 10
@export var species: GlobalEnums.Species

# Tag system - stores TagResource references
@export var tags: Array[TagResource] = []

# Simple query: Check if creature has a specific tag (by tag_id)
func has_tag(tag_id: String) -> bool:
	for tag in tags:
		if tag and tag.tag_id == tag_id:
			return true
	return false

# Simple query: Get formatted tag string for UI display
func get_tags_display() -> String:
	if tags.is_empty():
		return "No tags"

	var tag_names: Array[String] = []
	for tag in tags:
		if tag:
			tag_names.append(tag.tag_name)

	return ", ".join(tag_names)

# Simple query: Get colored tag display (for rich text labels)
func get_tags_colored_display() -> String:
	if tags.is_empty():
		return "[color=gray]No tags[/color]"

	var tag_displays: Array[String] = []
	for tag in tags:
		if tag:
			tag_displays.append(tag.get_colored_display())

	return ", ".join(tag_displays)
