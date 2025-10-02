# Development Guide - Living Document

## How We Work Together

### Our Development Process
When implementing features, we follow this pattern:
1. **You request a feature/change**
2. **I provide implementation steps in this document**
3. **You follow along and implement**
4. **We update the architecture documentation as we go**

This document serves as:
- A living reference of your game's architecture
- A place for step-by-step implementation guides
- Documentation of signal flow and connections

---

## Current Game Architecture

### Signal Flow Map

```
[Main Menu] --click start--> [Game Scene] --emits--> game_started
                                   |
                                   v
                            [SignalBus]
                                   |
                    +--------------+-------------+
                    |                            |
                    v                            v
            [GameManager]                 [UI Components]
            initialize_new_game()         (Debug Popup, HUD, etc)
                    |
                    v
            Creates PlayerData
            Creates Starter Creature
                    |
                    v
            Emits: player_data_initialized
                   creature_added
                   gold_changed
```

### Active Signal Connections

#### SignalBus Signals
```gdscript
# Game Flow
game_started → GameManager.initialize_new_game()
player_data_initialized → game_scene._on_player_data_ready()

# Save/Load
game_saved → [Not connected yet]
game_loaded → [Not connected yet]
save_failed → [Not connected yet]

# Player & Resources
gold_change_requested(amount) → GameManager._on_gold_change_requested()
gold_changed(amount) → UI components (for display updates)
creature_added(creature) → game_scene._on_creature_added()
creature_stats_changed(creature) → [Not connected yet]

# Game Progress
week_advanced(week) → FacilityManager.process_all_activities()

# Activity & Facility
activity_started(creature, activity) → [Not connected yet]
activity_completed(creature, activity) → [Not connected yet]
creature_species_changed(creature) → [Not connected yet]
facility_assigned(creature, facility) → FacilityManager.register_assignment()
facility_unassigned(creature, facility) → FacilityManager.unregister_assignment()

# UI Events
show_debug_popup_requested → [Not connected yet]
show_creature_details_requested(creature) → [Not connected yet]
creature_clicked(creature_data) → game_scene._on_creature_clicked()
popup_closed(popup_name) → [Not connected yet]

# Shop & Commerce
shop_opened(shop) → [UI components listen]
shop_closed() → [UI components listen]
shop_purchase_completed(item_name, cost) → [UI feedback]
shop_purchase_failed(reason) → [UI feedback]
```

### System Overview

#### Autoload Order (Important!)
1. `GlobalEnums` - Game enumerations and constants (Species, CreatureState, FacingDirection, Emote, ItemType)
2. `SignalBus` - Central signal hub
3. `GameManager` - Game state management
4. `SaveManager` - Save/load operations

#### Core Systems

**GameManager**
- Manages PlayerData (gold, creatures)
- Handles game initialization
- Controls week progression
- Listens for `gold_change_requested` signal and updates player gold
- Emits state changes through SignalBus
- Contains `facility_manager` instance (FacilityManager)

**FacilityManager** (accessed via `GameManager.facility_manager`)
- Tracks creature-to-facility assignments
- Processes all activities on week advancement
- Handles registration/unregistration of creatures
- Dictionary: `{facility: [creatures]}`
- Created and managed by GameManager

**SignalBus**
- Central hub for all signals
- No logic, just signal definitions
- Enables decoupled communication

**SaveManager**
- Handles all game persistence
- Resource-based saves at `user://savegame.tres`
- F5 to save, F9 to load
- Save metadata and versioning

**PlayerData Resource**
- Contains: gold, creatures array
- Persistent data structure

**CreatureData Resource**
- Contains: name, species, strength, agility, intelligence
- Individual creature stats

**DragDropComponent**
- Unified component for all drag/drop interactions
- Supports multiple drag types (CREATURE, FACILITY_CARD, CUSTOM)
- Configurable flags: `can_drag`, `can_accept_drops`
- Custom validation via callbacks
- Visual preview generation
- Signal-based communication (`drag_started`, `drag_ended`, `drop_received`)

**CreatureGenerator** (`scripts/creature_generation.gd`)
- Static utility class for procedural creature generation
- Species-based stat curves with normal distribution
- Random name generation per species

**ShopManager** (`scripts/shop_manager.gd`) - if implemented
- Static utility class for shop purchases
- Handles validation, gold transactions, SignalBus integration
- Not an autoload - called directly by UI components

---

## Implementation Steps Section

### 🎯 Current Task: Resource-Based Shop System

**Goal:** Create a flexible, resource-based shop system that can be reused for multiple vendors and shop types (creatures, items, etc).

**Design:**
- **ItemResource**: Defines inventory items (potions, equipment, etc) - reusable across shop, inventory, drops, etc
- **ShopEntry**: Defines what's for sale (creature, item, or service) with price and stock
- **ShopResource**: Defines shop inventory (vendor info, array of ShopEntries)
- **ShopWindow**: Reusable UI scene for displaying and interacting with shops
- **ShopManager**: Static utility class for purchase logic and SignalBus integration
- Easy to create new shops by making new ShopResource files

