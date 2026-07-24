extends Node2D

@export var package_scene: PackedScene
@export var letter_scene: PackedScene
@export_dir var packages_folder: String = "res://PACKAGES"

var package_textures: Array[Texture2D] = []

@onready var drop_zone: Control = $DropZone
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var spawn_button: Button = $SpawnButton
@onready var spawn_button2: Button = $SpawnButton2

func _ready() -> void:
	spawn_button.pressed.connect(_on_spawn_button_pressed)
	spawn_button2.pressed.connect(_on_spawn_letters)
	GameManager.set_phase("evening")
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
			if not dir.current_is_dir():
				var clean_name = file_name.get_basename()
				if clean_name.ends_with(".png") or clean_name.ends_with(".jpg") or clean_name.ends_with(".jpeg"):
					var full_path = packages_folder.path_join(clean_name)
					var texture = load(full_path)
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

func _on_spawn_letters() -> void:
	if not letter_scene:
		print("Warning: No letter scene assigned.")
		return
	var all_letters = LetterManager.incoming_pile + LetterManager.outgoing_pile
	if all_letters.is_empty():
		print("No letters to spawn — LetterManager piles are empty.")
		return
	var offset := Vector2.ZERO
	for letter_data in all_letters:
		var letter_instance = letter_scene.instantiate()
		add_child(letter_instance)
		letter_instance.global_position = spawn_point.global_position + offset
		letter_instance.setup(letter_data, drop_zone.get_global_rect())
		offset.x += 15
		offset.y += 8

func _on_end_of_day() -> void:
	GameManager.end_of_day()
	get_tree().change_scene_to_file("res://Scenes/night_scene.tscn")
