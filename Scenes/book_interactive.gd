class_name InteractiveBook
extends DraggableSprite # Inherits your entire drag-and-drop system!

@onready var left_dog_ear: Area2D = $LeftDogEar
@onready var right_dog_ear: Area2D = $RightDogEar

var pages: Array[BookPage] = []
var current_page_index: int = 0

func _ready() -> void:
	# Run DraggableSprite's _ready function first
	super._ready()
	
	# Automatically gather all BookPage Sprite2D children
	for child in get_children():
		if child is BookPage:
			pages.append(child)
			
	# Connect dog ear click signals
	left_dog_ear.input_event.connect(_on_left_dog_ear_clicked)
	right_dog_ear.input_event.connect(_on_right_dog_ear_clicked)
	
	# Display the first page
	_update_page_display()

## Intercepts input to ensure dog ears get click priority over book dragging
func _unhandled_input(event: InputEvent) -> void:
	if not is_draggable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# If the click lands on an active dog ear, do not start dragging
		if _is_mouse_over_dog_ear():
			return

	# Otherwise, proceed with normal DraggableSprite behavior
	super._unhandled_input(event)

## Updates visible textures and moves the reusable dog ears to their new offsets
func _update_page_display() -> void:
	if pages.is_empty():
		return
		
	# Toggle page visibilities
	for i in range(pages.size()):
		pages[i].visible = (i == current_page_index)
		
	var active_page: BookPage = pages[current_page_index]
	
	# Update Left Dog Ear
	left_dog_ear.visible = active_page.show_left_dog_ear
	left_dog_ear.position = active_page.left_dog_ear_offset
	left_dog_ear.monitorable = active_page.show_left_dog_ear
	left_dog_ear.monitoring = active_page.show_left_dog_ear
	
	# Update Right Dog Ear
	right_dog_ear.visible = active_page.show_right_dog_ear
	right_dog_ear.position = active_page.right_dog_ear_offset
	right_dog_ear.monitorable = active_page.show_right_dog_ear
	right_dog_ear.monitoring = active_page.show_right_dog_ear

func turn_page(direction: int) -> void:
	var new_index = clampi(current_page_index + direction, 0, pages.size() - 1)
	if new_index != current_page_index:
		current_page_index = new_index
		_update_page_display()

## Handle clicking the Left Dog Ear
func _on_left_dog_ear_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		turn_page(-1)
		get_viewport().set_input_as_handled()

## Handle clicking the Right Dog Ear
func _on_right_dog_ear_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		turn_page(1)
		get_viewport().set_input_as_handled()

## Checks if the mouse cursor is currently over any visible dog ear
func _is_mouse_over_dog_ear() -> bool:
	var global_mouse = get_global_mouse_position()
	
	if left_dog_ear.visible and _is_point_in_area(global_mouse, left_dog_ear):
		return true
	if right_dog_ear.visible and _is_point_in_area(global_mouse, right_dog_ear):
		return true
		
	return false

## Helper physics query to test point intersection with an Area2D
func _is_point_in_area(pos: Vector2, area: Area2D) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_point(query)
	for res in results:
		if res.collider == area:
			return true
	return false
