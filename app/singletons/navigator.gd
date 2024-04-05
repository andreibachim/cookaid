extends Node

func load_new_recipe_screen() -> void:
	load_screen("res://screens/new_recipe/new-recipe.tscn")
	
func load_screen(file: String) -> void:
	get_tree().change_scene_to_file.call_deferred(file)
