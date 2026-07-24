## Base class for draggable postal stampers
## Handles drag-and-drop application of postmarks to letters
class_name PostalStamper
extends Node2D

## Type of postmark this stamper applies (e.g., "RURAL ROUTE", "OUT OF STATE", "REJECTED")
@export var stamper_type: String = "STANDARD"

## Color associated with this stamper's mark
@export var stamper_color: Color = Color.WHITE

## Mail class this stamper represents (only for EXPRESS, RURAL stampers)
@export var mail_class: String = "standard"  # "standard", "express", "rural"

@onready var sprite := $Sprite2D
@onready var area := $Area2D

var is_held: bool = false
var home_position: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var letter_under_cursor: LetterSprite = null

func _ready() -> void:
	home_position = global_position
	area.mouse_entered.connect(_on_stamper_hover_enter)
	area.mouse_exited.connect(_on_stamper_hover_exit)

func _on_stamper_hover_enter() -> void:
	pass  # Can add visual feedback here

func _on_stamper_hover_exit() -> void:
	letter_under_cursor = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and area.get_overlapping_areas().size() > 0 and not is_held:
			is_held = true
			drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		elif not event.pressed and is_held:
			is_held = false
			_on_released()

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset
		_check_letter_under_cursor()

func _check_letter_under_cursor() -> void:
	var letters = get_tree().get_nodes_in_group("letters")
	letter_under_cursor = null
	
	for letter in letters:
		if letter is LetterSprite and _is_over_letter(letter):
			letter_under_cursor = letter
			break

func _is_over_letter(letter: LetterSprite) -> bool:
	if letter.texture == null:
		return false
	
	var distance = global_position.distance_to(letter.global_position)
	var letter_radius = (letter.texture.get_size() * letter.scale).length() / 2.0
	
	return distance < letter_radius + 50.0  # 50px buffer for easier targeting

func _on_released() -> void:
	if letter_under_cursor:
		_apply_postmark_to_letter(letter_under_cursor)
	
	global_position = home_position

## Apply this stamper's postmark to a letter and track it
func _apply_postmark_to_letter(letter: LetterSprite) -> void:
	if letter.letter_data == null:
		return
	
	# Convert stamper type to route category
	var route = _get_route_from_stamper()
	
	print("Stamper '%s' applied to letter '%s' (route: %s, class: %s)" % [
		stamper_type, letter.letter_data.letter_id, route, mail_class
	])
	
	# Record postmark in LetterManager
	LetterManager.postmark_letter(letter.letter_data, route, mail_class)
	
	# Visual feedback
	letter.highlight_postmark_applied()

## Determine postal route from stamper type
func _get_route_from_stamper() -> String:
	var lower_type = stamper_type.to_lower()
	
	if "rural" in lower_type or "local" in lower_type:
		return "local"
	elif "out" in lower_type or "state" in lower_type or "interstate" in lower_type:
		return "interstate"
	elif "rejected" in lower_type:
		return "rejected"
	else:
		return "local"  # Default
