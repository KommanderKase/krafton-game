extends CanvasLayer

signal screen_covered
signal transition_finished

@export var duration: float = 0.5
@export var debug_mode: bool = true

@onready var gradient_rect = $GradientImage
@onready var debug_button = $"../TransitionDebugButton"

var is_covered: bool = false

func _ready():
	# Make sure we wait until the node is fully in the scene tree
	if not is_inside_tree():
		await tree_entered
		
	setup_rect()
	
	# Start at the very left (off-screen)
	gradient_rect.position.x = -get_screen_size().x
	
	# Handle the debug button
	debug_button.visible = debug_mode
	if not debug_button.pressed.is_connected(play_transition):
		debug_button.pressed.connect(play_transition)

func get_screen_size() -> Vector2:
	# If in tree, get actual viewport size; otherwise fallback to Project Settings size
	if is_inside_tree() and get_viewport():
		return get_viewport().get_visible_rect().size
	
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)

func setup_rect():
	var screen_size = get_screen_size()
	gradient_rect.size = screen_size

func play_transition():
	setup_rect()
	var screen_width = get_screen_size().x
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	if not is_covered:
		# PHASE 1: Move Left to Center
		gradient_rect.position.x = -screen_width
		tween.tween_property(gradient_rect, "position:x", 0.0, duration)
		
		tween.finished.connect(func(): screen_covered.emit())
		is_covered = true
		
	else:
		# PHASE 2: Move Center to Right
		tween.tween_property(gradient_rect, "position:x", screen_width, duration)
		
		tween.finished.connect(func(): 
			gradient_rect.position.x = -screen_width
			transition_finished.emit()
		)
		is_covered = false
