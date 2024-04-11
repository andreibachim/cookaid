extends MarginContainer

# MEMBERS
@onready var request := $request
@onready var input := $hbox/input
@onready var edit_button := $hbox/edit
@onready var save_button := $hbox/save

var id: String
var recipe: String
var current_value: String

func set_ingredient(value: Dictionary, recipe_id) -> void:
	input.text = value.name
	id = value.id
	recipe = recipe_id

func _on_delete_button_up():
	request.request(
		State.API_BASE_URL+"/api/recipe/"+recipe+"/ingredient/"+id,
		["Authorization: Bearer " + State.TOKEN],
		HTTPClient.METHOD_DELETE
	)
	var response_array = await request.request_completed
	match response_array[1]:
		200: 
			get_parent().remove_child(self)
			queue_free.call_deferred()
		_:
			print("Could not remove ingredient")
			
func _on_edit_button_up():
	current_value = input.text
	input.editable = true
	input.grab_focus()
	input.caret_column = input.text.length()
	edit_button.visible = false
	save_button.visible = true

func _on_save_button_up():
	input.editable = false
	edit_button.visible = true
	save_button.visible = false
	grab_focus()
	request.request(
		State.API_BASE_URL+"/api/recipe/"+recipe+"/ingredient/"+id,
		["Authorization: Bearer " + State.TOKEN, "Content-Type: application/json"],
		HTTPClient.METHOD_PUT,
		JSON.stringify({ "name": input.text })
	)
	var response_array = await request.request_completed
	match response_array[1]:
		200:
			pass
		_:
			input.text = current_value
