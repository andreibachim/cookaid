extends MarginContainer

@onready var link: Button = $hbox/link
@onready var status := $hbox/status
var recipe_id: String


func set_up(recipe: Dictionary) -> void:
	if recipe.status == "DRAFT":
		status.text = "[DRAFT]"
	link.text = recipe.name
	recipe_id = recipe.recipe_id

func _on_link_button_up():
	Navigator.load_recipe_screen(recipe_id)
