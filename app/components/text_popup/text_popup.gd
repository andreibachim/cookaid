extends ColorRect

@onready var text_edit: TextEdit = $hbox/text_edit

signal text_submitted(text: String)

func _ready() -> void:
	text_edit.grab_focus()

func set_text(value: String) -> void:
	text_edit.text = value
	text_edit.select_all()

func _on_cancel_button_up():
	get_parent().remove_child(self)
	queue_free()

func _on_save_button_up():
	text_submitted.emit(text_edit.text)
	get_parent().remove_child(self)
	queue_free()
