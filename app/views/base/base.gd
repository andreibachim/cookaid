extends VBoxContainer

#VARIABLES
@onready var ratio: float = float(get_tree().root.content_scale_size.y) / float(DisplayServer.window_get_size().y)

#MEMBERS
@onready var panel := $padding

func _ready() -> void:
	pass

func _process(_delta):
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		var keyboard_height := DisplayServer.virtual_keyboard_get_height()
		var computed_height := ceili(keyboard_height * ratio)
		panel.custom_minimum_size.y = computed_height
