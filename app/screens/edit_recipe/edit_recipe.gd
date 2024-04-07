extends MarginContainer

@onready var request = $request

@onready var recipe_name = $vbox/recipe_name
@onready var description = $vbox/description
@onready var external_reference = $vbox/external_reference

var recipe_id = Navigator.next_recipe_id

func _ready() -> void:
	print("The recipe id is: " +  recipe_id)
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
