extends Node2D

@onready var _animator = $AnimationPlayer
@onready var _letter = $letters

func _ready():
	_letter.hide()
	Dialogic.signal_event.connect(DialogicSignal)
	Dialogic.start("timeline")

func DialogicSignal(argument:String):
	if argument == "letter_spawn":
		_animator.active = true
		_letter.visible = true
		_animator.play("letter_give")
