extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

@export_enum("MAIL", "PACKAGE", "SMALL_PACKAGE", "LONG_PACKAGE") var type_id: String = "PACKAGE"

@export_group("Sideways Textures")
@export var mail_sideways_texture: Texture2D
@export var package_sideways_texture: Texture2D
@export var small_package_sideways_texture: Texture2D
@export var long_package_sideways_texture: Texture2D

var default_texture: Texture2D
var is_held: bool = false
var is_draggable: bool = true
var drag_offset: Vector2 = Vector2.ZERO
var boundary_rect: Rect2 

var letter_data: MailItemData

func _ready() -> void:
	area.input_event.connect(_on_area_input_event)
	letter_data = MailItemData.new()
	letter_data.randomize_data()

func get_item_type() -> String:
	return type_id

func set_is_draggable(value: bool) -> void:
	is_draggable = value

func set_sideways_view(sideways: bool) -> void:
	if sideways:
		if default_texture == null:
			default_texture = sprite.texture
			
		var target_sideways_tex: Texture2D = null
		match type_id:
			"MAIL":
				target_sideways_tex = mail_sideways_texture
			"PACKAGE":
				target_sideways_tex = package_sideways_texture
			"SMALL_PACKAGE":
				target_sideways_tex = small_package_sideways_texture
			"LONG_PACKAGE":
				target_sideways_tex = long_package_sideways_texture

		if target_sideways_tex != null:
			sprite.texture = target_sideways_tex
			sprite.scale = Vector2.ONE
		else:
			rotation_degrees = 90.0
	else:
		if default_texture != null:
			sprite.texture = default_texture
		rotation_degrees = 0.0

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_draggable:
		return
		
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
			_check_pigeonhole_drop_or_constrain()

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset

func _check_pigeonhole_drop_or_constrain() -> void:
	var overlapping_areas = area.get_overlapping_areas()
	for col_area in overlapping_areas:
		var parent_node = col_area.get_parent()
		if parent_node.is_in_group("pigeonholes") and parent_node.has_method("accept_item"):
			parent_node.accept_item(self)
			return
			
	_constrain_to_boundary()

func _constrain_to_boundary() -> void:
	if boundary_rect == Rect2(): 
		return
		
	global_position.x = clamp(global_position.x, boundary_rect.position.x, boundary_rect.end.x)
	global_position.y = clamp(global_position.y, boundary_rect.position.y, boundary_rect.end.y)
