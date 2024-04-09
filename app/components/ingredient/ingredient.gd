extends MarginContainer

@onready var request := $request

var id: String
var recipe: String

func set_ingredient(value: Dictionary, recipe_id) -> void:
	$hbox/input.text = value.name
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
