extends ScrollContainer

@onready var popup = $margin/popup
@onready var request: HTTPRequest = HTTPRequest.new()

@onready var recipe_name_input = $margin/popup/background/margin/vbox/recipe_name_input
@export var recipe_list_item_template: PackedScene
@onready var recipes_list = $margin/recipes_list

func _ready():
	popup.visible = false
	add_child(request)
	request.request(State.API_BASE_URL + "/api/recipe",\
		["Authorization: Bearer " + State.TOKEN])
	var response_array = await request.request_completed
	match response_array[1]:
		200:
			var body: Array = JSON.parse_string(\
				response_array[3].get_string_from_utf8())
			for recipe in body:
				var recipe_instance = recipe_list_item_template.instantiate()
				recipes_list.add_child(recipe_instance)
				recipe_instance.set_up(recipe)
		_: 
			print("Could not load recipes")

func _on_new_recipe_button_up():
	popup.popup()

func _on_cancel_button_button_up():
	popup.hide()

func _on_create_button_button_up():
	var payload: Dictionary = {
		"name": recipe_name_input.text
	}
	request.request(State.API_BASE_URL + "/api/recipe",\
		["Content-Type: application/json",\
		"Authorization: Bearer " + State.TOKEN],\
		HTTPClient.METHOD_POST,\
		JSON.stringify(payload))
	var response_array = await request.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			var response_body: Dictionary = JSON.parse_string(\
				response_array[3].get_string_from_utf8())
			Navigator.load_recipe_screen(response_body.recipe_id)
		_: 
			print(response_array)
