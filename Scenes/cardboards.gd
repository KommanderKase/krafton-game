extends Node2D

enum SlideDirection {
	HORIZONTAL_X,
	VERTICAL_Y
}

@export_group("Slide Mechanics")
## Direction the panels slide along
@export var slide_direction: SlideDirection = SlideDirection.VERTICAL_Y
## If true, only 1 panel can be open at a time (opening a new one closes the active one)
@export var single_active_focus: bool = true

@export_group("Drag Limits (Relative to start position)")
## Minimum relative offset allowed during drag (usually 0.0 for starting position)
@export var min_offset: float = 0.0
## Maximum relative offset allowed during drag (distance and direction)
@export var max_offset: float = -650.0

@export_group("Animation & Snapping")
## Duration of the snap-to-place animation after releasing drag
@export var snap_duration: float = 0.25
## Percentage of total drag distance required to snap OPEN (e.g. 0.3 = 30% drag to open)
@export_range(0.0, 1.0, 0.05) var snap_threshold_percentage: float = 0.5

# State tracking
var panel_data: Dictionary = {}
var currently_open_panel: Node2D = null
var active_dragging_panel: Node2D = null
var drag_start_mouse_pos: float = 0.0
var drag_start_panel_pos: float = 0.0

func _ready() -> void:
	for child in get_children():
		if child is Node2D:
			_setup_panel(child)

func _setup_panel(panel: Node2D) -> void:
	var handle: Area2D = panel.find_child("Handle", true, false) as Area2D
	
	if handle:
		var base_pos: float = panel.position.x if slide_direction == SlideDirection.HORIZONTAL_X else panel.position.y
		var min_pos: float = base_pos + min_offset
		var max_pos: float = base_pos + max_offset
		
		# Ensure bounds_min is less than bounds_max regardless of negative/positive offsets
		var bounds_min: float = min(min_pos, max_pos)
		var bounds_max: float = max(min_pos, max_pos)
		
		panel_data[panel] = {
			"closed_pos": base_pos,
			"open_pos": base_pos + max_offset,
			"min_pos": bounds_min,
			"max_pos": bounds_max,
			"tween": null
		}
		
		# Connect handle input event
		handle.input_event.connect(
			func(_viewport, event, _shape_idx):
				_on_handle_input(panel, event)
		)
	else:
		push_warning("No 'Handle' Area2D found inside " + panel.name)

func _on_handle_input(panel: Node2D, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and active_dragging_panel == null:
			_start_drag(panel)

func _unhandled_input(event: InputEvent) -> void:
	# Release drag when mouse button is released anywhere on screen
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if active_dragging_panel != null:
			_end_drag()

func _process(_delta: float) -> void:
	if active_dragging_panel != null:
		var data: Dictionary = panel_data[active_dragging_panel]
		var current_mouse_pos: float = _get_mouse_axis_position()
		var delta_pos: float = current_mouse_pos - drag_start_mouse_pos
		
		var target_pos: float = drag_start_panel_pos + delta_pos
		var clamped_pos: float = clamp(target_pos, data["min_pos"], data["max_pos"])
		
		_set_panel_axis_position(active_dragging_panel, clamped_pos)

func _start_drag(panel: Node2D) -> void:
	active_dragging_panel = panel
	drag_start_mouse_pos = _get_mouse_axis_position()
	drag_start_panel_pos = _get_panel_axis_position(panel)
	
	var data: Dictionary = panel_data[panel]
	
	# Kill ongoing animation for this panel
	if data["tween"] and data["tween"].is_running():
		data["tween"].kill()
		
	# Handle single focus behavior if enabled
	if single_active_focus and currently_open_panel != null and currently_open_panel != panel:
		_snap_panel(currently_open_panel, false)
		currently_open_panel = null

func _end_drag() -> void:
	var panel: Node2D = active_dragging_panel
	active_dragging_panel = null
	
	var data: Dictionary = panel_data[panel]
	var current_pos: float = _get_panel_axis_position(panel)
	
	# Calculate custom threshold point based on percentage along drag path
	var threshold_pos: float = lerp(data["closed_pos"], data["open_pos"], snap_threshold_percentage)
	
	# Check if current position passed the threshold point
	var should_open: bool
	if max_offset > 0:
		should_open = current_pos >= threshold_pos
	else:
		should_open = current_pos <= threshold_pos
	
	_snap_panel(panel, should_open)
	
	if single_active_focus:
		currently_open_panel = panel if should_open else null

func _snap_panel(panel: Node2D, open: bool) -> void:
	var data: Dictionary = panel_data[panel]
	var target_pos: float = data["open_pos"] if open else data["closed_pos"]
	
	if data["tween"] and data["tween"].is_running():
		data["tween"].kill()
		
	var property_path: String = "position:x" if slide_direction == SlideDirection.HORIZONTAL_X else "position:y"
	
	# Smoothly snap to target open/closed position
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, property_path, target_pos, snap_duration)
	data["tween"] = tween

# Helper functions to abstract axis reading/writing
func _get_mouse_axis_position() -> float:
	var global_mouse: Vector2 = get_global_mouse_position()
	return global_mouse.x if slide_direction == SlideDirection.HORIZONTAL_X else global_mouse.y

func _get_panel_axis_position(panel: Node2D) -> float:
	return panel.position.x if slide_direction == SlideDirection.HORIZONTAL_X else panel.position.y

func _set_panel_axis_position(panel: Node2D, value: float) -> void:
	if slide_direction == SlideDirection.HORIZONTAL_X:
		panel.position.x = value
	else:
		panel.position.y = value
