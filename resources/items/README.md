# Food Items - Manual Setup Required

These food items need to be created in the Godot Editor:

## food_basic.tres
1. In Godot: FileSystem → resources/items → Right-click → New Resource
2. Select `ItemResource`
3. Set properties:
   - `item_name`: "Basic Food"
   - `description`: "Simple creature food. One meal for one training session."
   - `item_type`: FOOD (0)
   - `stat_boost_multiplier`: 1.0
   - `is_stackable`: true
   - `max_stack_size`: 99
4. Save as `food_basic.tres`

## food_premium.tres
1. In Godot: FileSystem → resources/items → Right-click → New Resource
2. Select `ItemResource`
3. Set properties:
   - `item_name`: "Premium Food"
   - `description`: "High-quality creature food. Provides +50% training bonus!"
   - `item_type`: FOOD (0)
   - `stat_boost_multiplier`: 1.5
   - `is_stackable`: true
   - `max_stack_size`: 99
4. Save as `food_premium.tres`

**Note**: After creating these files, the InventoryManager will automatically load them on game start.
