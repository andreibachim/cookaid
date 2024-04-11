extends ScrollContainer

@onready var request = $request
@onready var ingredients_container = $scroll/vbox/ingredients_container
@onready var recipe_name = $scroll/vbox/recipe_name
@onready var description = $scroll/vbox/description
@onready var external_reference = $scroll/vbox/external_reference

var recipe_id = Navigator.next_recipe_id

func _ready() -> void:
	ingredients_container.recipe_id = recipe_id
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
	recipe_name.set_text(response.name)
	if response.description != null:
		description.set_text(response.description)
	if response.external_reference != null:
		external_reference.set_text(response.external_reference)
	for ingredient in response.ingredients:
		ingredients_container.add_ingredient(ingredient)

func _on_back_button_up():
	Navigator.load_recipes_screen()
	
func _on_recipe_name_text_changed(value):
	var payload = { "name": value }
	var response_array = await perform_request(JSON.stringify(payload))
	var status_code = response_array[1]
	match status_code:
		200: recipe_name.commit_name()
		_: recipe_name.revert_name()
		
func _on_external_reference_text_changed(value):
	var payload = { "external_reference": value }
	var response_array = await perform_request(JSON.stringify(payload))
	match response_array[1]:
		200: external_reference.commit_name()
		_: external_reference.revert_name()
		
func _on_description_text_changed(value):
	var payload = { "description": value }
	var response_array = await perform_request(JSON.stringify(payload))
	match response_array[1]:
		200: description.commit()
		_: description.revert()
		
func perform_request(payload: String) -> Array:
	request.request(State.API_BASE_URL + "/api/recipe/" + recipe_id,\
		["Content-Type: application/json", "Authorization: Bearer " + State.TOKEN],\
		HTTPClient.METHOD_PUT,
		payload)
	return await request.request_completed
