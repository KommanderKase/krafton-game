extends Node

# =============================================================================
# GAME STATE
# =============================================================================

# Day tracking
var current_day: int = 1
var current_phase: String = "morning"  # morning, day, evening, night

# Character affinities — maps character ID to affinity score (0-100)
var affinities: Dictionary = {
	"postman": 50,
}

# Letters the player has bagged to take home
var bagged_letters: Array = []

# Letters available today — loaded each morning from the day manifest
var todays_letters: Array = []

# Cover integrity — starts at 100, erodes over time (for main narrative)
var cover_integrity: int = 100

# Postman compromise level — affects reliability of his briefings
var postman_compromise: int = 0

# Error tracking (for pink slip condition)
var daily_error_count: int = 0
var cumulative_errors: int = 0
const ERROR_THRESHOLD: int = 5  # pink slip trigger

# Current day's manifest
var current_manifest: DayManifest = null

# Routes and mail classes (used by LetterManager and evening puzzle)
var ROUTES: Dictionary = {
	"local": "Local",
	"interstate": "Interstate",
}

var MAIL_CLASSES: Dictionary = {
	"standard": "Standard",
	"express": "Express",
	"air_mail": "Air Mail",
}

# =============================================================================
# SAVE/LOAD DATA
# =============================================================================

class GameSaveData extends Resource:
	@export var day: int = 1
	@export var affinities: Dictionary = {}
	@export var cover_integrity: int = 100
	@export var postman_compromise: int = 0
	@export var cumulative_errors: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Ensure GameManager persists across scene changes
	if not is_in_group("autoload"):
		add_to_group("autoload")

# =============================================================================
# DAY MANAGEMENT
# =============================================================================

## Loads the manifest for a specific day and populates game state
func load_day(day: int) -> DayManifest:
	current_day = day
	var path = "res://resources/manifests/day_%d.tres" % day
	
	if ResourceLoader.exists(path):
		current_manifest = load(path) as DayManifest
		print("Loaded manifest for day %d" % day)
	else:
		push_warning("No manifest found for day %d. Creating default." % day)
		current_manifest = DayManifest.new()
		current_manifest.day_number = day
	
	# Load letters for this day
	LetterManager.load_days_letters(current_manifest)
	
	return current_manifest

## Transition from current day to the next day
func advance_day() -> void:
	current_day += 1
	current_phase = "morning"
	bagged_letters.clear()
	todays_letters.clear()
	daily_error_count = 0
	print("Advanced to day %d" % current_day)

## Called at end of day to finalize errors and check for pink slip condition
func end_of_day() -> void:
	LetterManager.end_of_day_check()
	cumulative_errors += daily_error_count
	daily_error_count = 0
	print("End of day — cumulative errors: %d / %d" % [cumulative_errors, ERROR_THRESHOLD])

## Checks if player should receive a pink slip (game over condition)
func should_receive_pink_slip() -> bool:
	return cumulative_errors >= ERROR_THRESHOLD

# =============================================================================
# PHASE MANAGEMENT
# =============================================================================

## Sets the current game phase
func set_phase(phase: String) -> void:
	if phase in ["morning", "day", "evening", "night"]:
		current_phase = phase
		print("Phase changed to: %s" % phase)
	else:
		push_error("Invalid phase: %s" % phase)

## Gets the current game phase
func get_phase() -> String:
	return current_phase

# =============================================================================
# AFFINITY SYSTEM
# =============================================================================

## Ensures a character exists in the affinity dictionary with a default score
func register_character(character_id: String, initial_affinity: int = 0) -> void:
	if not character_id in affinities:
		affinities[character_id] = clamp(initial_affinity, 0, 100)
		print("Registered character: %s (affinity: %d)" % [character_id, initial_affinity])

## Modifies a character's affinity score
func modify_affinity(character: String, delta: int) -> void:
	if not character in affinities:
		register_character(character)
	
	var old_score = affinities[character]
	affinities[character] = clamp(affinities[character] + delta, 0, 100)
	var new_tier = get_affinity_tier(character)
	
	print("Affinity change: %s %d → %d (tier: %s)" % [character, old_score, affinities[character], new_tier])

