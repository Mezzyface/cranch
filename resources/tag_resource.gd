# resources/tag_resource.gd
extends Resource
class_name TagResource

# Unique identifier for this tag
@export var tag_id: String = ""

# Display name shown to player
@export var tag_name: String = "Unnamed Tag"

# What this tag represents
@export_multiline var description: String = ""

# Categories this tag belongs to (can be multiple)
@export var categories: Array[GlobalEnums.TagCategory] = []

# Visual appearance (future)
@export var icon: Texture2D = null
@export var color: Color = Color.WHITE

# Training requirement (only for training tags)
# Structure:
# {
#   "type": "stat_threshold" | "all_stats_threshold" | "activity_count" | "has_tag",
#   "stat": "strength" | "agility" | "intelligence",
#   "threshold": int,
#   "prerequisite_tag": "tag_id"
# }
@export var training_requirement: Dictionary = {}

# Check if this tag is in a specific category
func is_category(category: GlobalEnums.TagCategory) -> bool:
	return category in categories

# Get formatted display string
func get_display_name() -> String:
	return tag_name

# Get color-coded display (for rich text)
func get_colored_display() -> String:
	var hex_color = color.to_html(false)
	return "[color=#%s]%s[/color]" % [hex_color, tag_name]
