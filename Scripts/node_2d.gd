extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var label := $Sprite2D/Label
@onready var postmark_sprite := $postmarksocket/Sprite2D
@onready var stamp_sprite := $stampsocket/Sprite2D

var letter_data: LetterResource = null
var is_held: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var boundary_rect: Rect2
var is_postmarked: bool = false
var is_stamped: bool = false
var mouse_inside: bool = false

func _ready() -> void:
	add_to_group("letters")
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(func(): mouse_inside = true)
	area.mouse_exited.connect(func(): mouse_inside = false)
	postmark_sprite.scale = Vector2(0.3, 0.3)
	postmark_sprite.hide()
	stamp_sprite.hide()

func setup(resource: LetterResource, target_boundary: Rect2) -> void:
	letter_data = resource
	boundary_rect = target_boundary
	
	label.text = "%s\n%s\n%s, %s" % [
		resource.recipient_name,
		resource.recipient_address,
		resource.town,
		resource.state
	]
	
	if resource.arrives_with_stamp:
		stamp_sprite.show()
		stamp_sprite.modulate = GameManager.MAIL_CLASS_COLORS[resource.mail_class]
		is_stamped = true

func receive_stamp(mail_class: String) -> void:
	if is_stamped:
		return
	is_stamped = true
	stamp_sprite.show()
	stamp_sprite.modulate = GameManager.MAIL_CLASS_COLORS[mail_class]
	if letter_data:
		letter_data.stamp_is_correct = (mail_class == letter_data.mail_class)

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

func _check_postmark_correct(type: String) -> bool:
	if not letter_data:
		return false
	match letter_data.route:
		"RFD 1", "RFD 2", "RFD 3", "LOCAL", "PO BOX", "GENERAL DELIVERY":
			return type == "RURAL ROUTE"
		_:
			return type == "OUT OF STATE"

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_held:
			is_held = true
			drag_offset = global_position - get_global_mouse_position()
			get_parent().move_child(self, -1)
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_held:
			is_held = false
			_on_dropped()

func _process(_delta: float) -> void:
	if is_held:
		global_position = get_global_mouse_position() + drag_offset

func _on_dropped() -> void:
	_constrain_to_boundary()
	_check_drop_location()

func _constrain_to_boundary() -> void:
	if boundary_rect == Rect2():
		return
	global_position.x = clamp(global_position.x, boundary_rect.position.x, boundary_rect.end.x)
	global_position.y = clamp(global_position.y, boundary_rect.position.y, boundary_rect.end.y)

func _check_drop_location() -> void:
	var slots = get_tree().get_nodes_in_group("pigeonholes")
	for slot in slots:
		if slot.get_slot_rect().has_point(global_position):
			slot.accept_letter(self)
			return
	var bags = get_tree().get_nodes_in_group("bag")
	for bag in bags:
		if bag.get_bag_rect().has_point(global_position):
			bag.accept_letter(self)
			return
