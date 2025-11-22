extends Node3D

func _ready():
	print("=== MINIMAL TEST SCENE LOADED ===")
	
	# Create a simple 3D object to show something
	var box = CSGBox3D.new()
	box.size = Vector3(2, 2, 2)
	box.material = StandardMaterial3D.new()
	box.material.albedo_color = Color.RED
	add_child(box)
	
	print("Red box created!")
	print("If you see this, the scene is working!")
