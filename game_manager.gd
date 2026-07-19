extends Node

# Day tracking
var current_day: int = 1
var current_phase: String = "morning"  # morning, day, evening, night

# Character affinities — add characters as you create them
var affinities: Dictionary = {
	"postman": 50,
}

# Letters the player has bagged to take home
var bagged_letters: Array = []

# Letters available today — loaded each morning from the day manifest
var todays_letters: Array = []

# Cover integrity — starts at 100, erodes over time
var cover_integrity: int = 100

# Postman compromise level — affects reliability of his briefings
var postman_compromise: int = 0

func advance_day():
	current_day += 1
	current_phase = "morning"
	bagged_letters.clear()
	todays_letters.clear()
	
var daily_error_count: int = 0
var cumulative_errors: int = 0
const ERROR_THRESHOLD: int = 5  # pink slip trigger

func end_of_day() -> void:
	LetterManager.end_of_day_check()
	cumulative_errors += daily_error_count
	daily_error_count = 0

func should_receive_pink_slip() -> bool:
	return cumulative_errors >= ERROR_THRESHOLD

func set_phase(phase: String):
	current_phase = phase

func modify_affinity(character: String, delta: int):
	if affinities.has(character):
		affinities[character] = clamp(affinities[character] + delta, 0, 100)

func get_affinity_tier(character: String) -> String:
	var score = affinities.get(character, 0)
	if score < 26: return "stranger"
	if score < 51: return "acquaintance"
	if score < 76: return "regular"
	return "confidant"
	

var current_manifest: DayManifest = null

func load_manifest(day: int) -> DayManifest:
	var path = "res://resources/manifests/day_%d.tres" % day
	if ResourceLoader.exists(path):
		current_manifest = load(path)
	else:
		push_warning("No manifest found for day %d" % day)
		current_manifest = DayManifest.new()
	return current_manifest
