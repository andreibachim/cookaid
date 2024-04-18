extends Node

func load_login_screen() -> void:
	load_scene("res://views/login/login.tscn")
	
func load_recipes_list_screen() -> void:
	load_scene("res://views/recipe/list_view/list_view.tscn")
	
func load_new_recipe_screen() -> void:
	load_scene("res://views/recipe/new/new_recipe.tscn")

func load_scene(scene_name: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene_name)
