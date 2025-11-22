extends Node

# Game Data Container

var units: Dictionary = {}
var items: Dictionary = {}
var skills: Dictionary = {}

func _ready():
	print("[GameData] Initialized")
	_load_data()

func _load_data():
	# TODO: Load JSON or Resource files
	pass
