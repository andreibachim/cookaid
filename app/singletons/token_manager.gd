extends Node

const FILE_LOCATION = "user://token.dat"

func save_token(token: String) -> Error:
	var file = FileAccess.open(FILE_LOCATION, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(token)
	file.close()
	State.TOKEN = token
	return OK
	
func load_token() -> String:
	var file= FileAccess.open(FILE_LOCATION, FileAccess.READ)
	var token = file.get_as_text() if file != null else ""
	State.TOKEN = token
	return token
	
func delete_token() -> void:
	var result: Error = DirAccess.remove_absolute(FILE_LOCATION)
	assert(result == OK, "Could not delete the token file")
	
func token_is_valid(token: String) -> bool:
	if (token.length() == 0): return false
	var request = HTTPRequest.new()
	add_child(request)
	request.request(State.API_BASE_URL + "/api/check-session", \
		["Content-Type: application/json"],\
		HTTPClient.METHOD_POST,
		JSON.stringify({"token": token})
	)
	var response = await request.request_completed
	request.queue_free.call_deferred()
	match response[1]:
		200: return true
		_: 
			TokenManager.delete_token()
			return false
	
