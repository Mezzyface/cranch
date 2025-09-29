extends Node2D  # Match the root node type from the scene

# The scene has a TextureRect named "Emote"
@onready var emote_icon = $Emote

# Define emote textures from the review folder
const EMOTE_TEXTURES = {
	GlobalEnums.Emote.HAPPY: preload("res://assets/emotes/review/happy.png"),
	GlobalEnums.Emote.JOYFUL: preload("res://assets/emotes/review/joyful.png"),
	GlobalEnums.Emote.FRUSTRATED: preload("res://assets/emotes/review/frustrated.png"),
	GlobalEnums.Emote.CRYING: preload("res://assets/emotes/review/crying.png"),
	GlobalEnums.Emote.CHEERFUL: preload("res://assets/emotes/review/cheerful.png"),
	GlobalEnums.Emote.LAUGHING: preload("res://assets/emotes/review/laughing.png"),
	GlobalEnums.Emote.SLEEPING: preload("res://assets/emotes/review/sleeping.png"),
	GlobalEnums.Emote.PLEASED: preload("res://assets/emotes/review/pleased.png"),
	GlobalEnums.Emote.SHOCKED: preload("res://assets/emotes/review/shocked.png"),
	GlobalEnums.Emote.GIGGLING: preload("res://assets/emotes/review/giggling.png"),
	GlobalEnums.Emote.LOVE: preload("res://assets/emotes/review/love.png"),
	GlobalEnums.Emote.DROWSY: preload("res://assets/emotes/review/drowsy.png"),
	GlobalEnums.Emote.WORRIED: preload("res://assets/emotes/review/worried.png"),
	GlobalEnums.Emote.EXCITED: preload("res://assets/emotes/review/excited.png"),
	GlobalEnums.Emote.ANGRY: preload("res://assets/emotes/review/angry.png")
}

func set_random_emote():
	# Get random emote
	var emotes = GlobalEnums.Emote.values()
	var random_emote = emotes[randi() % emotes.size()]
	set_emote(random_emote)

func set_emote(emote: GlobalEnums.Emote):
	# Set the texture based on emote type
	if emote_icon and emote in EMOTE_TEXTURES:
		emote_icon.texture = EMOTE_TEXTURES[emote]

	# Add pop-in animation
	_play_pop_in_animation()

func _play_pop_in_animation():
	# Simple scale animation
	scale = Vector2(0, 0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5)
