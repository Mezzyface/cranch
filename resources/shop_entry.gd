# resources/shop_entry.gd
extends Resource
class_name ShopEntry

@export var entry_name: String = "Mystery Purchase"
@export var description: String = "Something wonderful!"
@export var entry_type: GlobalEnums.ShopEntryType = GlobalEnums.ShopEntryType.CREATURE
@export var cost: int = 50
@export var stock: int = -1  # -1 = unlimited
@export var icon_texture: Texture2D = null

# Type-specific data
@export var creature_species: GlobalEnums.Species = GlobalEnums.Species.SLIME  # For CREATURE type
@export var item_id: String = ""  # For ITEM type - references inventory items by ID
# For SERVICE type: no extra data needed (yet)
