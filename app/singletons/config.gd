extends Node

var API_URL: String = "http://192.168.0.127:8080"
var TOKEN: String

func _ready() -> void:
	var api_url_env_var = OS.get_environment("API_URL")
	if !api_url_env_var.is_empty(): API_URL = api_url_env_var
