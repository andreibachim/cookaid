extends MarginContainer

var recipe: Dictionary

@onready var title := $vbox/title
@onready var delete_button := $vbox/actions/delete
@onready var edit_button := $vbox/actions/edit
@onready var cook_button := $vbox/actions/cook

@onready var http_client: HTTPRequest = $http_client

func init(recipe_prop: Dictionary) -> void:
	recipe = recipe_prop

func _ready() -> void:
	title.text = recipe.name
	if recipe.status.to_lower() == "draft":
		cook_button.disabled = true

func _on_delete_button_up():
	var id = recipe.recipe_id
	http_client.request(
		Config.API_URL + "/api/recipe/" + id,
		["Authorization: Bearer " + Config.TOKEN],
		HTTPClient.METHOD_DELETE
	)
	var response_array = await http_client.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			queue_free()
		_:
			printerr("Could not delete recipe!")
