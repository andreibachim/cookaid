extends VBoxContainer

#REFS
var ingredient_template: PackedScene = load("res://components/ingredient/ingredient.tscn")

#VARIABLES
var recipe_id;

#MEMBERS 
@onready var request := $request
@onready var input := $ingredients_form/ingredients_input
@onready var list := $ingredients_list

func _on_add_ingredient_button_button_up():
	var ingredient = input.text
	perform_request(ingredient)

func add_ingredient(ingredient: Dictionary):
	var ingredient_label = ingredient_template.instantiate()
	list.add_child.call_deferred(ingredient_label)
	ingredient_label.set_ingredient.call_deferred(ingredient, recipe_id)

func perform_request(ingredient: String) -> void:
	request.request(get_url(),
		["Content-Type: application/json", "Authorization: Bearer " + State.TOKEN],
		HTTPClient.METHOD_POST,
		JSON.stringify({ "name" : ingredient })
	)
	var response_array = await request.request_completed
	match response_array[1]:
		200: 
			var body: Dictionary = JSON.parse_string(response_array[3].get_string_from_utf8())
			add_ingredient(body)
		_: print("Failure")

func get_url() -> String:
	return State.API_BASE_URL + "/api/recipe/"+ recipe_id +"/ingredient"
