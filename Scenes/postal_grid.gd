class_name PostalGrid
extends Node2D

@export_group("Grid Dimensions")
@export var columns: int = 7
@export var rows: int = 5
@export var cell_size: float = 64.0

@export_group("Container Settings")
## Drag your main world/table container here so packages return to it when picked up
@export var unplaced_container: Node2D

@export_group("Debug Settings")
## Toggle this on to see the 7x5 grid drawn on your screen during gameplay!
@export var show_debug_grid: bool = true

var grid_data: Array = []

## Track whether initialization has occurred
var _is_initialized: bool = false

func _ready() -> void:
	_initialize_grid()

func _process(_delta: float) -> void:
	if show_debug_grid:
		queue_redraw() # Forces Godot to redraw the grid every frame

func _draw() -> void:
	if not show_debug_grid:
		return
		
	for x in range(columns):
		for y in range(rows):
			var cell_rect = Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
			
			# Color empty cells dark blue/gray, occupied cells red
			var is_occupied = (grid_data.size() > x and grid_data[x].size() > y and grid_data[x][y] != null)
			var fill_color = Color(0.8, 0.2, 0.2, 0.3) if is_occupied else Color(0.2, 0.5, 1.0, 0.15)
			var border_color = Color(1.0, 1.0, 1.0, 0.4)
			
			draw_rect(cell_rect, fill_color, true)
			draw_rect(cell_rect, border_color, false, 1.0)

func _initialize_grid() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	
	grid_data.clear()
	for x in range(columns):
		var column = []
		for y in range(rows):
			column.append(null)
		grid_data.append(column)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = to_local(world_pos)
	return Vector2i(
		floori(local_pos.x / cell_size),
		floori(local_pos.y / cell_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return to_global(Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size))

func can_place_package(package: Node2D, start_cell: Vector2i) -> bool:
	var pkg_width = 1
	var pkg_height = 1
	if package.has_method("get") and package.get("grid_width") != null:
		pkg_width = package.grid_width
		pkg_height = package.grid_height

	for x in range(pkg_width):
		for y in range(pkg_height):
			var cell_x = start_cell.x + x
			var cell_y = start_cell.y + y
			
			if cell_x < 0 or cell_x >= columns or cell_y < 0 or cell_y >= rows:
				return false
				
			if grid_data[cell_x][cell_y] != null and grid_data[cell_x][cell_y] != package:
				return false
				
	return true

func try_place_package(package: Node2D) -> bool:
	var start_cell = world_to_grid(package.global_position)
	
	if can_place_package(package, start_cell):
		remove_package_from_grid(package) # Clear old positions first
		
		var pkg_width = package.grid_width if package.has_method("get") else 1
		var pkg_height = package.grid_height if package.has_method("get") else 1
		
		for x in range(pkg_width):
			for y in range(pkg_height):
				grid_data[start_cell.x + x][start_cell.y + y] = package
				
		package.global_position = grid_to_world(start_cell)
		if package.has_method("set"):
			package.set("is_placed_on_grid", true)
			
		# REPARENT TO GRID: This makes the package move/collapse right along with the cardboard!
		if package.get_parent() != self:
			package.reparent(self, true)
			
		return true
		
	return false

func remove_package_from_grid(package: Node2D) -> void:
	for x in range(columns):
		for y in range(rows):
			if grid_data[x][y] == package:
				grid_data[x][y] = null
				
	if package.has_method("set"):
		package.set("is_placed_on_grid", false)
		
	# REPARENT BACK TO TABLE: Free it from the grid hierarchy so it can be dragged freely
	if package.get_parent() == self:
		if unplaced_container:
			package.reparent(unplaced_container, true)
		else:
			package.reparent(get_tree().current_scene, true)
