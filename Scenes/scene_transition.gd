extends CanvasLayer

@onready var texture_rect: TextureRect = $GradientImage

func _ready() -> void:
	texture_rect.visible = false

func transition_to_scene(target_scene_path: String) -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	texture_rect.visible = true
	
	# Calculate the TRUE actual width of your TextureRect (accounting for scale)
	var texture_width: float = texture_rect.size.x * texture_rect.scale.x
	var texture_height: float = texture_rect.size.y * texture_rect.scale.y
	
	# Target X position when centered over the screen
	var center_x: float = (screen_size.x - texture_width) / 2.0

	# 1. Start completely off-screen right
	texture_rect.position = Vector2(screen_size.x, (screen_size.y - texture_height) / 2.0)

	# 2. Slide from right to center
	var tween_in = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_in.tween_property(texture_rect, "position:x", center_x, 0.4)
	await tween_in.finished

	# 3. Change the scene while covered, then wait for 1 second
	get_tree().change_scene_to_file(target_scene_path)
	await get_tree().create_timer(1.0).timeout

	# 4. Slide completely off-screen left (moves entire width past 0)
	var tween_out = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween_out.tween_property(texture_rect, "position:x", -texture_width, 0.4)
	await tween_out.finished

	# Hide and reset position back off-screen right
	texture_rect.visible = false
	texture_rect.position.x = screen_size.x
