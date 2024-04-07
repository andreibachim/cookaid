extends MarginContainer

@onready var email_input = $vbox/registration_form/email_input
@onready var password_input = $vbox/registration_form/password_input

@onready var request = $register_request

func _on_submit_button_up():
	var payload = {
		"email": email_input.text,
		"password": password_input.text
	}
	
	request.request(
		State.API_BASE_URL + "/api/register", \
		["Content-Type: application/json"], \
		HTTPClient.METHOD_POST, \
		JSON.stringify(payload)
	)
	
	var response_array = await request.request_completed
	match response_array[1]:
		200:
			print("Success")
		400:
			print("Bad Request")
		409:
			print("Conflict")
		_:
			print("Internal Server Error")

func _on_login_link_button_up():
	get_tree().change_scene_to_file("res://screens/login/loginscreen.tscn")

