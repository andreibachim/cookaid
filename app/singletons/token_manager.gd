extends Node

const FILE_LOCATION = "user://token.dat"

func save_token(token: String) -> void:
	var file = FileAccess.open_encrypted_with_pass(FILE_LOCATION,\
		FileAccess.WRITE,\
		"itsapassword");
	file.store_string(token)
	file.close()
	
func get_token() -> String:
	if (FileAccess.file_exists(FILE_LOCATION)):
		var file = FileAccess.open_encrypted_with_pass(FILE_LOCATION,\
			FileAccess.READ,\
			"itsapassword");
		var token = file.get_as_text()
		file.close()
		return token
	else:
		return ""

func delete_token() -> void:
	if (FileAccess.file_exists(FILE_LOCATION)):
		DirAccess.remove_absolute(FILE_LOCATION)
