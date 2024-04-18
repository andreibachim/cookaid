extends VBoxContainer

@export var popup_template: PackedScene

@onready var recipe_name := $margin/carousel/name/recipe_name_input
@onready var description: TextEdit = $margin/carousel/details/description_vbox/description
@onready var http_client: HTTPRequest = $http_client
@onready var carousel: TabContainer = $margin/carousel

func _ready() -> void:
	recipe_name.grab_focus()

func _on_recipe_name_next_button_up():
	var payload := {
		"name": recipe_name.text
	}
	
	http_client.request(
		Config.API_URL + "/api/recipe",
		["Content-Type: application/json", "Authorization: Bearer " + Config.TOKEN],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	var response_array = await http_client.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			carousel.select_next_available()
		_:
			printerr("Could not create new recipe")
			printerr(response_array)

func _on_cancel_button_up():
	Navigator.load_recipes_list_screen()

func _on_back_to_name_button_up():
	carousel.select_previous_available()

func _on_description_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		var popup = popup_template.instantiate()
		get_parent().add_child(popup)
		popup.set_text(description.text)
		popup.text_submitted.connect(func(value): description.text = value)