**Purchase Types:**
- **Creature purchases** - Directly generate and add creature to player array (no item created)
- **Item purchases** - Add ItemResource to player inventory (future)
- **Service purchases** - Trigger immediate action (healing, training boost, etc.)

---

#### Step 1: Add ShopEntryType to GlobalEnums

**File:** `core/global_enums.gd`

Add this enum to the GlobalEnums script:

```gdscript
enum ShopEntryType {
	CREATURE,     # Purchase generates a creature directly
	ITEM,         # Purchase gives an item to inventory
	SERVICE       # Purchase triggers an immediate action
}
```

**Why:** ShopEntryType defines what kind of purchase this is, not what type of item. Creatures bypass inventory entirely.

---

#### Step 2: Create ItemResource (for inventory items only)

**File:** `resources/item_resource.gd` (NEW FILE)

```gdscript
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
```

**Why:** Defines actual inventory items (potions, equipment). NOT used for creatures - those generate directly.

---

#### Step 3: Create ShopEntry Class

**File:** `resources/shop_entry.gd` (NEW FILE)

```gdscript
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
@export var item: ItemResource = null  # For ITEM type
# For SERVICE type: no extra data needed (yet)
```

**Why:** Each shop entry is self-contained. Creature purchases define species directly, item purchases reference ItemResource.

---

#### Step 4: Create ShopResource

**File:** `resources/shop_resource.gd` (NEW FILE)

```gdscript
# resources/shop_resource.gd
extends Resource
class_name ShopResource

@export var shop_name: String = "General Shop"
@export var vendor_name: String = "Shopkeeper"
@export var greeting: String = "Welcome to my shop!"

# Array of ShopEntry (each contains ItemResource + price + stock)
@export var entries: Array[ShopEntry] = []

# Track current stock for items with limited quantity
var current_stock: Dictionary = {}  # entry_index -> remaining stock

func _init():
	_initialize_stock()

func _initialize_stock():
	current_stock.clear()
	for i in range(entries.size()):
		if entries[i].stock > 0:
			current_stock[i] = entries[i].stock

func get_remaining_stock(entry_index: int) -> int:
	var entry = entries[entry_index]
	if entry.stock == -1:
		return -1  # Unlimited
	return current_stock.get(entry_index, 0)

func can_purchase(entry_index: int) -> bool:
	if entry_index < 0 or entry_index >= entries.size():
		return false
	var remaining = get_remaining_stock(entry_index)
	return remaining == -1 or remaining > 0

func purchase_item(entry_index: int) -> bool:
	if not can_purchase(entry_index):
		return false
	var entry = entries[entry_index]
	if entry.stock > 0:
		current_stock[entry_index] -= 1
	return true
```

**Why:** Shop contains references to items with shop-specific pricing/stock. Items can be reused across multiple systems.

---

#### Step 5: Create ShopManager Utility Class

**File:** `scripts/shop_manager.gd` (NEW FILE)

```gdscript
# scripts/shop_manager.gd
class_name ShopManager

# Handle shop purchases and validation
static func attempt_purchase(shop: ShopResource, entry_index: int) -> bool:
	if not shop or entry_index < 0 or entry_index >= shop.entries.size():
		push_error("Invalid shop or entry index")
		return false

	var entry = shop.entries[entry_index]

	# Check if item is in stock
	if not shop.can_purchase(entry_index):
		SignalBus.shop_purchase_failed.emit("Out of stock!")
		return false

	# Check if player has enough gold
	if not GameManager.player_data or GameManager.player_data.gold < entry.cost:
		SignalBus.shop_purchase_failed.emit("Not enough gold!")
		return false

	# Request gold deduction (negative amount = spend)
	SignalBus.gold_change_requested.emit(-entry.cost)

	# Process purchase based on entry type
	match entry.entry_type:
		GlobalEnums.ShopEntryType.CREATURE:
			_purchase_creature(entry)
		GlobalEnums.ShopEntryType.ITEM:
			_purchase_item(entry)
		GlobalEnums.ShopEntryType.SERVICE:
			_purchase_service(entry)

	# Update shop stock
	shop.purchase_item(entry_index)

	# Emit success signal
	SignalBus.shop_purchase_completed.emit(entry.entry_name, entry.cost)

	return true

static func _purchase_creature(entry: ShopEntry):
	# Generate creature directly and add to player array
	var creature = CreatureGenerator.generate_creature(entry.creature_species)
	GameManager.player_data.creatures.append(creature)
	SignalBus.creature_added.emit(creature)
	print("Purchased creature: %s (%s)" % [creature.creature_name, entry.entry_name])

static func _purchase_item(entry: ShopEntry):
	# TODO: Add to player inventory when item system exists
	if entry.item:
		print("Purchased item: %s" % entry.item.item_name)
	else:
		push_error("ShopEntry has ITEM type but no ItemResource assigned!")

static func _purchase_service(entry: ShopEntry):
	# TODO: Trigger service action (healing, training boost, etc)
	print("Purchased service: %s" % entry.entry_name)
```

