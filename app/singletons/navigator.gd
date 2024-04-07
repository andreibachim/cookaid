extends Node

var next_recipe_id: String

func load_login_screen() -> void:
	load_screen("res://screens/login/loginscreen.tscn")
	
func load_recipes_screen() -> void:
	load_screen("res://screens/recipes/recipes.tscn")
	
func load_recipe_screen(recipe_id: String) -> void:
	next_recipe_id = recipe_id
	load_screen("res://screens/edit_recipe/edit_recipe.tscn")
	
func load_screen(file: String) -> void:
	get_tree().change_scene_to_file.call_deferred(file)
	
