extends Node2D

@export var stamper_type: String = "RURAL ROUTE" 
@export var stamper_color: Color = Color.WHITE

@onready var sprite := $Sprite2D
@onready var area := $Area2D

var is_held: bool = false
var home_position: Vector2 = Vector2.ZERO
var mouse_inside: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	home_position = global_position
	area.mouse_entered.connect(func(): mouse_inside = true)
	area.mouse_exited.connect(func(): mouse_inside = false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and mouse_inside and not is_held:
			is_held = true
			drag_offset = global_position - get_global_mouse_position()
		elif not event.pressed and is_held:
			is_held = false
			_on_released()

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset

func _on_released() -> void:
	# Check if released over a letter
	var letters = get_tree().get_nodes_in_group("letters")
	for letter in letters:
		if letter.mouse_inside:
			letter.receive_postmark(stamper_type, stamper_color)
			break
	# Always return home
	global_position = home_position
