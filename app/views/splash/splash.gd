extends Control

@onready var request = HTTPRequest.new()

func _ready():
	# Add request child
	add_child(request)
	
	# Try to load the token
	var token = FileAccess.get_file_as_string("user://token")
	# Check the token
	if await token_is_not_valid(token): 
		load_login_view()
		return
	# Store token
	Config.TOKEN = token
	# Redirect to appropriate screen
	load_recipes_page()
	
func load_login_view() -> void:
	Navigator.load_login_screen()

func load_recipes_page() -> void:
	Navigator.load_recipes_list_screen()

func token_is_not_valid(token: String) -> bool:
	if token.is_empty(): return true
	var payload := JSON.stringify({ "token": token })
	request.request(
		Config.API_URL + "/api/check-session", 
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		payload
	)
	var response_array = await request.request_completed
	var status_code = response_array[1]
	match status_code:
		200: return false
		_: return true
	
	
