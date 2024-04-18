extends ColorRect

func _on_log_out_button_up():
	match DirAccess.remove_absolute("user://token"):
		OK: 
			Config.TOKEN = ""
			Navigator.load_login_screen()
		_: printerr("Could not delete session token")

