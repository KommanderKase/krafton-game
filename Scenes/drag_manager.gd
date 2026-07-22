class_name DragManager
extends Node

# Simple static reference so objects in this scene can find their local manager
static var instance: DragManager

var dragged_object: DraggableObject = null
var active_zone: DragZone = null
var hovered_zones: Array[DragZone] = []

func _enter_tree() -> void:
	instance = self

func _process(_delta: float) -> void:
	if not dragged_object:
		return
		
	# 1. Update the active zone if the mouse enters a new valid zone/slot
	var target_zone: DragZone = _get_top_hovered_zone()
	if target_zone:
		active_zone = target_zone
		
	# 2. Ask the active zone for a valid clamped/snapped position
	if active_zone:
		var mouse_pos: Vector2 = dragged_object.get_global_mouse_position()
		var valid_pos: Vector2 = active_zone.get_valid_position(mouse_pos, dragged_object)
		dragged_object.global_position = valid_pos

func _input(event: InputEvent) -> void:
	# Global left-click release check ensures drop triggers even if cursor leaves the object
	if dragged_object and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_drag()

func start_drag(object: DraggableObject) -> void:
	dragged_object = object
	active_zone = object.current_zone
	
	# Elevate z-index so it renders above other table items while moving
	dragged_object.z_index = 100
	dragged_object.on_drag_start()

func end_drag() -> void:
	if not dragged_object:
		return
		
	# Finalize drop inside the last valid zone we were in
	if active_zone:
		dragged_object.current_zone = active_zone
		var final_pos: Vector2 = active_zone.get_valid_position(dragged_object.global_position, dragged_object)
		dragged_object.global_position = final_pos
		active_zone.on_object_dropped(dragged_object)
			
	dragged_object.z_index = 0
	dragged_object.on_drag_end()
	dragged_object = null

func register_hovered_zone(zone: DragZone) -> void:
	if not hovered_zones.has(zone):
		hovered_zones.append(zone)

func unregister_hovered_zone(zone: DragZone) -> void:
	hovered_zones.erase(zone)

func _get_top_hovered_zone() -> DragZone:
	if hovered_zones.is_empty():
		return null
	# Return the most recently entered zone (top of stack)
	return hovered_zones.back()
