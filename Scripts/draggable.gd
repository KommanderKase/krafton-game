class_name DraggableSprite
extends Sprite2D

## Toggle whether this sprite can be dragged or is locked in place
@export var is_draggable: bool = true:
	set(value):
		is_draggable = value
		_update_lock_visuals()

## Optional: Visual indicator when locked (e.g., slightly dimmed)
@export var dim_when_locked: bool = false

## Group name assigned to your DragZone Area2Ds
@export var drag_zone_group: String = "drag_zone"

## How long (in seconds) the snap-back animation takes when released outside bounds
@export_range(0.05, 1.0, 0.05) var return_duration: float = 0.25

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_z_index: int = 0
var last_valid_position: Vector2 = Vector2.ZERO

# Keeps track of the DragZone this item is currently resting on
var current_drag_zone: Area2D = null
var local_zone_offset: Vector2 = Vector2.ZERO

# Active return animation tween
var return_tween: Tween = null

func _ready() -> void:
	original_z_index = z_index
	_update_lock_visuals()
	call_deferred("_attach_to_current_zone")

func _unhandled_input(event: InputEvent) -> void:
	if not is_draggable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_mouse_over():
				_start_drag()
				get_viewport().set_input_as_handled()
		elif is_dragging:
			_stop_drag()

func _process(delta: float) -> void:
	if is_dragging:
		var target_pos = get_global_mouse_position() + drag_offset
		global_position = global_position.lerp(target_pos, 30.0 * delta)
		
		# Only update last valid position if ALL 4 corners fit inside a zone
		if _get_drag_zone_at(global_position) != null:
			last_valid_position = global_position
			
	elif is_instance_valid(current_drag_zone) and (return_tween == null or not return_tween.is_running()):
		global_position = current_drag_zone.to_global(local_zone_offset)

func _start_drag() -> void:
	if return_tween and return_tween.is_running():
		return_tween.kill()
		
	is_dragging = true
	drag_offset = global_position - get_global_mouse_position()
	last_valid_position = global_position
	current_drag_zone = null
	z_index = 100

func _stop_drag() -> void:
	is_dragging = false
	z_index = original_z_index
	
	# If released while any corner is sticking out, slide back to last valid position
	if _get_drag_zone_at(global_position) == null:
		_clamp_to_boundary_smoothly()
	else:
		_attach_to_current_zone()

## Smoothly animates the sprite back to the last position where it completely fit
func _clamp_to_boundary_smoothly() -> void:
	if return_tween and return_tween.is_running():
		return_tween.kill()

	return_tween = create_tween()
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_ease(Tween.EASE_OUT)
	# Slide back to last_valid_position where all 4 corners are guaranteed inside
	return_tween.tween_property(self, "global_position", last_valid_position, return_duration)
	return_tween.tween_callback(_attach_to_current_zone)

## Connects this sprite to the DragZone directly underneath it (if fully inside)
func _attach_to_current_zone() -> void:
	current_drag_zone = _get_drag_zone_at(global_position)
	if current_drag_zone:
		local_zone_offset = current_drag_zone.to_local(global_position)

## Returns the DragZone if ALL 4 sprite corners fit inside it; otherwise returns null
func _get_drag_zone_at(pos: Vector2) -> Area2D:
	var corners = _get_corners_at_position(pos)
	
	# Get all candidate drag zones under corner 0 (top-left)
	var candidate_zones = _get_all_drag_zones_at_point(corners[0])
	
	for zone in candidate_zones:
		var fits_completely = true
		# Verify that the remaining 3 corners are inside this EXACT same zone
		for i in range(1, corners.size()):
			if not _is_point_in_zone(corners[i], zone):
				fits_completely = false
				break
		if fits_completely:
			return zone
			
	return null

## Calculates the 4 world-space corners of the sprite if it were located at `pos`
func _get_corners_at_position(pos: Vector2) -> Array[Vector2]:
	if texture == null:
		return [pos]
		
	var r = get_rect()
	# Construct a transform centered at `pos` matching current rotation and scale
	var xform = Transform2D(global_transform.x, global_transform.y, pos)
	
	return [
		xform * r.position,                             # Top-Left
		xform * Vector2(r.end.x, r.position.y),         # Top-Right
		xform * Vector2(r.position.x, r.end.y),         # Bottom-Left
		xform * r.end                                   # Bottom-Right
	]

## Point query to check if a single position collides with a specific Area2D
func _is_point_in_zone(pos: Vector2, zone: Area2D) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_point(query)
	for res in results:
		if res.collider == zone:
			return true
	return false

## Returns all valid DragZone Area2Ds intersecting a single point
func _get_all_drag_zones_at_point(pos: Vector2) -> Array[Area2D]:
	var zones: Array[Area2D] = []
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_point(query)
	for result in results:
		if _is_drag_zone(result.collider):
			zones.append(result.collider as Area2D)
	return zones

func _is_drag_zone(collider: Object) -> bool:
	return collider is Area2D and collider.is_in_group(drag_zone_group)

func _is_mouse_over() -> bool:
	if texture == null:
		return false
	var local_mouse = get_local_mouse_position()
	return get_rect().has_point(local_mouse)

func set_locked(locked: bool) -> void:
	is_draggable = !locked

func toggle_lock() -> void:
	is_draggable = !is_draggable

func _update_lock_visuals() -> void:
	if dim_when_locked:
		modulate = Color(1, 1, 1, 1) if is_draggable else Color(0.6, 0.6, 0.6, 0.8)
