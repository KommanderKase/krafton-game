class_name CustomerManager
extends Node

@export var customer_sprite: Customer
@export var next_button: Button
## Drag and drop all your different character textures here in the Inspector!
@export var customer_textures: Array[Texture2D] = []

@export_group("Package Spawning")
## Drag and drop your different Package PackedScenes here (e.g., 1x1, small 2x3, long 7x2)
@export var package_scenes: Array[PackedScene] = []
## Reference to your PostalGrid so packages know where they can be sorted
@export var postal_grid: PostalGrid
## Container node where active packages are stored in the scene tree
@export var packages_container: Node2D

@export_group("Spawn Target Area (Table / Counter)")
@export var spawn_min_x: float = 100.0
@export var spawn_max_x: float = 500.0
@export var target_y: float = 350.0 ## The Y position on the counter/table where packages land
@export var spawn_duration: float = 1

var current_index: int = -1
var is_busy_transitioning: bool = false
var has_active_customer: bool = false

func _ready() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_customer_pressed)
	
	if customer_sprite:
		customer_sprite.fade_out_completed.connect(_on_customer_left)

func _on_next_customer_pressed() -> void:
	# Ignore clicks if we are already in the middle of fading someone in/out
	if is_busy_transitioning or customer_textures.is_empty():
		return
		
	is_busy_transitioning = true
	next_button.disabled = true # Temporarily disable button to prevent spam-clicking
	
	if has_active_customer:
		# Fade out the current person at the desk
		customer_sprite.fade_out()
	else:
		# Desk is empty, bring the first customer in immediately
		_bring_next_customer()

## Called automatically when Customer.gd finishes its fade_out tween
func _on_customer_left() -> void:
	has_active_customer = false
	_bring_next_customer()

func _bring_next_customer() -> void:
	# Cycle to the next texture in the array (loops back to 0 at the end)
	current_index = (current_index + 1) % customer_textures.size()
	customer_sprite.texture = customer_textures[current_index]
	
	customer_sprite.fade_in()
	
	# SPAWN A RANDOM PACKAGE WHEN THE NEW CUSTOMER ARRIVES
	_spawn_customer_package()
	
	has_active_customer = true
	is_busy_transitioning = false
	next_button.disabled = false

func _spawn_customer_package() -> void:
	if package_scenes.is_empty():
		return
		
	# Pick a random package scene from your array (e.g., randomizes between 1x1, small, or long)
	var random_scene = package_scenes.pick_random() as PackedScene
	if not random_scene:
		return
		
	# Instantiate the package
	var package = random_scene.instantiate() as Package
	
	# Add it to your container (or default to customer's parent if container is missing)
	if packages_container:
		packages_container.add_child(package)
	else:
		customer_sprite.get_parent().add_child(package)
		
	# Pass the PostalGrid reference so the new package can snap into cells
	package.postal_grid = postal_grid
	
	# Start position originates right at the customer sprite's center
	package.global_position = customer_sprite.global_position
	
	# Generate a random landing spot on your table/counter X range
	var random_x = randf_range(spawn_min_x, spawn_max_x)
	var target_pos = Vector2(random_x, target_y)
	
	# Animate smoothly using the exact same CUBIC EASE OUT style
	var spawn_tween = create_tween()
	spawn_tween.set_trans(Tween.TRANS_CUBIC)
	spawn_tween.set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(package, "global_position", target_pos, spawn_duration)
