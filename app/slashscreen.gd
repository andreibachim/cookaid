extends Control

func _ready():
	await get_tree().create_timer(.5, true).timeout
	move_on()
	
func move_on():
	get_tree().change_scene_to_file("res://screens/login/loginscreen.tscn")
