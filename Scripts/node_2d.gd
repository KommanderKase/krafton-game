extends Node2D

@onready var area := $Area2D
@onready var sprite := $Sprite2D
@onready var label := $Label
@onready var postmark_sprite := $postmarksocket/Sprite2D

var letter_data: LetterResource = null
var is_held: bool = false
var mouse_inside: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_postmarked: bool = false

func _ready() -> void:
	add_to_group("letters")
	area.mouse_entered.connect(func(): mouse_inside = true)
	area.mouse_exited.connect(func(): mouse_inside = false)
	postmark_sprite.scale = Vector2(0.3, 0.3)
	postmark_sprite.hide()

func setup(resource: LetterResource) -> void:
	letter_data = resource
	label.text = "%s\n%s\n%s, %s" % [
		resource.recipient_name,
		resource.recipient_address,
		resource.town,
		resource.state
	]

func receive_postmark(type: String, color: Color) -> void:
	if is_postmarked:
		return
	is_postmarked = true
	postmark_sprite.show()
	postmark_sprite.modulate = color
	match type:
		"OUT OF STATE":
			postmark_sprite.texture = load("res://Assets/Images/Background and Objects/out of state mark.png")
		"REJECTED":
			postmark_sprite.texture = load("res://Assets/Images/Background and Objects/REJECTED.png")
		"RURAL ROUTE":
			postmark_sprite.texture = load("res://Assets/Images/Background and Objects/RURAL ROUTE MARK.png")
	if letter_data:
		letter_data.is_postmarked = true
		letter_data.postmark_correct = _check_postmark_correct(type)
		if not letter_data.postmark_correct:
			print("Postal error: wrong postmark on ", letter_data.letter_id)

func _check_postmark_correct(type: String) -> bool:
	if not letter_data:
		return false
	match letter_data.route:
		"RFD 1", "RFD 2", 	"RFD 3", "LOCAL":
			return type == "RURAL ROUTE"
		"PO BOX", "GENERAL DELIVERY":
			return type == "RURAL ROUTE"
		_:
			return type == "OUT OF STATE"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and mouse_inside:
			is_held = true
			drag_offset = global_position - get_global_mouse_position()
		elif not event.pressed:
			is_held = false

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset
