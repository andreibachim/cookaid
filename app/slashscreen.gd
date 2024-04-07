extends Control

@onready var request: HTTPRequest = $check_session_request

func _ready():
	# Show logo
	await get_tree().create_timer(.5).timeout
	
	# Load the token
	var token = TokenManager.load_token();
	if not await TokenManager.token_is_valid(token):
		Navigator.load_login_screen()
	else:
		Navigator.load_recipes_screen()
