extends VBoxContainer

@export var placeholder: String = ""

@onready var button := $hbox/button
@onready var input := $input

signal text_changed(value: String)

var current_value: String = ""

func _ready():
	input.placeholder_text = placeholder
	button.text = "Edit"
	input.editable = false
	
func get_text() -> String:
	return input.text

func set_text(value: String):
	input.text = value
	current_value = value

func commit() -> void:
	current_value = input.text
	
func revert() -> void:
	set_text(current_value)

func _on_button_button_up():
	if not input.editable:
		input.grab_focus()
		input.editable = true 
		button.text = "Save"
	else:
		grab_focus()
		input.editable = false
		button.text = "Edit"
		if input.text != current_value:
			text_changed.emit(input.text)