## Gets the affinity score for a character (0-100)
func get_affinity_score(character: String) -> int:
	return affinities.get(character, 0)

## Converts affinity score to a tier name
func get_affinity_tier(character: String) -> String:
	var score = affinities.get(character, 0)
	
	if score < 26:
		return "stranger"
	elif score < 51:
		return "acquaintance"
	elif score < 76:
		return "regular"
	else:
		return "confidant"

## Gets all characters currently tracked
func get_all_characters() -> Array:
	return affinities.keys()

# =============================================================================
# NARRATIVE STATE
# =============================================================================

## Increases cover integrity (player is maintaining their undercover identity)
func increase_cover_integrity(amount: int = 5) -> void:
	cover_integrity = clamp(cover_integrity + amount, 0, 100)
	print("Cover integrity: %d%%" % cover_integrity)

## Decreases cover integrity (player is suspected)
func decrease_cover_integrity(amount: int = 5) -> void:
	cover_integrity = clamp(cover_integrity - amount, 0, 100)
	print("Cover integrity: %d%% (COMPROMISED!)" % cover_integrity)
	
	if cover_integrity <= 0:
		print("COVER BLOWN!")

## Increases postman compromise (postman suspects player)
func compromise_postman(amount: int = 1) -> void:
	postman_compromise = clamp(postman_compromise + amount, 0, 10)
	print("Postman compromise: %d/10" % postman_compromise)

# =============================================================================
# SAVE/LOAD
# =============================================================================

## Creates a saveable snapshot of game state
func create_save_data() -> GameSaveData:
	var save = GameSaveData.new()
	save.day = current_day
	save.affinities = affinities.duplicate()
	save.cover_integrity = cover_integrity
	save.postman_compromise = postman_compromise
	save.cumulative_errors = cumulative_errors
	return save

## Restores game state from saved data
func load_save_data(save: GameSaveData) -> void:
	current_day = save.day
	affinities = save.affinities.duplicate()
	cover_integrity = save.cover_integrity
	postman_compromise = save.postman_compromise
	cumulative_errors = save.cumulative_errors
	print("Loaded save data for day %d" % current_day)

## Saves game to a .tres resource file
func save_game(slot: int = 1) -> bool:
	var save_data = create_save_data()
	var save_path = "user://game_save_slot_%d.tres" % slot
	
	var result = ResourceSaver.save(save_data, save_path)
	if result == OK:
		print("Game saved to slot %d" % slot)
		return true
	else:
		push_error("Failed to save game: error code %d" % result)
		return false

## Loads game from a .tres resource file
func load_game(slot: int = 1) -> bool:
	var save_path = "user://game_save_slot_%d.tres" % slot
	
	if ResourceLoader.exists(save_path):
		var save_data = load(save_path) as GameSaveData
		if save_data:
			load_save_data(save_data)
			return true
	
	push_warning("No save file found in slot %d" % slot)
	return false

## Checks if a save file exists
func save_exists(slot: int = 1) -> bool:
	return ResourceLoader.exists("user://game_save_slot_%d.tres" % slot)

# =============================================================================
# UTILITY
# =============================================================================

## Resets the entire game to initial state
func reset_game() -> void:
	current_day = 1
	current_phase = "morning"
	affinities.clear()
	affinities["postman"] = 50
	bagged_letters.clear()
	todays_letters.clear()
	cover_integrity = 100
	postman_compromise = 0
	daily_error_count = 0
	cumulative_errors = 0
	current_manifest = null
	print("Game reset to initial state")

## Gets a debug summary of current game state
func get_state_summary() -> String:
	var summary = ""
	summary += "=== GAME STATE ===\n"
	summary += "Day: %d | Phase: %s\n" % [current_day, current_phase]
	summary += "Cover Integrity: %d%% | Postman Compromise: %d/10\n" % [cover_integrity, postman_compromise]
	summary += "Errors: %d daily / %d cumulative\n" % [daily_error_count, cumulative_errors]
	summary += "\n=== AFFINITIES ===\n"
	
	for character in affinities.keys():
		var score = affinities[character]
		var tier = get_affinity_tier(character)
		summary += "%s: %d (%s)\n" % [character, score, tier]
	
	return summary
