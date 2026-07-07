extends CanvasLayer

var dialogue_res
var dialogue_line

@onready var speaker = $bg/mc/vb/Speaker
@onready var dialogue_bg = $bg
@onready var dialogue_text = $bg/mc/vb/Text
@onready var option_list = $Options_list
@onready var option_button = $option_button

var awaiting_selection = false
var total_characters = 0
var typing_dialogue = false
var characters_drawn = 0
var Y_scale = 0
@export var DRAW_SPEED = 40

func _ready():
	DialogueManager.dialogue_ended.connect(end_dialogue)

func start_dialogue(dialogue, start_point):
	dialogue_res = dialogue
	dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue)
	update_dialog_window()

func get_next_dialogue(next_id):
	dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_res,next_id)
	update_dialog_window()

func update_dialog_window():
	Y_scale = 0
	if dialogue_line.is_empty():
		return
	speaker.text = dialogue_line.character
	dialogue_text.text = dialogue_line.text
	Y_scale += speaker.get_content_height()
	Y_scale += dialogue_text.get_content_height()
	clear_options()
	set_options()
	total_characters = dialogue_text.get_total_character_count()
	dialogue_text.visible_characters = 0
	characters_drawn = 0
	typing_dialogue = true
	


func end_dialogue():
	queue_free()


func set_options():
	if dialogue_line.responses.size() > 0:
		awaiting_selection = true
	else: 
		awaiting_selection = false
	var options = dialogue_line.responses
	for i in options.size():
		var opt = option_ref_button.duplicate()
		option_list.add_child(opt)
		opt.show()
		opt.text = options[i].text
		set_response_action(opt, options[i].next_id)
		if i == 0:
			opt.grab_focus()
	Y_scale += option_list.size.y
	dialogue_bg.size.y = Y_scale

func clear_options():
	for child in option_list.get_children():
		child.queue_free()

func set_response_action(option_button, next_id):
	option_button.pressed.connect(get_next_dialogue.bind(next_id))


#UNFINISHED CODE!!!!!!!!!!!