**Why:** Creature purchases bypass inventory entirely. Item purchases will use ItemResource when inventory exists. Services are immediate actions. Gold changes via signal maintain decoupled architecture.

---

#### Step 6b: Update GameManager to Handle Gold Changes

**File:** `core/game_manager.gd`

Add this signal connection in `_connect_signals()`:

```gdscript
func _connect_signals():
	SignalBus.game_started.connect(initialize_new_game)
	SignalBus.gold_change_requested.connect(_on_gold_change_requested)
```

Add this handler function:

```gdscript
func _on_gold_change_requested(amount: int):
	if not player_data:
		push_error("Cannot change gold: no player_data")
		return

	player_data.gold += amount

	# Prevent negative gold
	if player_data.gold < 0:
		player_data.gold = 0

	# Emit update signal for UI
	SignalBus.gold_changed.emit(player_data.gold)

	if amount > 0:
		print("Gained %d gold (Total: %d)" % [amount, player_data.gold])
	else:
		print("Spent %d gold (Total: %d)" % [-amount, player_data.gold])
```

**Why:** GameManager is the single source of truth for player data. All gold changes go through SignalBus, maintaining decoupled architecture.

---

#### Step 7: Create ShopWindow UI Scene

**File:** `scenes/windows/shop_window.tscn` and `scenes/windows/shop_window.gd`

**Create the scene in Godot Editor:**

1. Scene → New Scene → User Interface
2. Rename root to `ShopWindow` (Panel or Window node)
3. Add these child nodes:
   ```
   ShopWindow (Window)
   ├── MarginContainer
   │   └── VBoxContainer
   │       ├── Header (HBoxContainer)
   │       │   ├── ShopNameLabel (Label)
   │       │   └── CloseButton (Button)
   │       ├── GreetingLabel (Label)
   │       ├── ItemList (ScrollContainer → VBoxContainer)
   │       └── Footer (HBoxContainer)
   │           └── GoldLabel (Label)
   ```

4. Configure nodes:
   - ShopWindow: title = "Shop", size = (600, 400), exclusive = true
   - ItemList VBoxContainer: name it "ItemListContainer"
   - CloseButton: text = "✕"

5. Save as `scenes/windows/shop_window.tscn`

**Attach script:** `scenes/windows/shop_window.gd`

```gdscript
# scenes/windows/shop_window.gd
extends Window

@onready var shop_name_label = $MarginContainer/VBoxContainer/Header/ShopNameLabel
@onready var greeting_label = $MarginContainer/VBoxContainer/GreetingLabel
@onready var item_list_container = $MarginContainer/VBoxContainer/ItemList/VBoxContainer
@onready var gold_label = $MarginContainer/VBoxContainer/Footer/GoldLabel
@onready var close_button = $MarginContainer/VBoxContainer/Header/CloseButton

var current_shop: ShopResource

# Preload shop item entry scene
const SHOP_ITEM_ENTRY = preload("res://scenes/ui/shop_item_entry.tscn")

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	close_requested.connect(_on_close_pressed)

	# Connect to signals
	SignalBus.gold_changed.connect(_update_gold_display)
	SignalBus.shop_purchase_completed.connect(_on_purchase_completed)
	SignalBus.shop_purchase_failed.connect(_on_purchase_failed)

func setup(shop: ShopResource):
	current_shop = shop

	# Set header
	shop_name_label.text = shop.shop_name
	greeting_label.text = shop.greeting

	# Populate item list
	_populate_items()

	# Update gold display
	_update_gold_display(GameManager.player_data.gold if GameManager.player_data else 0)

	# Emit signal
	SignalBus.shop_opened.emit(shop)

func _populate_items():
	# Clear existing items
	for child in item_list_container.get_children():
		child.queue_free()

	# Add shop entries
	for i in range(current_shop.entries.size()):
		var shop_entry = current_shop.entries[i]
		var entry = SHOP_ITEM_ENTRY.instantiate()
		item_list_container.add_child(entry)
		entry.setup(shop_entry, i, current_shop)
		entry.purchase_requested.connect(_on_purchase_requested)

func _on_purchase_requested(entry_index: int):
	ShopManager.attempt_purchase(current_shop, entry_index)

func _on_purchase_completed(item_name: String, cost: int):
	print("Purchase successful: %s for %d gold" % [item_name, cost])
	# Refresh item list to update stock displays
	_populate_items()

func _on_purchase_failed(reason: String):
	print("Purchase failed: %s" % reason)
	# TODO: Show visual feedback (popup, shake, flash red, etc)

func _update_gold_display(gold_amount: int):
	gold_label.text = "Gold: %d" % gold_amount

func _on_close_pressed():
	SignalBus.shop_closed.emit()
	queue_free()
```

**Why:** Reusable shop window that works with any ShopResource. Handles display and purchase requests.

---

#### Step 8: Create ShopItemEntry UI Component

**File:** `scenes/ui/shop_item_entry.tscn` and `scenes/ui/shop_item_entry.gd`

**Create the scene:**

