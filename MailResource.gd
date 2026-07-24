extends Resource
class_name MailItemData

@export var tracking_id: String = ""
@export var sender_name: String = ""
@export var recipient_name: String = ""
@export var destination_route: String = "LOCAL"

@export var is_story_item: bool = false
@export var is_suspicious: bool = false
@export var raw_letter_text: String = ""

func randomize_data() -> void:
	tracking_id = "PKG-" + str(randi_range(1000, 9999))
	
	var senders = ["Arthur Pendelton", "Clara Higgins", "Sheriff Miller", "Evelyn Vance", "Doc Thomas", "Anonymous"]
	var recipients = ["Mayor Gable", "County Hardware", "Hank's Auto Repair", "Mrs. Gable", "State Depot"]
	var routes = ["LOCAL", "RURAL", "OUT OF STATE"]
	
	sender_name = senders[randi() % senders.size()]
	recipient_name = recipients[randi() % recipients.size()]
	destination_route = routes[randi() % routes.size()]
	
	is_suspicious = randf() < 0.10
	is_story_item = randf() < 0.05
	
	if is_story_item:
		raw_letter_text = "Meet at the old mill behind the quarry. Midnight."
	else:
		raw_letter_text = "Dear friend, hope the winter harvest went well..."
