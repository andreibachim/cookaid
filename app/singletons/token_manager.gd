extends Node

const FILE_LOCATION = "user://token.dat"
var secret = ""

func _ready() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.request(Variables.API_BASE_URL + "/api/encryption-token")
	var response_array = await request.request_completed
	var response: Dictionary = JSON.parse_string(response_array[3].get_string_from_utf8())
	secret = response.get("secret")
	
func save_token(token: String) -> void:
	var file = FileAccess.open_encrypted_with_pass(FILE_LOCATION,\
		FileAccess.WRITE,\
		secret);
	file.store_string(token)
	file.close()

func get_token() -> String:
	if (FileAccess.file_exists(FILE_LOCATION)):
		var file = FileAccess.open_encrypted_with_pass(FILE_LOCATION,\
			FileAccess.READ,\
			secret);
		if file == null: 
			delete_token()
			return ""
		var token = file.get_as_text()
		file.close()
		return token
	else:
		return ""

func delete_token() -> void:
	if (FileAccess.file_exists(FILE_LOCATION)):
		DirAccess.remove_absolute(FILE_LOCATION)