1. Scene → New Scene → User Interface
2. Root: PanelContainer named "ShopItemEntry"
3. Add children:
   ```
   ShopItemEntry (PanelContainer)
   └── HBoxContainer
       ├── IconRect (TextureRect) - size 64x64
       ├── InfoVBox (VBoxContainer)
       │   ├── ItemNameLabel (Label)
       │   ├── DescriptionLabel (Label)
       │   └── StockLabel (Label)
       └── BuyButton (Button) - text "Buy (50g)"
   ```

4. Configure:
   - ItemNameLabel: larger font, bold if possible
   - DescriptionLabel: smaller font, modulate slightly gray
   - BuyButton: minimum width 100px

5. Save as `scenes/ui/shop_item_entry.tscn`

**Attach script:**

```gdscript
# scenes/ui/shop_item_entry.gd
extends PanelContainer

signal purchase_requested(item_index: int)

@onready var icon_rect = $HBoxContainer/IconRect
@onready var item_name_label = $HBoxContainer/InfoVBox/ItemNameLabel
@onready var description_label = $HBoxContainer/InfoVBox/DescriptionLabel
@onready var stock_label = $HBoxContainer/InfoVBox/StockLabel
@onready var buy_button = $HBoxContainer/BuyButton

var shop_entry: ShopEntry
var entry_index: int
var shop: ShopResource

func setup(entry: ShopEntry, index: int, shop_ref: ShopResource):
	shop_entry = entry
	entry_index = index
	shop = shop_ref

	# Set display from entry data
	item_name_label.text = entry.entry_name
	description_label.text = entry.description
	buy_button.text = "Buy (%dg)" % entry.cost

	if entry.icon_texture:
		icon_rect.texture = entry.icon_texture

	# Update stock display
	_update_stock_display()

	# Connect button
	buy_button.pressed.connect(_on_buy_pressed)

func _update_stock_display():
	var remaining = shop.get_remaining_stock(entry_index)

	if remaining == -1:
		stock_label.text = "Stock: Unlimited"
	else:
		stock_label.text = "Stock: %d" % remaining
		if remaining == 0:
			buy_button.disabled = true
			stock_label.text = "SOLD OUT"

func _on_buy_pressed():
	purchase_requested.emit(entry_index)
```

**Why:** Modular item entry that displays all necessary info and handles the buy button click.

---

#### Step 9: Create Example Creature Shop

**In Godot Editor:**

1. FileSystem → Right-click `resources/shops/` folder (create if needed) → Create New → Resource
2. Search for and select `ShopResource`
3. Save as `resources/shops/creature_shop_1.tres`
4. In Inspector:
   - Shop Name: "Creature Emporium"
   - Vendor Name: "Greta the Breeder"
   - Greeting: "Looking for a new companion? I've got just the thing!"
5. Entries array → Add 3 elements
6. For each entry, create new `ShopEntry`:

**Entry 0 - Slime Egg:**
- Entry Name: "Slime Egg"
- Description: "A balanced starter creature"
- Entry Type: CREATURE
- Cost: 50
- Stock: -1 (unlimited)
- Creature Species: SLIME

**Entry 1 - Scuttleguard Egg:**
- Entry Name: "Scuttleguard Egg"
- Description: "A tough, defensive creature"
- Entry Type: CREATURE
- Cost: 75
- Stock: 3
- Creature Species: SCUTTLEGUARD

**Entry 2 - Wind Dancer Egg:**
- Entry Name: "Wind Dancer Egg"
- Description: "A swift and intelligent creature"
- Entry Type: CREATURE
- Cost: 100
- Stock: 2
- Creature Species: WIND_DANCER

7. Save the shop resource

**Why:** Creature purchases are self-contained in ShopEntry. No separate item files needed since creatures generate directly.

---

#### Step 10: Add Shop Opening to Game Scene (Test)

**File:** `scenes/view/game_scene.gd`

Add a test function to open the shop:

```gdscript
# Preload shop window and test shop
const SHOP_WINDOW = preload("res://scenes/windows/shop_window.tscn")
const TEST_SHOP = preload("res://resources/shops/creature_shop_1.tres")

func _input(event):
	# Existing F5/F9 save/load code...

	# TEST: Open shop with F6
	if event.is_action_pressed("ui_text_backspace"):  # F6 is usually ui_text_backspace
		_open_test_shop()

func _open_test_shop():
	var shop_window = SHOP_WINDOW.instantiate()
	add_child(shop_window)
	shop_window.setup(TEST_SHOP)
	shop_window.popup_centered()
```

**Why:** Quick way to test the shop system. Press F6 to open shop.

---

### Testing Checklist

After implementation:
- [ ] Press F6 to open creature shop
- [ ] Shop displays 3 creature types with correct info
- [ ] Gold amount displays correctly
- [ ] Click "Buy" button purchases creature
- [ ] Gold is deducted
- [ ] Creature appears in game world
- [ ] Limited stock items decrease count
- [ ] Sold out items become disabled
- [ ] Can't purchase with insufficient gold
- [ ] Close button works

