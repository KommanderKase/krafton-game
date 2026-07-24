class_name DraggableSprite
extends Node2D # Inherited by Sprite2D, Area2D, and Node2D!

## Shared static counter so every newly dragged item gets placed on top of all others
static var global_z_counter: int = 10

## Toggle whether this item can be dragged or is locked in place
@export var is_draggable: bool = true:
	set(value):
		is_draggable = value
		_update_lock_visuals()

## Optional: Visual indicator when locked (dims the node and all child sprites)
@export var dim_when_locked: bool = false

## Group name assigned to your DragZone Area2Ds
@export var drag_zone_group: String = "drag_zone"

## How long (in seconds) the snap-back animation takes when released outside bounds
@export_range(0.05, 1.0, 0.05) var return_duration: float = 0.25

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_z_index: int = 0
var last_valid_position: Vector2 = Vector2.ZERO

# Reference to the PostalGrid if this package is dropped onto one
var postal_grid: Node

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
	
	# If this item was on a grid, remove it from memory so its cells open back up
	if self.has_method("get") and self.get("is_placed_on_grid") == true and postal_grid:
		if postal_grid.has_method("remove_package_from_grid"):
			postal_grid.remove_package_from_grid(self)
		
	last_valid_position = global_position
	current_drag_zone = null
	
	# Automatically increment global z-order so this item pops to the very front
	global_z_counter += 1
	z_index = global_z_counter
	original_z_index = z_index

func _stop_drag() -> void:
	is_dragging = false
	
	# Instantly catch up to the mouse to eliminate lerp lag on release
	global_position = get_global_mouse_position() + drag_offset
	
	# 1. First, check if dropped over a PostalGrid
	if postal_grid != null and postal_grid.has_method("try_place_package"):
		var placed_successfully = postal_grid.try_place_package(self)
		if placed_successfully:
			last_valid_position = global_position
			return

	# 2. If not on a grid (or placement failed), check standard Area2D Drag Zones
	if _get_drag_zone_at(global_position) == null:
		_clamp_to_boundary_smoothly()
	else:
		_attach_to_current_zone()

## Smoothly animates back to the last position where all corners fit
func _clamp_to_boundary_smoothly() -> void:
	if return_tween and return_tween.is_running():
		return_tween.kill()

	return_tween = create_tween()
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "global_position", last_valid_position, return_duration)
	return_tween.tween_callback(_attach_to_current_zone)

func _attach_to_current_zone() -> void:
	current_drag_zone = _get_drag_zone_at(global_position)
	if current_drag_zone:
		local_zone_offset = current_drag_zone.to_local(global_position)

## Returns all visible active Sprite2D nodes (self + children)
func _get_active_sprites() -> Array[Sprite2D]:
	var active_sprites: Array[Sprite2D] = []
	
	var self_obj: Object = self
	if self_obj is Sprite2D and visible and self_obj.texture != null:
		active_sprites.append(self_obj as Sprite2D)
		
	for child in get_children():
		if child is Sprite2D and child.visible and child.texture != null:
			active_sprites.append(child)
			
	return active_sprites

## Combines all active Sprite2D bounding boxes into a single local Rect2
func _get_combined_rect() -> Rect2:
	var sprites = _get_active_sprites()
	if sprites.is_empty():
		return Rect2(Vector2(0, 0), Vector2(32, 32))
		
	var combined_rect = Rect2()
	var has_first_rect = false
	
	for sprite in sprites:
		var local_r = sprite.get_rect()
		var xform = Transform2D.IDENTITY if sprite == self else sprite.transform
		
		var p1 = xform * local_r.position
		var p2 = xform * Vector2(local_r.end.x, local_r.position.y)
		var p3 = xform * Vector2(local_r.position.x, local_r.end.y)
		var p4 = xform * local_r.end
		
		if not has_first_rect:
			combined_rect = Rect2(p1, Vector2.ZERO)
			has_first_rect = true
			
		combined_rect = combined_rect.expand(p1)
		combined_rect = combined_rect.expand(p2)
		combined_rect = combined_rect.expand(p3)
		combined_rect = combined_rect.expand(p4)
		
	return combined_rect

func _get_corners_at_position(pos: Vector2) -> Array[Vector2]:
	var r = _get_combined_rect()
	var xform = Transform2D(global_transform.x, global_transform.y, pos)
	
	return [
		xform * r.position,
		xform * Vector2(r.end.x, r.position.y),
		xform * Vector2(r.position.x, r.end.y),
		xform * r.end
	]

func _is_mouse_over() -> bool:
	var local_mouse = get_local_mouse_position()
	return _get_combined_rect().has_point(local_mouse)

func _get_drag_zone_at(pos: Vector2) -> Area2D:
	var corners = _get_corners_at_position(pos)
	var candidate_zones = _get_all_drag_zones_at_point(corners[0])
	
	for zone in candidate_zones:
		var fits_completely = true
		for i in range(1, corners.size()):
			if not _is_point_in_zone(corners[i], zone):
				fits_completely = false
				break
		if fits_completely:
			return zone
			
	return null

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

func set_locked(locked: bool) -> void:
	is_draggable = !locked

func toggle_lock() -> void:
	is_draggable = !is_draggable

func _update_lock_visuals() -> void:
	if dim_when_locked:
		modulate = Color(1, 1, 1, 1) if is_draggable else Color(0.6, 0.6, 0.6, 0.8)
