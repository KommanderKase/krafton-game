extends Node

var incoming_pile: Array[LetterResource] = []
var outgoing_pile: Array[LetterResource] = []
var player_bag: Array[LetterResource] = []
var sorted_letters: Dictionary = {}  # route -> Array[LetterResource]
var postal_errors: Array[Dictionary] = []

func load_days_letters(manifest: DayManifest) -> void:
	incoming_pile.clear()
	outgoing_pile.clear()
	sorted_letters.clear()
	postal_errors.clear()
	
	for route in GameManager.ROUTES.keys():
		sorted_letters[route] = []
	
	for letter_id in manifest.incoming_letter_ids:
		var path = "res://resources/letters/%s.tres" % letter_id
		if ResourceLoader.exists(path):
			var letter = load(path) as LetterResource
			letter.is_incoming = true
			incoming_pile.append(letter)
	
	for letter_id in manifest.outgoing_letter_ids:
		var path = "res://resources/letters/%s.tres" % letter_id
		if ResourceLoader.exists(path):
			var letter = load(path) as LetterResource
			letter.is_incoming = false
			outgoing_pile.append(letter)

func bag_letter(letter: LetterResource) -> void:
	letter.is_bagged = true
	player_bag.append(letter)

func sort_letter_to_route(letter: LetterResource, route: String) -> void:
	letter.is_sorted = true
	letter.sorted_to_correct_route = (route == letter.route)
	sorted_letters[route].append(letter)
	
	if not letter.sorted_to_correct_route:
		log_error(letter, "wrong_pigeonhole")
	if not letter.is_postmarked:
		log_error(letter, "missing_postmark")

func postmark_letter(letter: LetterResource, applied_route: String, applied_class: String) -> void:
	letter.is_postmarked = true
	var route_correct = applied_route == letter.route
	var class_correct = applied_class == letter.mail_class
	letter.postmark_correct = route_correct and class_correct
	
	if not route_correct:
		log_error(letter, "wrong_postmark_color")
	if not class_correct:
		log_error(letter, "wrong_class_postmark")

func log_error(letter: LetterResource, error_type: String) -> void:
	postal_errors.append({
		"letter_id": letter.letter_id,
		"error": error_type,
		"day": GameManager.current_day
	})
	GameManager.daily_error_count += 1

func get_bag_for_night() -> Array[LetterResource]:
	return player_bag

func end_of_day_check() -> void:
	# Check express letters that weren't dispatched
	for letter in outgoing_pile:
		if letter.is_time_sensitive and not letter.is_sorted and not letter.is_bagged:
			log_error(letter, "express_held")
