extends Button

# Creates a scene picker slot in the Godot Inspector
@export_file("*.tscn") var target_scene: String

func _ready() -> void:
	# Automatically connects the button click to our function
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if target_scene != "":
		SceneTransition.transition_to_scene(target_scene)
	else:
		print("Warning: Assign a target scene in the Inspector first!")
