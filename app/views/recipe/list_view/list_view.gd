extends VBoxContainer

@export var list_item_template: PackedScene

#MEMBERS
@onready var http_client: HTTPRequest = $http_client
@onready var recipes_list := $list/vbox

func _ready() -> void:
	http_client.request(
		Config.API_URL + "/api/recipe",
		["Authorization: Bearer " + Config.TOKEN],
	)
	var response_array = await http_client.request_completed
	var status_code = response_array[1]
	match status_code:
		200: 
			var body = JSON.parse_string(
				(response_array[3] as PackedByteArray).get_string_from_utf8())
			for recipe in body:
				var recipe_item := list_item_template.instantiate()
				recipe_item.init(recipe)
				recipes_list.add_child(recipe_item)
		_:
			printerr("Could not load recipes")
			
func _on_logout_button_up() -> void:
	match DirAccess.remove_absolute("user://token"):
		OK: 
			Config.TOKEN = ""
			Navigator.load_login_screen()
		_: printerr("Could not delete session token")
