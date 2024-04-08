extends MarginContainer

@onready var request = $request

@onready var recipe_name = $vbox/recipe_name
@onready var description = $vbox/description
@onready var external_reference = $vbox/external_reference

var recipe_id = Navigator.next_recipe_id

func _ready() -> void:
	request.request(State.API_BASE_URL + "/api/recipe/" + recipe_id,\
		["Authorization: Bearer " + State.TOKEN])
	var response_array = await request.request_completed
	var status_code = response_array[1]
	var response_body_bytes: PackedByteArray = response_array[3]
	match status_code:
		200:
			var response_body: Dictionary = JSON.parse_string(\
				response_body_bytes.get_string_from_utf8())
			process_response(response_body)
		404:
			print("Recipe not found")
		_:
			print("Server error")
			
func process_response(response: Dictionary) -> void:
	recipe_name.text = response.name
	if response.description != null:
		description.text = response.description
	if response.external_reference != null:
		external_reference.text = response.external_reference

func _on_back_button_up():
	Navigator.load_recipes_screen()

func _on_save_button_up():
	var payload: Dictionary = {
		"name": recipe_name.text,
		"description": description.text,
		"external_reference": external_reference.text,
		"ingredients": [],
		"steps": [],
	}
	print(JSON.stringify(payload))
	request.request(State.API_BASE_URL + "/api/recipe/" + recipe_id,\
	["Authorization: Bearer " + State.TOKEN, "Content-Type: application/json"],\
	HTTPClient.METHOD_PUT,\
	JSON.stringify(payload))
	var response_array = await request.request_completed
	var status_code = response_array[1]
	match status_code:
		200: print("Sugges")
		_: print("Failure because of status code: " + str(status_code))
