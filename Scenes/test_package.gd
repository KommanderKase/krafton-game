extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

# Define our strict game groups
enum PackageType { MAIL, PACKAGE, SMALL_PACKAGE, LONG_PACKAGE }
var package_type: PackageType

# --- TARGET DIMENSIONS FOR YOUR PUZZLE GRID ---
# Define exactly how big each block type should be on your desk/grid interface
@export_group("Strict Grid Target Sizes (Pixels)")
@export var mail_target: Vector2 = Vector2(120.0, 90.0)
@export var package_target: Vector2 = Vector2(240.0, 160.0)
@export var small_package_target: Vector2 = Vector2(120.0, 160.0)
@export var long_package_target: Vector2 = Vector2(360.0, 90.0)

var is_held: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var boundary_rect: Rect2 

func _ready() -> void:
	area.input_event.connect(_on_area_input_event)

func setup(custom_texture: Texture2D, target_boundary: Rect2) -> void:
	boundary_rect = target_boundary
	sprite.texture = custom_texture
	
	var original_size := custom_texture.get_size()	
	var aspect_ratio: float = original_size.x / original_size.y
	var chosen_target: Vector2 = Vector2.ZERO
	
	# --- 1. THE 4-WAY IDENTIFICATION ENGINE ---
	# We classify using structural thresholds derived from your raw files
	if aspect_ratio > 2.5:
		package_type = PackageType.LONG_PACKAGE
		chosen_target = long_package_target
	elif aspect_ratio < 1.0:
		package_type = PackageType.SMALL_PACKAGE
		chosen_target = small_package_target
	else:
		# Both Mail and Standard Package are wide, distinguished by raw size thresholds
		if original_size.x < 250.0:
			package_type = PackageType.MAIL
			chosen_target = mail_target
		else:
			package_type = PackageType.PACKAGE
			chosen_target = package_target

	# --- 2. FORCE UNIFORM GRID ALIGNMENT ---
	# We divide our exact target dimensions by the raw dimensions.
	# This guarantees that minor cropping errors vanish completely!
	var final_scale := chosen_target / original_size
	sprite.scale = final_scale
	
	# Adjust the physics bounding box to match the uniform grid space perfectly
	var current_shape = $Area2D/CollisionShape2D.shape as RectangleShape2D
	if current_shape:
		current_shape.size = chosen_target

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_held:
			is_held = true
			drag_offset = global_position - get_global_mouse_position()
			get_parent().move_child(self, -1)
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_held:
			is_held = false
			_constrain_to_boundary()

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset

func _constrain_to_boundary() -> void:
	if boundary_rect == Rect2(): 
		return
		
	global_position.x = clamp(global_position.x, boundary_rect.position.x, boundary_rect.end.x)
	global_position.y = clamp(global_position.y, boundary_rect.position.y, boundary_rect.end.y)
