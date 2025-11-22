extends Node3D

func _ready():
	# Simple test: spawn one character
	var unit = Character.new()
	unit.character_name = "TestUnit"
	unit.current_class = "Gunner"
	
	add_child(unit)
	await get_tree().process_frame
	
	# Try to set position
	var test_pos: Vector3 = Vector3(2.0, 0.0, 2.0)
	print("Setting position to: ", test_pos, " type: ", typeof(test_pos))
	unit.global_position = test_pos
	print("Position set successfully!")
