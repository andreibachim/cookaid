extends Control

@onready var request: HTTPRequest = $check_session_request

func _ready():
	await get_tree().create_timer(.5).timeout
	var token = TokenManager.get_token()
	if (await token_is_valid(token)):
		recipes_screen()
	else:
		login_screen()
		
func login_screen():
	get_tree().change_scene_to_file.call_deferred("res://screens/login/loginscreen.tscn")

func recipes_screen():
	get_tree().change_scene_to_file.call_deferred("res://screens/recipes/recipes.tscn")

func token_is_valid(token: String) -> bool:
	if (token.length() == 0): return false
	request.request(Variables.API_BASE_URL + "/api/check-session", \
		["Content-Type: application/json"],\
		HTTPClient.METHOD_POST,
		JSON.stringify({"token": token})
	)
	var response = await request.request_completed
	match response[1]:
		200: return true
		_: 
			TokenManager.delete_token()
			return false
