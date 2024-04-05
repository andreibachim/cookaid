extends MarginContainer

@onready var popup = $popup
@onready var create_request: HTTPRequest = HTTPRequest.new()

@onready var recipe_name_input = $popup/background/margin/vbox/recipe_name_input

func _ready():
	popup.visible = false
	add_child(create_request)

func _on_new_recipe_button_up():
	popup.popup()

func _on_cancel_button_button_up():
	popup.hide()

func _on_create_button_button_up():
	var payload: Dictionary = {
		"name": recipe_name_input.text
	}
	create_request.request(Variables.API_BASE_URL + "/api/recipe",\
		["Content-Type: application/json",\
		"Authorization: Bearer " + TokenManager.get_token()],\
		HTTPClient.METHOD_POST,\
		JSON.stringify(payload))
	var response_array = await create_request.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			var response_body = response_array[3].get_string_from_utf8()
			Navigator.load_new_recipe_screen()
		_: 
			print(response_array)
