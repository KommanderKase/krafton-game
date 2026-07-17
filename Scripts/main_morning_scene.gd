extends Node2D

@onready var _animator = $AnimationPlayer
@onready var _letter = $letters

func _ready():
	_letter.hide()
	Dialogic.signal_event.connect(DialogicSignal)
	Dialogic.start("timeline")
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	var color_rect = ColorRect.new()
	color_rect.anchor_left = 0
	color_rect.anchor_top = 0
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = 1
	color_rect.color = Color(0.0, 0.0, 0.0, 0.38) 

	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://your_shader.gdshader")
	color_rect.material = shader_material

	canvas_layer.add_child(color_rect)

func DialogicSignal(argument:String):
	if argument == "letter_spawn":
		_animator.active = true
		_letter.visible = true
		_animator.play("letter_give")
