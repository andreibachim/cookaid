extends ColorRect

@onready var text_edit: TextEdit = $hbox/text_edit
@onready var type_select: OptionButton = $hbox/type_margin/hbox/type_select
@onready var timer_value: SpinBox = $hbox/timer_margin/hbox/timer_value_spinbox
@onready var time_unit: OptionButton = $hbox/timer_margin/hbox/timer_unit_select
@onready var timer_margin: MarginContainer = $hbox/timer_margin

signal submitted(text: StepValue)

func _ready() -> void:
	text_edit.grab_focus()

func set_text(value: String) -> void:
	text_edit.text = value
	text_edit.select_all()

func _on_cancel_button_up():
	get_parent().remove_child(self)
	queue_free()

func _on_save_button_up():
	var step_value = StepValue.new()
	step_value.text = text_edit.text
	step_value.type = type_select.get_item_text(type_select.selected)
	step_value.time = timer_value.value * max(1, 60 * time_unit.selected)
	
	submitted.emit(step_value)
	get_parent().remove_child(self)
	queue_free()

func _on_type_select_item_selected(index: int) -> void:
	match index:
		1: 
			timer_margin.visible = true
		_:
			timer_margin.visible = false
