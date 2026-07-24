extends Node2D

@export var package_scene: PackedScene
@export var letter_scene: PackedScene
@export_dir var packages_folder: String = "res://Assets/Images/Background and Objects/PACKAGES"

var package_textures: Array[Texture2D] = []

@onready var drop_zone: Control = $DropZone
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var spawn_button: Button = $SpawnButton
@onready var spawn_button2: Button = $SpawnButton2

# Pigeonhole references — will be created if missing
var local_pigeonhole: Area2D = null
var interstate_pigeonhole: Area2D = null

func _ready() -> void:
	GameManager.set_phase("evening")
	
	# Ensure pigeonholes exist (create if missing from scene)
	_ensure_pigeonholes_exist()
	_setup_pigeonholes()
	_load_packages_from_folder()
	
	# Connect button signals
	if spawn_button:
		spawn_button.pressed.connect(_on_spawn_button_pressed)
	if spawn_button2:
		spawn_button2.pressed.connect(_on_spawn_letters)

# ==========================================
# --- PIGEONHOLE SETUP ---
# ==========================================

func _ensure_pigeonholes_exist() -> void:
	# Try to find existing pigeonholes in scene
	local_pigeonhole = find_child("PigeonholeLocal", true, false)
	interstate_pigeonhole = find_child("PigeonholeInterstate", true, false)
	
	# If they don't exist, create them programmatically
	if not local_pigeonhole:
		print("Creating PigeonholeLocal Area2D...")
		local_pigeonhole = _create_pigeonhole("PigeonholeLocal", Vector2(200, 750))
		add_child(local_pigeonhole)
	
	if not interstate_pigeonhole:
		print("Creating PigeonholeInterstate Area2D...")
		interstate_pigeonhole = _create_pigeonhole("PigeonholeInterstate", Vector2(700, 750))
		add_child(interstate_pigeonhole)

func _create_pigeonhole(name: String, position: Vector2) -> Area2D:
	var area = Area2D.new()
	area.name = name
	area.position = position
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(250, 200)  # Size of pigeonhole
	collision.shape = shape
	area.add_child(collision)
	
	return area

func _setup_pigeonholes() -> void:
	if local_pigeonhole:
		local_pigeonhole.add_to_group("pigeonholes")
		print("✓ Local pigeonhole ready at ", local_pigeonhole.global_position)
	else:
		push_error("Local pigeonhole failed to initialize!")
		
	if interstate_pigeonhole:
		interstate_pigeonhole.add_to_group("pigeonholes")
		print("✓ Interstate pigeonhole ready at ", interstate_pigeonhole.global_position)
	else:
		push_error("Interstate pigeonhole failed to initialize!")

# ==========================================
# --- ASSET LOADING ---
# ==========================================

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
				var clean_file = file_name.replace(".import", "")
				if clean_file.ends_with(".png") or clean_file.ends_with(".jpg") or clean_file.ends_with(".jpeg"):
					var full_path = packages_folder.path_join(clean_file)
					var texture = load(full_path) as Texture2D
					if texture and not package_textures.has(texture):
						package_textures.append(texture)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("Successfully loaded %d package textures from %s" % [package_textures.size(), packages_folder])
	else:
		print("Failed to open directory: %s" % packages_folder)

# ==========================================
# --- SPAWN HANDLERS (DEBUG/TEST) ---
# ==========================================

func _on_spawn_button_pressed() -> void:
	if not package_scene:
		print("ERROR: TestPackage.tscn not assigned to 'Package Scene' in Inspector!")
		return
		
	if package_textures.is_empty():
		print("ERROR: No textures in %s" % packages_folder)
		return
		
	var new_package = package_scene.instantiate()
	add_child(new_package)
	
	var spawn_pos = spawn_point.global_position if spawn_point else Vector2(200, 200)
	new_package.global_position = spawn_pos
	
	var random_img = package_textures.pick_random()
	var boundary = drop_zone.get_global_rect() if drop_zone else Rect2()
	
	if new_package.has_method("setup"):
		new_package.setup(random_img, boundary)
		print("✓ Spawned package at ", spawn_pos)
	else:
		print("ERROR: Package scene missing setup() method")

func _on_spawn_letters() -> void:
	if not letter_scene:
		print("ERROR: Letter scene not assigned in Inspector!")
		return
	
	# Create test letters inline (for debug testing)
	var test_letters = _create_test_letters()
	
	if test_letters.is_empty():
		print("ERROR: No test letters created")
		return
	
	var drop_zones = []
	if local_pigeonhole:
		drop_zones.append(local_pigeonhole)
	if interstate_pigeonhole:
		drop_zones.append(interstate_pigeonhole)
	
	print("Spawning %d test letters with drop zones..." % test_letters.size())
	
	var offset := Vector2.ZERO
	for letter_data in test_letters:
		var letter_instance = letter_scene.instantiate()
		
		# Assign a test texture so it's visible
		if letter_instance is LetterSprite:
			if package_textures.size() > 0:
				letter_instance.texture = package_textures.pick_random()
			else:
				# Fallback: create a plain colored rectangle
				var placeholder = Image.create(100, 80, false, Image.FORMAT_RGB8)
				placeholder.fill(Color.WHITE)
				letter_instance.texture = ImageTexture.create_from_image(placeholder)
		
		add_child(letter_instance)
		
		var spawn_pos = spawn_point.global_position + offset if spawn_point else offset
		letter_instance.global_position = spawn_pos
		
		# Set up with letter data and drop zones
		letter_instance.setup(letter_data, drop_zones)
		
		offset.x += 15
		offset.y += 8
	
	print("✓ Spawned %d test letters" % test_letters.size())

## Create mock letter data for testing/debugging
func _create_test_letters() -> Array[LetterResource]:
	var letters: Array[LetterResource] = []
	
	# Test letter 1 — LOCAL, should go to left pigeonhole
	var letter1 = LetterResource.new()
	letter1.letter_id = "TEST_001"
	letter1.sender_name = "Alice Smith"
	letter1.recipient_name = "Bob Jones"
	letter1.recipient_address = "123 Main St"
	letter1.town = "Boston"
	letter1.state = "MA"
	letter1.route = "local"
	letter1.mail_class = "standard"
	letters.append(letter1)
	
	# Test letter 2 — INTERSTATE, should go to right pigeonhole
	var letter2 = LetterResource.new()
	letter2.letter_id = "TEST_002"
	letter2.sender_name = "Charlie Davis"
	letter2.recipient_name = "Diana Evans"
	letter2.recipient_address = "456 Oak Ave"
	letter2.town = "Denver"
	letter2.state = "CO"
	letter2.route = "interstate"
	letter2.mail_class = "express"
	letters.append(letter2)
	
	# Test letter 3 — LOCAL
	var letter3 = LetterResource.new()
	letter3.letter_id = "TEST_003"
	letter3.sender_name = "Eve Frank"
	letter3.recipient_name = "Frank Garcia"
	letter3.recipient_address = "789 Pine Rd"
	letter3.town = "Boston"
	letter3.state = "MA"
	letter3.route = "local"
	letter3.mail_class = "standard"
	letters.append(letter3)
	
	return letters

func _on_end_of_day() -> void:
	GameManager.end_of_day()
	get_tree().change_scene_to_file("res://Scenes/night_scene.tscn")
