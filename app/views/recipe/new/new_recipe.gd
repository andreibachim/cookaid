extends VBoxContainer

@export var popup_template: PackedScene
@export var step_input_template: PackedScene
@export var step_template: PackedScene

@onready var recipe_name := $margin/carousel/name/recipe_name_input
@onready var description: TextEdit = $margin/carousel/details/description_vbox/description
@onready var reference: LineEdit = $margin/carousel/details/external_reference/reference
@onready var http_client: HTTPRequest = $http_client
@onready var carousel: TabContainer = $margin/carousel

@onready var recipe_id: String

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
			var body: Dictionary = JSON.parse_string((response_array[3] as PackedByteArray).get_string_from_utf8())
			recipe_id = body.recipe_id
			carousel.select_next_available()
		_:
			printerr("Could not create new recipe")
			printerr(response_array)

func _on_cancel_button_up():
	Navigator.load_recipes_list_screen()

func _on_description_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		var popup = popup_template.instantiate()
		get_parent().add_child(popup)
		popup.set_text(description.text)
		popup.text_submitted.connect(set_description)
		
func set_description(value: String) -> void:
	http_client.request(
		Config.API_URL + "/api/recipe/" + recipe_id,
		["Content-Type: application/json", "Authorization: Bearer " + Config.TOKEN],
		HTTPClient.METHOD_PUT,
		JSON.stringify({ "description": value })
	)
	var response_array = await http_client.request_completed
	var status_code = response_array[1]
	match status_code:
		200:
			description.text = value
		_:
			printerr("Could not update description")

func _on_reference_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		var popup = popup_template.instantiate()
		get_parent().add_child(popup)
		popup.set_text(reference.text)
		popup.text_submitted.connect(func(value: String):
				http_client.request(
					Config.API_URL + "/api/recipe/" + recipe_id,
					["Content-Type: application/json", "Authorization: Bearer " + Config.TOKEN],
					HTTPClient.METHOD_PUT,
					JSON.stringify({ "external_reference": value })
				)
				var response_array = await http_client.request_completed
				var status_code = response_array[1]
				match status_code:
					200:
						reference.text = value
					_:
						printerr("Could not update reference")
		)

func _on_next_button_up():
	carousel.select_next_available()

func _on_back_button_up():
	carousel.select_previous_available()

func _on_ingredients_edit_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		var popup = popup_template.instantiate()
		get_parent().add_child(popup)
		popup.text_submitted.connect(func(value: String):
			http_client.request(
				Config.API_URL + "/api/recipe/" + recipe_id + "/ingredient",
				["Content-Type: application/json", "Authorization: Bearer " + Config.TOKEN],
				HTTPClient.METHOD_POST,
				JSON.stringify({ "name": value })
			)
			var response_array = await http_client.request_completed
			var status_code = response_array[1]
			match status_code:
				200:
					add_ingredient(value)
				_:
					printerr("Could not add ingredient")
		)
@onready var ingredients_list = $margin/carousel/ingredients/list/vbox

func add_ingredient(ingredient: String) -> void:
	var label: Label = Label.new()
	label.text = ingredient
	ingredients_list.add_child(label)


func _on_step_edit_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		var popup = step_input_template.instantiate()
		get_parent().add_child(popup)
		
		popup.submitted.connect(func(value: StepValue):
			var payload: Dictionary = { "text": value.text }
			match value.type:
				"Normal": 
					payload.merge({ "step_type": "Normal" })
				"Timer": 
					payload.merge({ "step_type": { "Timer": value.time }})
			http_client.request(
				Config.API_URL + "/api/recipe/" + recipe_id + "/step",
				["Content-Type: application/json", "Authorization: Bearer " + Config.TOKEN],
				HTTPClient.METHOD_POST,
				JSON.stringify(payload),
			)
			var response_array = await http_client.request_completed
			var status_code = response_array[1]
			match status_code:
				200:
					var response = JSON.parse_string((response_array[3] as PackedByteArray).get_string_from_utf8())
					add_step(response)
				_:
					print(status_code)
					printerr("Could not add ingredient")
		)
		
@onready var step_list: VBoxContainer = $margin/carousel/steps/list/vbox 
func add_step(step: Dictionary) -> void:
	var step_node = step_template.instantiate()
	step_node.set_step(step)
	step_list.add_child(step_node)
