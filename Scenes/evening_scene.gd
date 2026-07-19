extends Node2D

@export var package_scene: PackedScene      # Drag your TestPackage.tscn here

# This creates a handy folder selector directly in the Inspector!
@export_dir var packages_folder: String = "res://PACKAGES"

# We populate this array automatically through code now
var package_textures: Array[Texture2D] = []

@onready var drop_zone: Control = $DropZone
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var spawn_button: Button = $SpawnButton

func _ready() -> void:
	spawn_button.pressed.connect(_on_spawn_button_pressed)
	_load_packages_from_folder()

func _load_packages_from_folder() -> void:
	if packages_folder.is_empty():
		print("Warning: No packages folder path specified.")
		return

	var dir := DirAccess.open(packages_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Ignore actual sub-folders, look only at files
			if not dir.current_is_dir():
				# GODOT HACK: When Godot exports a game, it converts "image.png" into "image.png.import".
				# Using get_basename() cleanly strips away ".import" so the path remains valid!
				var clean_name = file_name.get_basename()
				
				# Check if it's a valid image extension
				if clean_name.ends_with(".png") or clean_name.ends_with(".jpg") or clean_name.ends_with(".jpeg"):
					var full_path = packages_folder.path_join(clean_name)
					var texture = load(full_path)
					
					# Avoid adding duplicate references if the scanner hits the file twice
					if texture and not package_textures.has(texture):
						package_textures.append(texture)
						
			file_name = dir.get_next()
		dir.list_dir_end()
		print("Successfully loaded ", package_textures.size(), " packages from folder!")
	else:
		print("Failed to open the directory: ", packages_folder)

func _on_spawn_button_pressed() -> void:
	if not package_scene or package_textures.is_empty():
		print("Warning: Make sure TestPackage.tscn is assigned and your PACKAGES folder isn't empty!")
		return
		
	var new_package = package_scene.instantiate()
	add_child(new_package)
	
	new_package.global_position = spawn_point.global_position
	
	var random_img = package_textures.pick_random()
	new_package.setup(random_img, drop_zone.get_global_rect())
