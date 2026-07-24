class_name Package
extends DraggableSprite

@export_group("Grid Setup")
@export var cell_size: float = 64.0

@export_group("Grid Dimensions (Size Control)")
## Turn ON to manually type grid size in the Inspector. Turn OFF to calculate automatically from image pixels.
@export var manual_override: bool = false
@export var grid_width: int = 2
@export var grid_height: int = 3

var is_placed_on_grid: bool = false

func _ready() -> void:
	super._ready()
	
	var self_obj: Object = self
	if self_obj is Sprite2D:
		var sprite = self_obj as Sprite2D
		sprite.centered = false
		sprite.texture_changed.connect(calculate_grid_dimensions)
		
	# Find postal grid if not assigned
	if postal_grid == null:
		postal_grid = get_tree().get_first_node_in_group("postal_grid")
		
	if postal_grid and postal_grid.has_method("get") and postal_grid.get("cell_size") != null:
		cell_size = postal_grid.cell_size
		
	# If manual override is off, calculate size dynamically from the texture
	if not manual_override:
		calculate_grid_dimensions()

func calculate_grid_dimensions() -> void:
	if manual_override:
		return
		
	var self_obj: Object = self
	if self_obj is Sprite2D and (self_obj as Sprite2D).texture != null and cell_size > 0.0:
		var sprite = self_obj as Sprite2D
		var tex_size = sprite.texture.get_size()
		
		var scaled_width = (tex_size.x * sprite.scale.x)
		var scaled_height = (tex_size.y * sprite.scale.y)
		
		grid_width = maxi(1, roundi(scaled_width / cell_size))
		grid_height = maxi(1, roundi(scaled_height / cell_size))
