extends Node

var TOKEN: String
var API_BASE_URL: String

func _ready():
	var base_url_env_var = OS.get_environment("cookaid_base_url")
	API_BASE_URL = base_url_env_var \
		if base_url_env_var.length() > 0 \
		else "http://192.168.0.129:8080"
