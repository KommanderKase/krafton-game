## Letter sprite that wraps a LetterResource and supports drag-and-drop routing
class_name LetterSprite
extends Sprite2D

## Reference to the underlying letter data
var letter_data: LetterResource = null

## Drop zone areas where this letter can be sorted
var target_drop_zones: Array[Area2D] = []

## Track if we're currently being dragged
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

## Last known valid drop zone (for snap-back)
var current_drop_zone: Area2D = null
var home_position: Vector2 = Vector2.ZERO

## Tween for smooth animations
var return_tween: Tween = null

## Visual feedback: highlight when hovering over valid zone
var zone_highlight: Sprite2D = null
var is_over_valid_zone: bool = false

## Original z-index before dragging
var original_z_index: int = 0

func _ready() -> void:
	original_z_index = z_index
	home_position = global_position
	
	# Add to letters group for easy lookup
	add_to_group("letters")
	
	# Create a subtle highlight for when hovering over drop zones
	_setup_highlight()

func setup(letter_resource: LetterResource, drop_zones: Array[Area2D]) -> void:
	letter_data = letter_resource
	target_drop_zones = drop_zones
	
	# You could set texture based on letter metadata here
	# For now, texture is set by evening_scene during instantiation
	print("Letter %s set up with %d drop zones" % [letter_data.letter_id, target_drop_zones.size()])

func _unhandled_input(event: InputEvent) -> void:
	if letter_data == null:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_mouse_over():
			_start_drag()
			get_viewport().set_input_as_handled()
		elif not event.pressed and is_dragging:
			_stop_drag()

func _process(_delta: float) -> void:
	if is_dragging:
		var target_pos = get_global_mouse_position() + drag_offset
		global_position = target_pos
		_check_hover_zones()

func _is_mouse_over() -> bool:
	if texture == null:
		return false
	var local_mouse = get_local_mouse_position()
	return get_rect().has_point(local_mouse)

func _start_drag() -> void:
	if is_dragging:
		return
	
	is_dragging = true
	drag_offset = global_position - get_global_mouse_position()
	z_index = 100
	_hide_highlight()

func _stop_drag() -> void:
	is_dragging = false
	z_index = original_z_index
	
	# Check if we landed in a valid drop zone
	var detected_zone = _get_zone_under_letter()
	
	if detected_zone:
		# Letter landed in a pigeonhole — route it
		_route_letter(detected_zone)
		_snap_to_zone(detected_zone)
	else:
		# Snap back home
		_snap_back_home()

## Check which zone(s) this letter is hovering over
func _check_hover_zones() -> void:
	var detected_zone = _get_zone_under_letter()
	
	if detected_zone and not is_over_valid_zone:
		is_over_valid_zone = true
		_show_highlight()
	elif not detected_zone and is_over_valid_zone:
		is_over_valid_zone = false
		_hide_highlight()

## Detect if letter center is over a drop zone
func _get_zone_under_letter() -> Area2D:
	var letter_center = global_position
	
	for zone in target_drop_zones:
		var zone_rect = zone.get_node("CollisionShape2D").shape.get_rect()
		var zone_global_rect = Rect2(zone.global_position + zone_rect.position, zone_rect.size)
		
		if zone_global_rect.has_point(letter_center):
			return zone
	
	return null

## Route letter to the selected pigeonhole and track errors
func _route_letter(zone: Area2D) -> void:
	if letter_data == null:
		return
	
	# Determine which route this zone represents
	var zone_name = zone.name.to_lower()
	var detected_route = ""
	
	if "local" in zone_name:
		detected_route = "local"
	elif "out_of_state" in zone_name or "outofstate" in zone_name:
		detected_route = "interstate"
	else:
		push_warning("Unknown zone: %s" % zone.name)
		return
	
	print("Letter %s routed to %s (expected: %s)" % [letter_data.letter_id, detected_route, letter_data.route])
	
	# Tell LetterManager to record this routing decision
	LetterManager.sort_letter_to_route(letter_data, detected_route)
	
	current_drop_zone = zone

## Smoothly animate letter into drop zone
func _snap_to_zone(zone: Area2D) -> void:
	if return_tween and return_tween.is_running():
		return_tween.kill()
	
	var zone_center = zone.global_position
	
	return_tween = create_tween()
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "global_position", zone_center, 0.3)
	return_tween.tween_callback(func(): _hide_highlight())

## Snap back to home position if dropped outside zones
func _snap_back_home() -> void:
	if return_tween and return_tween.is_running():
		return_tween.kill()
	
	return_tween = create_tween()
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "global_position", home_position, 0.25)
	return_tween.tween_callback(func(): _hide_highlight())

## Subtle highlight sprite
func _setup_highlight() -> void:
	zone_highlight = Sprite2D.new()
	zone_highlight.texture = texture  # Same as letter
	zone_highlight.modulate = Color(1, 1, 0.5, 0.3)  # Yellow tint, transparent
	zone_highlight.z_index = -1
	add_child(zone_highlight)
	zone_highlight.hide()

func _show_highlight() -> void:
	if zone_highlight:
		zone_highlight.show()

func _hide_highlight() -> void:
	if zone_highlight:
		zone_highlight.hide()

## Called by stampers when they apply a postmark to this letter
func receive_postmark(stamper_type: String, color: Color) -> void:
	if letter_data == null:
		return
	
	# Convert stamper type to route
	var route = ""
	if "RURAL" in stamper_type or "LOCAL" in stamper_type:
		route = "local"
	elif "OUT OF STATE" in stamper_type:
		route = "interstate"
	elif "REJECTED" in stamper_type:
		route = "rejected"
	
	var mail_class = "standard"  # TODO: derive from stamper or letter data
	
	print("Letter %s received postmark: %s / %s" % [letter_data.letter_id, route, mail_class])
	LetterManager.postmark_letter(letter_data, route, mail_class)
