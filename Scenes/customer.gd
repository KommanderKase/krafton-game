class_name Customer
extends Sprite2D

signal fade_out_completed
signal fade_in_completed

@export_group("Target Sizing")
## Enable automatic scaling so textures of different pixel sizes appear uniformly sized
@export var auto_scale_character: bool = true
## Target height in world pixels that all character sprites will scale to match
@export var target_height: float = 325.0

@export_group("Breathing Animation")
## How fast the character breathes up and down
@export var breathing_speed: float = 1.0
## How many pixels up and down the sprite moves
@export var breathing_height: float = 6.0
@export var is_breathing: bool = false

@export_group("Entrance & Exit Animations")
## How far to the left (in pixels) the customer starts/leaves
@export var slide_distance: float = 300.0
## How many degrees the sprite tilts while walking (Positive = Right, Negative = Left)
@export var tilt_angle: float = 5.0
## Total duration for the slide & fade transition
@export var transition_duration: float = 1

var time_elapsed: float = 0.0
var active_tween: Tween = null

func _ready() -> void:
	# Start completely transparent, reset offset & rotation
	modulate.a = 0.0
	offset = Vector2.ZERO
	rotation_degrees = 0.0
	is_breathing = false
	update_character_scale()

func _process(delta: float) -> void:
	if not is_breathing:
		return
		
	time_elapsed += delta
	# Smooth sine wave breathing loop on the Y offset
	offset.y = sin(time_elapsed * breathing_speed) * breathing_height

## Calculates and applies node scale to maintain consistent visual size and aspect ratio
func update_character_scale() -> void:
	if not auto_scale_character or texture == null:
		return
		
	var tex_size = texture.get_size()
	if tex_size.y <= 0:
		return
		
	# Scale factor based on target height while strictly maintaining aspect ratio
	var scale_factor = target_height / tex_size.y
	scale = Vector2(scale_factor, scale_factor)

func fade_in() -> void:
	is_breathing = false
	time_elapsed = 0.0
	
	# Recalculate scale whenever a new texture is loaded
	update_character_scale()
	
	if active_tween and active_tween.is_running():
		active_tween.kill()

	# Set initial entrance state (Left offset, tilted right, transparent)
	offset.x = -slide_distance
	offset.y = 0.0
	rotation_degrees = tilt_angle
	modulate.a = 0.0
	
	# Create parallel tween to animate position, tilt, and transparency simultaneously
	active_tween = create_tween().set_parallel(true)
	active_tween.set_trans(Tween.TRANS_CUBIC)
	active_tween.set_ease(Tween.EASE_OUT)
	
	active_tween.tween_property(self, "offset:x", 0.0, transition_duration)
	active_tween.tween_property(self, "rotation_degrees", 0.0, transition_duration)
	active_tween.tween_property(self, "modulate:a", 1.0, transition_duration)
	
	# Start breathing once arrival animation finishes
	active_tween.chain().tween_callback(func():
		is_breathing = true
		fade_in_completed.emit()
	)

func fade_out() -> void:
	is_breathing = false
	
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween().set_parallel(true)
	active_tween.set_trans(Tween.TRANS_CUBIC)
	active_tween.set_ease(Tween.EASE_IN)
	
	# Move left, tilt to the left (-tilt_angle), and fade out
	active_tween.tween_property(self, "offset:x", -slide_distance, transition_duration)
	active_tween.tween_property(self, "rotation_degrees", -tilt_angle, transition_duration)
	active_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
	
	# Reset transform properties upon completing exit animation
	active_tween.chain().tween_callback(func():
		offset = Vector2.ZERO
		rotation_degrees = 0.0
		fade_out_completed.emit()
	)
