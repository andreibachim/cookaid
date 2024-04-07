extends Node

@onready var email_input = $vbox/login_form/email_input
@onready var password_input = $vbox/login_form/password_input

@onready var request = $login_request

func _on_submit_button_up():
	var payload: Dictionary = {
		"email": email_input.text,
		"password": password_input.text
	}
	
	request.request(
		State.API_BASE_URL + "/api/login", \
		["Content-Type: application/json"], \
		HTTPClient.METHOD_POST, \
		JSON.stringify(payload)
	)
	var response_array = await request.request_completed
	match response_array[1]:
		200:
			var response_json: Dictionary = JSON.parse_string(
				response_array[3].get_string_from_utf8())
			var token = response_json.get("token")
			TokenManager.save_token(token)
			get_tree().change_scene_to_file("res://screens/recipes/recipes.tscn")
		400:
			print("Bad Request")
		_:
			print("Internal Server Error")

func _on_register_link_button_up():
	get_tree().change_scene_to_file("res://screens/register/registerscreen.tscn")

