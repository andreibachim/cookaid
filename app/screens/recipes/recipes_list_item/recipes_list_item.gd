extends MarginContainer

@onready var link: Button = $hbox/actions/edit_link
@onready var status := $hbox/status
@onready var title := $hbox/title
var recipe_id: String

func set_up(recipe: Dictionary) -> void:
	if recipe.status == "DRAFT":
		status.text = "[DRAFT]"
	title.text = recipe.name
	recipe_id = recipe.recipe_id

func _on_link_button_up():
	Navigator.load_recipe_screen(recipe_id)
