# DragManager.gd
extends Node2D

var dragged_item: Draggable = null
var drag_offset: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		_try_grab_item()
	elif event.is_action_released("click") and dragged_item:
		_drop_item()

func _try_grab_item() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true # Detect Area2D nodes
	
	var results = space_state.intersect_point(query)
	if results.is_empty():
		return
		
	# Find the item with the highest Z-index (top-most visual item)
	var top_item: Draggable = null
	for result in results:
		var collider = result.collider
		if collider is Draggable:
			if top_item == null or collider.z_index > top_item.z_index:
				top_item = collider
				
	if top_item:
		dragged_item = top_item
		# Offset ensures the package doesn't awkwardly snap its center to the cursor
		drag_offset = dragged_item.global_position - get_global_mouse_position()
		dragged_item.on_grabbed()

func _drop_item() -> void:
	dragged_item.on_dropped()
	dragged_item = null

func _process(delta: float) -> void:
	if dragged_item:
		var target_pos = get_global_mouse_position() + drag_offset
		# Smooth interpolation (higher multiplier = snappier, lower = heavier feel)
		dragged_item.global_position = dragged_item.global_position.lerp(target_pos, 25.0 * delta)
