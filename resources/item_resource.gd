# resources/item_resource.gd
extends Resource
class_name ItemResource

@export var item_name: String = "Mystery Item"
@export var description: String = "A wonderful item!"
@export var item_id: String = ""  # Unique identifier
@export var icon_texture: Texture2D = null

# Item properties (future)
# @export var consumable: bool = false
# @export var stackable: bool = true
# @export var max_stack: int = 99
