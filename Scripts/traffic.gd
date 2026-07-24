extends Node2D

@export_group("Spawn Bounds")
## Starting X coordinate on the left side of the screen
@export var left_x: float = -200.0
## Destination X coordinate on the right side of the screen
@export var right_x: float = 2100.0
## Fixed Y position where vehicles move across
@export var road_y: float = 600.0

@export_group("Traffic Control")
## 0.0 = Quiet/Sparse traffic, 1.0 = Heavy/Frequent traffic
@export_range(0.01, 1.0, 0.05) var traffic_density: float = .3
## Minimum time (in seconds) between spawns at MAX density (1.0)
@export var min_spawn_interval: float = 1.0
## Maximum time (in seconds) between spawns at MIN density (0.01)
@export var max_spawn_interval: float = 8.0

# Speed ranges defined per vehicle category (in pixels per second)
var speed_ranges: Dictionary = {
	"Bicycle": Vector2(150.0, 300.0),      # Tight range, slow speed
	"Car": Vector2(300.0, 700.0),         # Wide range, slow to fast speed
	"BoxTruck": Vector2(200.0, 400.0)     # Moderate range, medium speed
}

# Categorized template nodes found in child hierarchy
var vehicle_templates: Dictionary = {
	"Bicycle": [],
	"Car": [],
	"BoxTruck": []
}

var spawn_timer: Timer

func _ready() -> void:
	_catalog_preplaced_vehicles()	
	_setup_spawn_timer()

func _catalog_preplaced_vehicles() -> void:
	# Scan all existing child nodes, categorize them, and hide original templates
	for child in get_children():
		if child is Node2D:
			var category: String = _get_category_from_name(child.name)
			if category != "":
				vehicle_templates[category].append(child)
				# Hide template original so it doesn't show in scene static
				child.visible = false

func _get_category_from_name(node_name: String) -> String:
	if node_name.begins_with("Bicycle"):
		return "Bicycle"
	elif node_name.begins_with("Car"):
		return "Car"
	elif node_name.begins_with("BoxTruck"):
		return "BoxTruck"
	return ""

func _setup_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	# Higher traffic_density = lower interval delay
	var base_delay: float = lerp(max_spawn_interval, min_spawn_interval, traffic_density)
	var randomized_delay: float = randf_range(base_delay * 0.7, base_delay * 1.3)
	
	spawn_timer.start(max(0.2, randomized_delay))

func _on_spawn_timer_timeout() -> void:
	_spawn_vehicle_duplicate()
	_schedule_next_spawn()

func _spawn_vehicle_duplicate() -> void:
	# 1. Gather categories that actually have pre-placed template nodes
	var available_categories: Array[String] = []
	for category in vehicle_templates.keys():
		if vehicle_templates[category].size() > 0:
			available_categories.append(category)
			
	if available_categories.is_empty():
		push_warning("No vehicle templates starting with Bicycle, Car, or BoxTruck found under " + name)
		return
		
	# 2. Pick a random category & random pre-placed template
	var chosen_category: String = available_categories.pick_random()
	var template_node: Node2D = vehicle_templates[chosen_category].pick_random()
	
	# 3. Duplicate the chosen template node
	var vehicle_clone: Node2D = template_node.duplicate() as Node2D
	vehicle_clone.visible = true  # Make the clone visible
	
	# 4. Determine random travel direction (Left-to-Right OR Right-to-Left)
	var travel_right: bool = randf() > 0.5
	var start_x: float = left_x if travel_right else right_x
	var target_x: float = right_x if travel_right else left_x
	
	vehicle_clone.position = Vector2(start_x, road_y)
	
	# Flip visual orientation if traveling leftward
	if not travel_right:
		vehicle_clone.scale.x = -abs(vehicle_clone.scale.x)
	else:
		vehicle_clone.scale.x = abs(vehicle_clone.scale.x)
		
	add_child(vehicle_clone)
	
	# 5. Calculate travel speed based on category bounds
	var speed_bounds: Vector2 = speed_ranges[chosen_category]
	var speed: float = randf_range(speed_bounds.x, speed_bounds.y)
	
	# 6. Animate movement along X-axis and queue_free the duplicate upon arrival
	var distance: float = abs(target_x - start_x)
	var travel_time: float = distance / speed
	
	var tween: Tween = create_tween()
	tween.tween_property(vehicle_clone, "position:x", target_x, travel_time)
	tween.tween_callback(vehicle_clone.queue_free)
