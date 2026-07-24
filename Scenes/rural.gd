extends Node2D

@export var route_name: String = "RFD 1"

@onready var color_rect: ColorRect = $ColorRect
@onready var route_label: Label = $Label
@onready var drop_area: Area2D = $DropArea

var sorted_items: Array[Node2D] = []
@export var stack_offset: Vector2 = Vector2(0, -12)

func _ready() -> void:
	add_to_group("pigeonholes")
	
	var route_color = GameManager.ROUTES.get(route_name, Color.WHITE)
	color_rect.color = Color(route_color.r, route_color.g, route_color.b, 0.3)
	route_label.text = route_name
	
	drop_area.area_entered.connect(_on_area_entered)

func get_slot_rect() -> Rect2:
	return Rect2(global_position - color_rect.size / 2, color_rect.size)

func _on_area_entered(other_area: Area2D) -> void:
	var item = other_area.get_parent()
	if item.has_method("get_item_type") and not item in sorted_items:
		# Note: If the player is currently dragging the item, 
		# we wait until release (handled by Package._check_pigeonhole_drop_or_constrain())
		pass 

func accept_item(item: Node2D) -> void:
	var item_type = item.get_item_type() if item.has_method("get_item_type") else "UNKNOWN"
	
	if "letter_data" in item:
		LetterManager.sort_letter_to_route(item.letter_data, route_name)
	
	sorted_items.append(item)
	
	# 1. Lock dragging
	if item.has_method("set_is_draggable"):
		item.set_is_draggable(false)
	
	# 2. Swap to the dedicated sideways texture
	if item.has_method("set_sideways_view"):
		item.set_sideways_view(true)
		
	# 3. Stack neatly inside the shelf
	arrange_item_in_slot(item)
	
	print("Sorted ", item_type, " into ", route_name)

func arrange_item_in_slot(item: Node2D) -> void:
	var stack_index = sorted_items.size() - 1
	var target_pos = global_position + (stack_offset * stack_index)
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "global_position", target_pos, 0.2)
