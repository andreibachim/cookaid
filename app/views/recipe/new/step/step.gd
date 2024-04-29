extends MarginContainer

@onready var step_text: Label = $hbox/text
@onready var time_text: Label = $hbox/timer/time
var step: StepValue = StepValue.new()

func _ready():
	step_text.text = step.text
	if step.type == "Timer":
		var hours = floori(step.time / 3600.0)
		var minutes = floori((step.time % 3600) / 60.0)
		var seconds = step.time - hours * 3600 - minutes * 60.0
		var time = ""
		if hours: time = time + str(hours) + "h "
		if minutes: time = time + str(minutes) + "m "
		if seconds: time = time + str(seconds) + "s"
		time_text.text = time

func set_step(value: Dictionary) -> void:
	step.text = value.text
	if typeof(value.step_type) == TYPE_STRING and value.step_type == "Normal":
		step.type = "Normal"
	else:
		step.type = "Timer"
		step.time = value.step_type.Timer
