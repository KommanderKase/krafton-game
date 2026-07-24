## Unified Day Scene Controller
## Handles both customer interaction phase and postal sorting phase
extends Node2D

# ==========================================
# CUSTOMER PHASE STATE
# ==========================================

var customer_queue: Array = []
var current_customer_index: int = 0
var is_conversation_active: bool = false

# ==========================================
# POSTAL SORTING PHASE STATE
# ==========================================

var postal_phase_active: bool = false
var current_game_phase: String = "day"  # "day" (customers) or "evening" (postal)

# References to scene nodes
@onready var customer_manager: CustomerManager = $CustomerManager
@onready var postal_grid: PostalGrid = $Cardboards/Cardboard1/BaseTexture/PostalGrid
@onready var next_button: Button = $NextButton
@onready var pigeonhole_local: Area2D = null  # Will be created or found
@onready var pigeonhole_interstate: Area2D = null

func _ready() -> void:
	# Start in customer phase
	GameManager.set_phase("day")
	current_game_phase = "day"
	
	# Load today's available characters from the manifest
	if GameManager.current_manifest:
		customer_queue = GameManager.current_manifest.characters_available.duplicate()
	
	# Connect Dialogic signals for customer dialogue
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
	# Ensure pigeonholes exist
	_ensure_pigeonholes_exist()
	
	# Connect next button to customer manager
	if next_button and customer_manager:
		next_button.pressed.connect(customer_manager._on_next_customer_pressed)
	
	# Spawn first customer
	_next_customer()

# ==========================================
# CUSTOMER PHASE (Dialogue & Affinity)
# ==========================================

func _next_customer() -> void:
	if current_customer_index >= customer_queue.size():
		# All customers done — transition to postal sorting phase
		_all_customers_done()
		return
	
	var character_id = customer_queue[current_customer_index]
	var tier = GameManager.get_affinity_tier(character_id)
	
	# Build timeline name from character and affinity tier
	var timeline_name = "%s_%s" % [character_id, tier]
	
	is_conversation_active = true
	Dialogic.start(timeline_name)

func _on_dialogic_signal(argument: String) -> void:
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
			_transition_to_postal_phase()

func _on_timeline_ended() -> void:
	if is_conversation_active:
		is_conversation_active = false
		current_customer_index += 1
		await get_tree().create_timer(1.5).timeout
		_next_customer()

func _modify_current_customer_affinity(delta: int) -> void:
	if current_customer_index < customer_queue.size():
		var character_id = customer_queue[current_customer_index]
		GameManager.modify_affinity(character_id, delta)

func _all_customers_done() -> void:
	print("All customers have visited. Ready for postal sorting.")
	# Enable postal grid UI, hide or fade out customer area

# ==========================================
# POSTAL SORTING PHASE
# ==========================================

func _transition_to_postal_phase() -> void:
	current_game_phase = "evening"
	GameManager.set_phase("evening")
	
	print("Transitioning to postal sorting phase...")
	
	# Hide customer UI
	if customer_manager:
		customer_manager.visible = false
	
	# Activate postal grid and pigeonholes
	postal_phase_active = true
	_show_postal_ui()

func _show_postal_ui() -> void:
	"""Enable postal sorting interface: show PostalGrid, pigeonholes, sorting UI"""
	
	if postal_grid:
		postal_grid.visible = true
		postal_grid.show_debug_grid = true
	
	if pigeonhole_local:
		pigeonhole_local.visible = true
	if pigeonhole_interstate:
		pigeonhole_interstate.visible = true
	
	# Load today's letters into LetterManager
	if GameManager.current_manifest:
		LetterManager.load_days_letters(GameManager.current_manifest)
	
	# Show "End Day" button to transition to night
	if next_button:
		next_button.text = "END DAY"
		next_button.pressed.disconnect(customer_manager._on_next_customer_pressed)
		next_button.pressed.connect(_on_end_day_pressed)

func _on_end_day_pressed() -> void:
	"""Finalize postal work and transition to night phase"""
	GameManager.end_of_day()
	
	if GameManager.should_receive_pink_slip():
		print("PINK SLIP! Game Over.")
		get_tree().change_scene_to_file("res://Scenes/game_over_scene.tscn")
	else:
		print("Day completed successfully. Moving to night phase.")
		get_tree().change_scene_to_file("res://Scenes/night_scene.tscn")

# ==========================================
# PIGEONHOLE SETUP
# ==========================================

func _ensure_pigeonholes_exist() -> void:
	"""Find or create pigeonhole Area2D nodes for letter routing"""
	
	# Try to find existing pigeonholes in scene
	pigeonhole_local = find_child("PigeonholeLocal", true, false)
	pigeonhole_interstate = find_child("PigeonholeInterstate", true, false)
	
	# If they don't exist, create them programmatically
	if not pigeonhole_local:
		print("Creating PigeonholeLocal Area2D...")
		pigeonhole_local = _create_pigeonhole("PigeonholeLocal", Vector2(200, 750))
		add_child(pigeonhole_local)
	
	if not pigeonhole_interstate:
		print("Creating PigeonholeInterstate Area2D...")
		pigeonhole_interstate = _create_pigeonhole("PigeonholeInterstate", Vector2(700, 750))
		add_child(pigeonhole_interstate)
	
	# Add to group for letter sprite detection
	if pigeonhole_local:
		pigeonhole_local.add_to_group("pigeonholes")
	if pigeonhole_interstate:
		pigeonhole_interstate.add_to_group("pigeonholes")

func _create_pigeonhole(name: String, position: Vector2) -> Area2D:
	"""Create a pigeonhole Area2D with collision shape"""
	var area = Area2D.new()
	area.name = name
	area.position = position
	area.visible = false  # Hidden during customer phase
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(250, 200)
	collision.shape = shape
	area.add_child(collision)
	
	return area