---

### Future Enhancements

1. **Inventory System:**
   - Create PlayerInventory resource
   - Add ItemResource instances to inventory
   - Item shops sell ItemResources (potions, equipment, etc.)
   - Use same ShopEntry system with entry_type = ITEM

2. **Shop Features:**
   - Daily restocking system
   - Random shop inventories
   - Discount events/sales
   - Shop unlock progression
   - Service purchases (healing, training boosts, facility upgrades)

3. **Better UI:**
   - Creature preview in shop (show stat ranges)
   - Tooltips with detailed info
   - Purchase animations
   - Category tabs for large inventories

4. **Vendor System:**
   - Vendor reputation/friendship
   - Unlock special entries through reputation
   - Different vendors in different locations
   - Wandering merchants with random stock

---

### 🎯 Previous Task: Creature Generation with Species-Based Stat Curves (COMPLETED)

**Goal:** Create a system to generate creatures with randomized stats based on species profiles using distribution curves.

**Design:**
- Each species has a stat profile (base + variance)
- Stats generated using normal distribution for natural variation
- Centralized CreatureGenerator for consistent generation
- Replace hardcoded creature creation with generated creatures

**Species Stat Profiles:**
```
SCUTTLEGUARD: Tank/Defense
- Strength: 12 ± 3  (high)
- Agility: 6 ± 2   (low)
- Intelligence: 8 ± 2 (medium)

SLIME: Balanced
- Strength: 8 ± 2
- Agility: 8 ± 2
- Intelligence: 8 ± 2

WIND_DANCER: Speed/Magic
- Strength: 6 ± 2   (low)
- Agility: 12 ± 3  (high)
- Intelligence: 10 ± 2 (medium-high)
```

---

#### Step 1: Create CreatureGenerator Utility Class

**File:** `scripts/creature_generation.gd` (NEW FILE)

Create this new file with the following content:

```gdscript
# scripts/creature_generation.gd
class_name CreatureGenerator

# Species stat templates: [base_value, variance]
# Stats are generated as: base ± variance using normal distribution
const SPECIES_STATS = {
	GlobalEnums.Species.SCUTTLEGUARD: {
		"strength": [12, 3],      # Tank - High strength
		"agility": [6, 2],        # Low agility
		"intelligence": [8, 2]    # Medium intelligence
	},
	GlobalEnums.Species.SLIME: {
		"strength": [8, 2],       # Balanced stats
		"agility": [8, 2],
		"intelligence": [8, 2]
	},
	GlobalEnums.Species.WIND_DANCER: {
		"strength": [6, 2],       # Mage - Low strength
		"agility": [12, 3],       # High agility
		"intelligence": [10, 2]   # High intelligence
	}
}

# Generate a creature with stats based on species profile
static func generate_creature(species: GlobalEnums.Species, creature_name: String = "") -> CreatureData:
	var creature = CreatureData.new()

	# Set name (or generate random if not provided)
	creature.creature_name = creature_name if creature_name != "" else _generate_random_name(species)

	# Set species
	creature.species = species

	# Generate stats based on species profile
	if species in SPECIES_STATS:
		var profile = SPECIES_STATS[species]
		creature.strength = _generate_stat(profile["strength"])
		creature.agility = _generate_stat(profile["agility"])
		creature.intelligence = _generate_stat(profile["intelligence"])
	else:
		# Fallback if species not defined
		push_warning("No stat profile for species: %s, using defaults" % species)
		creature.strength = 10
		creature.agility = 10
		creature.intelligence = 10

	return creature

# Generate a stat value using normal distribution
# params: [base, variance] where stat = base ± variance
static func _generate_stat(params: Array) -> int:
	var base = params[0]
	var variance = params[1]

	# Use randfn for normal distribution (bell curve)
	# randfn(mean, deviation) - most values cluster around mean
	var value = randfn(base, variance / 2.0)  # Divide by 2 so most values stay within ± variance

	# Clamp to reasonable range (1-20 for now)
	return int(clamp(value, 1, 20))

# Generate a random name based on species
static func _generate_random_name(species: GlobalEnums.Species) -> String:
	# Name pools per species
	var name_prefixes = {
		GlobalEnums.Species.SCUTTLEGUARD: ["Crunch", "Shell", "Guard", "Scuttle", "Armor"],
		GlobalEnums.Species.SLIME: ["Goo", "Blob", "Squish", "Slip", "Ooze"],
		GlobalEnums.Species.WIND_DANCER: ["Breeze", "Gale", "Whisper", "Zephyr", "Swift"]
	}

	var suffixes = ["", "y", "ie", "ster", "ling", "let"]

	var prefixes = name_prefixes.get(species, ["Creature"])
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]

	return prefix + suffix
```

**Why:**
- Simple utility class with static functions - no autoload needed
- Uses normal distribution (randfn) for realistic stat variation
- Each species has distinct stat tendencies (tank, balanced, mage)
- Extensible for future species

---

#### Step 2: Update GameManager to Use CreatureGenerator

**File:** `core/game_manager.gd`

