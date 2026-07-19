extends Resource
class_name LetterResource

# Postal identity
@export var letter_id: String = ""
@export var sender_name: String = ""
@export var sender_address: String = ""
@export var recipient_name: String = ""
@export var recipient_address: String = ""
@export var town: String = ""
@export var state: String = ""
@export var mail_class: String = "regular"  # "regular", "express", "airmail"
@export var route: String = ""  # "RFD 1", "RFD 2", "LOCAL", "PO BOX", "GENERAL DELIVERY"
@export var arrives_with_stamp: bool = true
@export var stamp_is_correct: bool = true
@export var is_time_sensitive: bool = false
@export var is_registered: bool = false
@export var postmark_origin: String = ""
@export var postmark_date: String = ""

# Investigative identity
@export var contains_code: bool = false
@export var contents: String = ""  # only read at night if opened

# State
var is_postmarked: bool = false
var postmark_correct: bool = false
var is_sorted: bool = false
var sorted_to_correct_route: bool = false
var is_bagged: bool = false
var is_opened: bool = false
var player_transcription: String = ""
var chip_generated: bool = false
var is_incoming: bool = true  # false = outgoing from customer
