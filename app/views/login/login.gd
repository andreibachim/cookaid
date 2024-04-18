extends Control

# MEMBERS
@onready var email_input := $margin/form/email
@onready var password_input := $margin/form/password
@onready var login_button := $margin/form/login
@onready var login_client := $margin/form/login_client

func _on_login_button_up():
	var payload = { 
		"email": email_input.text,
		"password": password_input.text
	}

	login_client.request(
		Config.API_URL + "/api/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	var response_array = await login_client.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			var token = JSON.parse_string((response_array[3] as PackedByteArray)\
				.get_string_from_utf8()).token
			if !save_token(token):
				Config.TOKEN = token
				Navigator.load_recipes_list_screen()
			else:
				printerr("Could not save token")
		_:
			printerr(response_array)
			printerr("Failed to login")

func save_token(token: String) -> Error:
	var file := FileAccess.open("user://token", FileAccess.WRITE)
	if file == null: FileAccess.get_open_error()
	file.store_string(token)
	return Error.OK