**Location:** In `initialize_new_game()` function, replace the hardcoded creature creation

**Before:**
```gdscript
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

	create_test_facility()
```

**After:**
```gdscript
func initialize_new_game():
	# Create player data container
	player_data = PlayerData.new()
	player_data.gold = 100

	# Generate starter creatures using CreatureGenerator
	var starter_1 = CreatureGenerator.generate_creature(
		GlobalEnums.Species.SCUTTLEGUARD,
		"Scuttle"  # Optional: keep specific name or use "" for random
	)
	player_data.creatures.append(starter_1)
	SignalBus.creature_added.emit(starter_1)

	var starter_2 = CreatureGenerator.generate_creature(
		GlobalEnums.Species.SLIME,
		"Squish"  # Optional: keep specific name or use "" for random
	)
	player_data.creatures.append(starter_2)
	SignalBus.creature_added.emit(starter_2)

	# Use SignalBus instead of local signals
	SignalBus.player_data_initialized.emit()
	SignalBus.gold_changed.emit(player_data.gold)

	create_test_facility()
```

**Why:**
- Replaces manual stat assignment with generated stats
- Makes adding new creatures easier (one line instead of 6+)
- Stats now follow species-appropriate curves

---

#### Step 3: Add Helper Function to GameManager (Optional but Recommended)

**File:** `core/game_manager.gd`

Add this function at the bottom of the file:

```gdscript
# Helper function to add a generated creature to player's collection
func add_generated_creature(species: GlobalEnums.Species, creature_name: String = "") -> CreatureData:
	var creature = CreatureGenerator.generate_creature(species, creature_name)
	player_data.creatures.append(creature)
	SignalBus.creature_added.emit(creature)
	return creature
```

**Why:** Provides a convenient way for other systems (shops, breeding, rewards) to add creatures.

---

### Testing the System

After implementation, test by:

1. **Run the game** - Check output console for starter creature stats
2. **Verify stat ranges** - Stats should vary but follow species patterns:
   - Scuttleguard: Higher strength, lower agility
   - Slime: Balanced stats around 8
   - Wind Dancer: Higher agility/int, lower strength
3. **Restart multiple times** - Stats should be different each time
4. **Check creature stats popup** - Click creatures to see generated stats

**Console commands for testing** (optional - add to debug menu later):
```gdscript
# Test generating 10 creatures of each type to see stat distribution
for i in 10:
    var creature = CreatureGenerator.generate_creature(GlobalEnums.Species.SCUTTLEGUARD)
    print("%s: STR=%d AGI=%d INT=%d" % [creature.creature_name, creature.strength, creature.agility, creature.intelligence])
```

---

### Future Enhancements

Once basic generation works, consider:

1. **Rarity Tiers:** Add stat multipliers (Common, Rare, Legendary)
2. **Breeding:** Combine parent stats with mutation
3. **Level System:** Stats increase over time/training
4. **Trait System:** Special abilities based on stat thresholds
5. **Name Generator:** More sophisticated procedural names
6. **Stat Caps:** Per-species maximum stats

---

## Completed Implementations

### ✅ Facility Slot Unlock Bug Fix
**Fixed unlocked slots not accepting drops and set unique slot indices:**

**Bug Fixed:**
- Unlocked facility slots now properly accept facility drops after unlocking
- Root cause: Drop zone was only created in `_ready()` for initially unlocked slots
- Solution: Call `_setup_drop_zone()` in `attempt_unlock()` after removing overlay
- Slot indices properly set (0, 1, 2, 3) for accurate unlock messages

**Changes:**
- `scenes/card/facility_slot.gd:187` - Added `_setup_drop_zone()` call in `attempt_unlock()`
- `scenes/view/game_scene.tscn:52,60,69` - Set unique slot_index values (1, 2, 3)
- `core/signal_bus.gd:31` - Added `facility_slot_unlocked` signal
- `scenes/view/game_scene.gd:290` - Fixed slot reference from `$FacilitySlot` to `$FacilitySlot1`

---

### ✅ FacilitySlot Scene Conversion & Drop Zone Bug Fix
**Converted FacilitySlot from script-only to scene-based and fixed critical drop bug:**

**Features**:
- Converted FacilitySlot from programmatic creation to scene-based
- Created `facility_slot.tscn` for visual editing in Godot editor
- FacilitySlot instances now placed directly in game_scene.tscn as children
- Updated game_scene.gd to work with scene-based slots (signal connection only)
- Removed programmatic slot creation code

**Bug Fixed**:
- **Fixed facility drop zone bug** - Facility slots no longer stop accepting drops after removing all creatures
  - Root cause: `queue_free()` doesn't remove nodes immediately, causing duplicates
  - Old drag components stayed in tree and blocked mouse input after being marked for deletion
  - Solution: Changed to `free()` in `update_slots()` for immediate removal
  - Applies to both CreatureDrag components and creature sprites

