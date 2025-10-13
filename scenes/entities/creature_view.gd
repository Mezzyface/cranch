# scenes/entities/creature_view.gd
extends CharacterBody2D
class_name CreatureView

# Visual configuration
@export var hitbox_scale: float = 0.7

# References
var sim_id: String = ""
var creature_data: CreatureData
var current_emote_bubble = null

const EMOTE_BUBBLE = preload("res://scenes/windows/emote_bubble.tscn")

func _ready():
	# View-only setup, no AI initialization
	pass

func set_creature_data(data: CreatureData):
	creature_data = data
	_update_sprite()
	_update_hitbox()

func set_sim_id(id: String):
	sim_id = id

func update_from_simulation(sim_creature):  # SimCreature (no class_name available)
	# Sync position with simulation
	position = sim_creature.position

	# Update animation based on simulation state
	_update_animation(sim_creature.current_state, sim_creature.facing_direction)

	# Handle emote display
	if sim_creature.current_emote >= 0 and not current_emote_bubble:
		show_emote(sim_creature.current_emote)
	elif sim_creature.current_emote < 0 and current_emote_bubble:
		_hide_emote_bubble()

func _update_sprite():
	if not creature_data:
		return

	var sprite_frames = GlobalEnums.get_sprite_frames_for_species(creature_data.species)
	if sprite_frames and $AnimatedSprite2D:
		$AnimatedSprite2D.sprite_frames = sprite_frames

func _update_hitbox():
	if not creature_data or not $AnimatedSprite2D or not $CollisionShape2D:
		return

	var sprite_frames = $AnimatedSprite2D.sprite_frames
	if not sprite_frames:
		return

	var current_texture = sprite_frames.get_frame_texture("idle", 0)
	if current_texture:
		var sprite_size = current_texture.get_size()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = sprite_size * hitbox_scale
		$CollisionShape2D.shape = rect_shape
		$CollisionShape2D.position = Vector2(0, (sprite_size.y - rect_shape.size.y) / 2.0)

func _update_animation(state: GlobalEnums.CreatureState, facing: GlobalEnums.FacingDirection):
	var animation_name = ""

	match state:
		GlobalEnums.CreatureState.IDLE:
			animation_name = _get_idle_animation(facing)
		GlobalEnums.CreatureState.WALKING:
			animation_name = GlobalEnums.get_animation_name(facing)

	if animation_name and $AnimatedSprite2D.sprite_frames:
		if $AnimatedSprite2D.sprite_frames.has_animation(animation_name):
			$AnimatedSprite2D.play(animation_name)

func _get_idle_animation(walk_dir: GlobalEnums.FacingDirection) -> String:
	match walk_dir:
		GlobalEnums.FacingDirection.WALK_UP:
			return "idle-up"
		GlobalEnums.FacingDirection.WALK_DOWN:
			return "idle-down"
		GlobalEnums.FacingDirection.WALK_LEFT:
			return "idle-left"
		GlobalEnums.FacingDirection.WALK_RIGHT:
			return "idle-right"
		_:
			return "idle"

func show_emote(emote: int):  # Pass emote as int (GlobalEnums.Emote value)
	_hide_emote_bubble()

	current_emote_bubble = EMOTE_BUBBLE.instantiate()
	add_child(current_emote_bubble)
	current_emote_bubble.position = Vector2(0, -20)

	if current_emote_bubble.has_method("set_emote"):
		current_emote_bubble.set_emote(emote)

	# Auto-remove after duration (only if in tree)
	if is_inside_tree():
		get_tree().create_timer(2.5).timeout.connect(_hide_emote_bubble)

func _hide_emote_bubble():
	if current_emote_bubble:
		current_emote_bubble.queue_free()
		current_emote_bubble = null

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if creature_data:
			SignalBus.creature_clicked.emit(creature_data)
