# res://Scripts/day_scene.gd
extends Node2D

# Queue of characters who will visit today, loaded from manifest
var customer_queue: Array = []
var current_customer_index: int = 0
var is_conversation_active: bool = false

func _ready():
	GameManager.set_phase("day")
	
	# Load today's available characters from the manifest
	if GameManager.current_manifest:
		customer_queue = GameManager.current_manifest.characters_available.duplicate()
	
	# Connect Dialogic signals
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
	# Spawn first customer
	_next_customer()

func _next_customer():
	if current_customer_index >= customer_queue.size():
		# All customers done for the day — wait for player to advance to evening
		_all_customers_done()
		return
	
	var character_id = customer_queue[current_customer_index]
	var tier = GameManager.get_affinity_tier(character_id)
	
	# Build timeline name from character and affinity tier
	# e.g. "dorothy_acquaintance" or "sheriff_stranger"
	var timeline_name = "%s_%s" % [character_id, tier]
	
	is_conversation_active = true
	Dialogic.start(timeline_name)

func _on_dialogic_signal(argument: String):
	match argument:
		"affinity_up_small":
			_modify_current_customer_affinity(10)
		"affinity_up_large":
			_modify_current_customer_affinity(20)
		"affinity_down_small":
			_modify_current_customer_affinity(-10)
		"affinity_down_large":
			_modify_current_customer_affinity(-20)
		"phase_evening":
			_transition_to_evening()

func _on_timeline_ended():
	if is_conversation_active:
		is_conversation_active = false
		current_customer_index += 1
		# Small delay between customers so it doesn't feel instant
		await get_tree().create_timer(1.5).timeout
		_next_customer()

func _modify_current_customer_affinity(delta: int):
	if current_customer_index < customer_queue.size():
		var character_id = customer_queue[current_customer_index]
		GameManager.modify_affinity(character_id, delta)

func _all_customers_done():
	pass

func _transition_to_evening():
	GameManager.set_phase("evening")
	get_tree().change_scene_to_file("res://Scenes/evening_scene.tscn")