**Files Modified**:
- `scenes/card/facility_card.gd` - Changed `queue_free()` to `free()` in update_slots()
- `scenes/view/game_scene.gd` - Updated to work with scene-based FacilitySlots
- `scenes/view/game_scene.tscn` - FacilitySlot instances placed as children

**Files Created**:
- `scenes/card/facility_slot.tscn` - Scene for FacilitySlot visual editing

**Technical Details**:
- `queue_free()` marks nodes for deletion at end of frame
- During slot updates, new drag components were created before old ones were removed
- Result: Duplicate drag components with same names blocking input
- `free()` provides immediate removal, preventing input conflicts

### ✅ Creature Stats Popup & Click Detection
**Created popup system to view creature stats with click detection:**

**Features**:
- Click on creatures in world to view stats popup
- Shows: name, species, strength, agility, intelligence
- Click detection integrated into DragDropComponent
- Distinguishes clicks from drags (10px threshold)
- `clicked()` signal emitted for non-drag clicks
- Works alongside existing drag/drop functionality

**Files Created**:
- `scenes/windows/creature_stats_popup.tscn` - Popup UI scene
- `scenes/windows/creature_stats_popup.gd` - Popup logic and data display

**Bug Fixes**:
1. **Fixed facility activity execution** - Activities now properly modify stats
   - Changed from base `ActivityResource.new()` to actual `StrengthTrainingActivity` class
   - Activities execute their `run_activity()` implementation correctly

2. **Fixed creature duplication** - Creatures no longer duplicate when moved between slots
   - Fixed indentation bug in `facility_card.gd` line 142
   - Same-facility moves now properly remove creature from source slot

**Signals Updated**:
- Added `creature_clicked(creature_data)` to SignalBus
- Connected in game_scene to instantiate popup

### ✅ Unified Drag & Drop Component System
**Architecture**: Layered Control nodes with z-indexing for proper input priority

**DragDropComponent Class** (`scripts/drag_drop_component.gd`):
- Reusable component for all drag/drop operations
- Extends Control, purely for interaction (no visual elements)
- **Drag Types**: CREATURE, FACILITY_CARD, CUSTOM
- **Configurable Flags**:
  - `can_drag`: Enable/disable drag initiation (drop-only zones use `false`)
  - `can_accept_drops`: Enable drop acceptance
  - `hide_on_drag`: Auto-hide source node during drag
- **Custom Validation**: `custom_can_drop_callback` for complex drop logic
- **Signals**: `drag_started`, `drag_ended`, `drop_received`

**Layered Architecture Pattern**:
All drag/drop uses z-indexed layers for proper input handling:
- **Layer 1 (z:100)**: Base drop zones (cover full area, drop-only)
- **Layer 2 (z:101-200)**: Individual drag sources (positioned over specific elements)

**Implementations**:
1. **Creatures in World**:
   - `CreatureDrag_[name]` components (z:200) as siblings to container
   - Follow creatures via global positioning in `_process()`
   - Separate from visual CreatureDisplay nodes

2. **Creature Container**:
   - `ContainerDropZone` (z:100) drop-only base layer
   - Accepts creatures from world or facilities
   - Repositions world creatures or spawns from facilities

3. **Facility Cards**:
   - `FacilityDrag` (z:100) for dragging card + accepting creature drops
   - `CreatureDrag_0`, `CreatureDrag_1` (z:101) per creature slot
   - All as direct children of FacilityCard for proper hierarchy

4. **Facility Slots**:
   - `FacilitySlotDropZone` (z:100) drop-only
   - Accepts facility card drops for placement/swapping

**Key Features**:
- Completely agnostic of visual elements (pure interaction layer)
- No native `_get_drag_data/_can_drop_data/_drop_data` in game code
- Proper mouse event propagation via z-index and child ordering
- Preview generation with customizable alpha
- Drop validation prevents overfilling facilities
- **See `DRAG_DROP_CHANGES.md` for migration documentation**

### ✅ Facility Cards with Drag & Drop
- Created FacilityCard UI scene and script
- Added drag functionality to creatures using Control child nodes
- Implemented drop detection on facility cards
- Visual feedback during drag (semi-transparent preview, highlighting)
- Creatures return to view if not dropped on facility
- CreatureContainer accepts drops for repositioning
- Automatic activity execution on assignment

### ✅ Facility & Activity System
- Created base ActivityResource class with overridable run_activity
- Created FacilityResource class managing multiple activities
- Example activities: StrengthTraining, SpeciesChange
- Activities can check conditions and modify creatures
- Signals for activity events in SignalBus
- Test facility setup in GameManager

### ✅ Game Initialization Flow
- Created PlayerData resource class
- Set up GameManager initialization
- Implemented SignalBus pattern
- Connected game_scene to show debug popup
- Added creature with species to starter data

### ✅ SignalBus Setup
- Created centralized signal definitions
- Added to autoload in correct order
- Connected game_started signal
- Connected player_data_initialized signal

### ✅ Creature Display System
- Spawning creatures in CreatureContainer
- Container boundary constraints with padding
- Idle/Walking state machine
- Directional animations (walk-up, walk-down, walk-left, walk-right)
- FacingDirection enum in GlobalEnums

