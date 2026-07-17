extends Node2D

@onready var _animator = $AnimationPlayer
@onready var _letter = $letters

func _ready():
	_letter.hide()
	Dialogic.signal_event.connect(DialogicSignal)
	Dialogic.start("timeline")
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 0
	add_child(canvas_layer)
	var color_rect = ColorRect.new()
	color_rect.anchor_left = 0
	color_rect.anchor_top = 0
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = 1
	color_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://resources/Shader/main_dithered_shader.gdshader")
	color_rect.material = shader_material
	
	canvas_layer.add_child(color_rect)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		print("Main scene received input: ", event)

func DialogicSignal(argument:String):
	if argument == "letter_spawn":
		_animator.active = true
		_letter.visible = true
		_animator.play("letter_give")
