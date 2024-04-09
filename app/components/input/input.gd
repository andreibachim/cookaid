extends Panel


@export var flat: bool = false
@export var placeholder_text: String = ""
@export_range(32, 64) var min_height: int = 36

@onready var button := $vbox/button
@onready var input := $vbox/input

signal text_changed(value: String)

var current_name: String

func _ready():
	custom_minimum_size.y = min_height
	input.placeholder_text = placeholder_text
	if flat:
		self_modulate.a = 0
		input.add_theme_color_override("font_uneditable_color", Color.WHITE)
	input.editable = false
	button.self_modulate.a = 0.75
	button.text = "Edit"

func _on_button_button_up():
	if not input.editable:
		input.editable = true
		input.caret_column = input.text.length()
		input.grab_focus()
		button.self_modulate.a = 1
		button.text = "Save"
	else:
		input.editable = false
		button.self_modulate.a = 0.75
		button.text = "Edit"
		grab_focus()
		if input.text != current_name:
			text_changed.emit(input.text)
		
func get_text() -> String:
	return input.text
	
func set_text(value: String) -> void:
	input.text = value
	current_name = value
	
func revert_name() -> void:
	set_text(current_name)
	
func commit_name() -> void:
	current_name = input.text
