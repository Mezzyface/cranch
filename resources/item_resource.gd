# resources/item_resource.gd
extends Resource
class_name ItemResource

@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""
@export var is_stackable: bool = true
@export var max_stack_size: int = 99
@export var item_type: GlobalEnums.ItemType = GlobalEnums.ItemType.MATERIAL
@export var stat_boost_multiplier: float = 1.0  # Training boost (1.0 = normal, 1.5 = 50% bonus, etc.)