### ✅ Emote Bubble System
- Random emote display above creatures
- 15 different emote types
- Timer-based with configurable intervals
- Pop-in animation with elastic tween
- Auto-cleanup after duration

### ✅ Save/Load System
- SaveManager singleton for all persistence
- Resource-based saves (SaveGame class)
- F5/F9 quick save/load
- Main menu continue button
- Save metadata and versioning
- Refactored from GameManager to dedicated SaveManager

---

## Quick Reference

### Common Patterns

#### Adding a New Signal
1. Define in `SignalBus`
2. Emit from source system
3. Connect in receiving systems
4. Update this document

#### Creating New UI Popup
1. Create scene in `scenes/windows/`
2. Create accompanying script
3. Connect to relevant SignalBus signals
4. Preload and instantiate from game_scene

#### Adding Game Features
1. Define needed signals in SignalBus
2. Implement logic in GameManager or appropriate system
3. Create UI components if needed
4. Wire up signal connections
5. Test the flow

#### Using DragDropComponent

**For Drag Sources** (things you can pick up):
```gdscript
var drag_component = DragDropComponent.new()
drag_component.name = "MyDrag"
drag_component.drag_type = DragDropComponent.DragType.CREATURE  # or FACILITY_CARD, CUSTOM
drag_component.drag_data_source = source_node  # The visual node being dragged
drag_component.mouse_filter_mode = Control.MOUSE_FILTER_STOP
drag_component.z_index = 101  # Above drop zones

# Position and size over the draggable element
drag_component.position = element_position
drag_component.size = element_size

# Connect signals
drag_component.drag_started.connect(func(data): pass)
drag_component.drag_ended.connect(func(successful): pass)

add_child(drag_component)
```

**For Drop Zones** (areas that accept drops):
```gdscript
var drop_zone = DragDropComponent.new()
drop_zone.name = "MyDropZone"
drop_zone.drag_type = DragDropComponent.DragType.CREATURE
drop_zone.can_accept_drops = true
drop_zone.can_drag = false  # Drop-only zone
drop_zone.mouse_filter_mode = Control.MOUSE_FILTER_STOP
drop_zone.z_index = 100  # Below drag sources

# Fill the droppable area
drop_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
drop_zone.set_offsets_preset(Control.PRESET_FULL_RECT)

# Custom validation (optional)
drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
    return data.has("creature") and can_accept(data.creature)

# Connect drop signal
drop_zone.drop_received.connect(_on_drop_received)

add_child(drop_zone)
```

**Key Principles**:
- Drop zones at z:100, drag sources at z:101+
- Drop-only zones use `can_drag = false`
- Drag sources use `drag_data_source` to reference visual elements
- Components are siblings or parents to avoid mouse filter conflicts
- Use global positioning for components outside their parent's hierarchy

### File Structure
```
project/
├── core/
│   ├── game_manager.gd (Game logic)
│   ├── save_manager.gd (Persistence)
│   ├── signal_bus.gd (Signal hub)
│   ├── global_enums.gd (Constants)
│   └── managers/
│       └── facility_manager.gd (Facility assignments)
├── resources/
│   ├── creature_data.gd
│   ├── player_data.gd
│   ├── save_game.gd
│   ├── facility_data.gd
│   └── activities/ (ActivityResource subclasses)
├── scripts/
│   └── drag_drop_component.gd (Unified drag/drop)
├── scenes/
│   ├── view/ (Main scenes)
│   │   ├── main_menu.tscn/gd
│   │   └── game_scene.tscn/gd
│   ├── windows/ (Popups)
│   │   ├── debug_popup.tscn/gd
│   │   └── emote_bubble.tscn/gd
│   ├── card/ (Facility UI)
│   │   ├── facility_card.tscn/gd
│   │   ├── facility_slot.gd
│   │   └── week_display.tscn/gd
│   └── entities/ (Game objects)
│       └── creature_display.tscn/gd
└── assets/
    ├── sprites/creatures/
    └── emotes/
```

---

## Notes for Future Development

**SignalBus Best Practices:**
- SignalBus pattern keeps systems decoupled
- Always emit signals with relevant data
- Check if data exists before emitting
- Remember to disconnect signals when nodes are freed

**DragDropComponent Best Practices:**
- Always use DragDropComponent for drag/drop (never native methods)
- Layer drop zones at z:100, drag sources at z:101+
- Use `can_drag = false` for drop-only zones
- Keep components separate from visual nodes
- Use global positioning for components outside parent hierarchy
- Clean up drag components when visual nodes are freed

**General Development:**
- Use preload() for scenes that will be instantiated multiple times
- Test drag/drop with different z-index configurations if issues arise
- Check mouse_filter settings if input isn't working as expected

---

## Next Possible Features

Potential implementations ready to guide:
- Week advancement system with UI
- Creature training mechanics
- Facility management
- Save/Load system
- Settings menu
- Creature detail view
- Resource management (gold spending)
- Activity system

*Request any feature and steps will appear in the Implementation Steps section above*