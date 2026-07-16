extends Node2D

var ot := Vector2.ZERO
var mouseEnteredSDFDF := false
var is_stamped: bool = false
var move_count: int = 0
var last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	$Area2D.mouse_entered.connect(onMouseEntersdioafasdjf)
	$Area2D.mouse_exited.connect(onMosueExit)
	last_position = global_position

func onMouseEntersdioafasdjf() -> void:
	mouseEnteredSDFDF = true

func onMosueExit() -> void:
	mouseEnteredSDFDF = false

func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("rightClick") and mouseEnteredSDFDF:
		if not is_stamped:
			print("right click got")
			spawnStamp()

	if Input.is_action_just_pressed("leftClick"):
		ot = global_position - get_global_mouse_position()

	if Input.is_action_pressed("leftClick") and mouseEnteredSDFDF:
		global_position = get_global_mouse_position() + ot

func _process(delta: float) -> void:
	if global_position != last_position:
		move_count += 1
		last_position = global_position
		if move_count == 30:
			print("Item moved, Variable updated.")
			update_dialogic()


func update_dialogic() -> void:
	Dialogic.VAR.set_variable("letter_moved", 2)
	

func spawnStamp() -> void:
	var stamp := preload("res://stamp.tscn").instantiate()
	add_child(stamp)
	stamp.global_position = get_global_mouse_position()
	is_stamped = true

func update_dialogicstamp() -> void:
	if is_stamped:
		print("stamped")
		Dialogic.VAR.set_variable("letter_stamped", 2)
