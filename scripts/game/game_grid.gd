class_name GameBoard
extends Control

signal swap_completed(valid: bool)

@export_group("Board Settings")
@export var rows: int = 9
@export var columns: int = 9

@export_group("Piece Settings")
@export var piece_size: Vector2 = Vector2(64, 64)
@export var horizontal_spacing: float = 12.0
@export var vertical_spacing: float = 13.0

@export var min_drag_distance: float = 40.0

const SCORE_PER_PIECE: int = 60
const SCORE_PER_SPECIAL_CREATED: int = 100
const COMBO_MULTIPLIER_INCREMENT: float = 0.5

var current_combo: int = 0
var logic: BoardLogic
var is_swapping: bool = false

var drag_start_cell: Vector2i = Vector2i(-1, -1)
var drag_start_pos: Vector2 = Vector2.ZERO
var dragged_piece: Piece = null

@onready var match_detector: MatchDetector = $MatchDetector
@onready var fx_layer: FXLayer = $FxLayer

func _ready():
	if not GameState.current_level_data:
		initialize_board()

func _apply_level_data(data: LevelData) -> void:
	rows = data.rows
	columns = data.columns

# ---------------------------------------------------------------------------
# Atajos a logic
# ---------------------------------------------------------------------------

func get_cell(pos: Vector2i) -> Piece:
	return logic.get_cell(pos)

func set_cell(pos: Vector2i, piece) -> void:
	logic.set_cell(pos, piece)

func is_valid_cell(pos: Vector2i) -> bool:
	return logic.is_valid_cell(pos)

func get_all_positions_of_type(type: Piece.PieceType) -> Array:
	return logic.get_all_positions_of_type(type)

# ---------------------------------------------------------------------------
# Inicialización
# ---------------------------------------------------------------------------

func initialize_board() -> void:
	clear_board()
	# Usar la forma del nivel actual si existe
	var shape: BoardShape = null
	if GameState.current_level_data and GameState.current_level_data.shape:
		shape = GameState.current_level_data.shape
	logic = BoardLogic.new(rows, columns, shape)
	generate_initial_pieces()
	update_board_size()

func clear_board() -> void:
	for child in get_children():
		if child is Piece:
			child.queue_free()

func generate_initial_pieces() -> void:
	var available_types = []
	if GameState.current_level_data and GameState.current_level_data.available_piece_types.size() > 0:
		available_types = GameState.current_level_data.available_piece_types

	# Solo crear piezas en celdas jugables
	for cell in logic.get_all_playable_cells():
		var safe_type = logic.get_safe_random_type(cell, available_types)
		create_piece_at(cell, safe_type)

func create_piece_at(cell: Vector2i, forced_type = null) -> Piece:
	var piece = Piece.new()
	var piece_type
	if forced_type != null:
		piece_type = forced_type
	else:
		var available = Piece.PieceType.values()
		if GameState.current_level_data and GameState.current_level_data.available_piece_types.size() > 0:
			available = GameState.current_level_data.available_piece_types
		piece_type = available[randi() % available.size()]

	piece.custom_minimum_size = piece_size
	piece.size = piece_size
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(piece)
	piece.setup(piece_type)
	piece.position = cell_to_pixel(cell)

	logic.set_cell(cell, piece)
	return piece

func update_board_size() -> void:
	var total_width = columns * piece_size.x + (columns - 1) * horizontal_spacing
	var total_height = rows * piece_size.y + (rows - 1) * vertical_spacing
	custom_minimum_size = Vector2(total_width, total_height)

# ---------------------------------------------------------------------------
# Conversiones cell ↔ pixel
# ---------------------------------------------------------------------------

func cell_to_pixel(pos: Vector2i) -> Vector2:
	return Vector2(
		pos.x * (piece_size.x + horizontal_spacing),
		pos.y * (piece_size.y + vertical_spacing)
	)

func pixel_to_cell(screen_pos: Vector2) -> Vector2i:
	var col = int(screen_pos.x / (piece_size.x + horizontal_spacing))
	var row = int(screen_pos.y / (piece_size.y + vertical_spacing))

	var cell = Vector2i(col, row)
	if is_valid_cell(cell):
		var local_x = screen_pos.x - col * (piece_size.x + horizontal_spacing)
		var local_y = screen_pos.y - row * (piece_size.y + vertical_spacing)
		if local_x >= 0 and local_x <= piece_size.x and local_y >= 0 and local_y <= piece_size.y:
			return cell

	return Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Input / Drag
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if is_swapping:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			on_drag_start(event.position)
		else:
			on_drag_end(event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		on_dragging(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			on_drag_start(event.position)
		else:
			on_drag_end(event.position)
	elif event is InputEventScreenDrag:
		on_dragging(event.position)

func on_drag_start(pos: Vector2) -> void:
	var cell = pixel_to_cell(pos)

	if cell.x == -1:
		drag_start_cell = Vector2i(-1, -1)
		dragged_piece = null
		return

	drag_start_cell = cell
	drag_start_pos = pos
	dragged_piece = get_cell(cell)

	if dragged_piece:
		var tween = create_tween()
		tween.tween_property(dragged_piece, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK)
		dragged_piece.modulate = Color(1.3, 1.3, 1.3)

func on_dragging(pos: Vector2) -> void:
	if drag_start_cell.x == -1 or not dragged_piece:
		return

	var drag_vector = pos - drag_start_pos
	if drag_vector.length() < min_drag_distance:
		return

	var target_cell = drag_start_cell

	if abs(drag_vector.x) > abs(drag_vector.y):
		target_cell.x += 1 if drag_vector.x > 0 else -1
	else:
		target_cell.y += 1 if drag_vector.y > 0 else -1

	if is_valid_cell(target_cell):
		execute_swap(drag_start_cell, target_cell)
		drag_start_cell = Vector2i(-1, -1)
		dragged_piece = null

func on_drag_end(_pos: Vector2) -> void:
	if dragged_piece:
		var tween = create_tween()
		tween.tween_property(dragged_piece, "scale", Vector2(1.0, 1.0), 0.1)
		dragged_piece.modulate = Color(1.0, 1.0, 1.0)

	drag_start_cell = Vector2i(-1, -1)
	dragged_piece = null

# ---------------------------------------------------------------------------
# Swap
# ---------------------------------------------------------------------------

func execute_swap(cell_a: Vector2i, cell_b: Vector2i) -> void:
	is_swapping = true

	var piece1 = get_cell(cell_a)
	var piece2 = get_cell(cell_b)

	if not piece1 or not piece2:
		is_swapping = false
		return

	piece1.scale = Vector2(1.0, 1.0)
	piece1.modulate = Color(1.0, 1.0, 1.0)

	var tween1 = create_tween()
	var tween2 = create_tween()
	tween1.tween_property(piece1, "position", cell_to_pixel(cell_b), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween2.tween_property(piece2, "position", cell_to_pixel(cell_a), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	logic.swap_cells(cell_a, cell_b)

	await tween1.finished

	if piece1.special_type == Piece.SpecialType.COLOR_BOMB or piece2.special_type == Piece.SpecialType.COLOR_BOMB:
		await _activate_color_bomb_swap(piece1, piece2, cell_a, cell_b)
		is_swapping = false
		return

	var matches = match_detector.check_and_emit(logic)

	if matches.size() > 0:
		emit_signal("swap_completed", true)
		current_combo = 0
		GameState.consume_move()
		await process_matches(matches, cell_a, cell_b)
	else:
		emit_signal("swap_completed", false)
		await revert_swap(cell_a, cell_b, piece1, piece2)

	is_swapping = false

func revert_swap(cell_a: Vector2i, cell_b: Vector2i, piece1: Piece, piece2: Piece) -> void:
	var tween1 = create_tween()
	var tween2 = create_tween()
	tween1.tween_property(piece1, "position", cell_to_pixel(cell_a), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween2.tween_property(piece2, "position", cell_to_pixel(cell_b), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	logic.swap_cells(cell_a, cell_b)

	await tween1.finished

func _trigger_fx_for_piece(piece: Piece, cell: Vector2i) -> void:
	var pos = cell_to_pixel(cell) + piece_size / 2.0
	match piece.special_type:
		Piece.SpecialType.STRIPED_H:   fx_layer.play_striped_h(pos)
		Piece.SpecialType.STRIPED_V:   fx_layer.play_striped_v(pos)
		Piece.SpecialType.WRAPPED:     fx_layer.play_wrapped(pos)
		Piece.SpecialType.COLOR_BOMB:  fx_layer.play_color_bomb(pos)

# ---------------------------------------------------------------------------
# Matches
# ---------------------------------------------------------------------------

func process_matches(matches: Array, moved_a: Vector2i = Vector2i(-1, -1), moved_b: Vector2i = Vector2i(-1, -1)) -> void:
	var pieces_to_remove: Array = []
	var specials_to_create: Array = []
	var seen_remove := {}
	var seen_special := {}
	var fx_already_triggered := {}

	matches.sort_custom(func(a, b): return a.cells.size() > b.cells.size())

	for match_group in matches:
		var special = match_detector.get_special_type_for_match(match_group)
		var spawn_cell: Vector2i = Vector2i(-1, -1)

		if special != Piece.SpecialType.NONE:
			if match_group.is_tl:
				spawn_cell = match_group.intersection
			else:
				spawn_cell = _find_moved_cell_in_group(match_group.cells, moved_a, moved_b)
				if spawn_cell.x == -1:
					spawn_cell = match_group.cells[match_group.cells.size() / 2]

			if not seen_special.has(spawn_cell):
				seen_special[spawn_cell] = true
				var base_piece = get_cell(spawn_cell)
				if base_piece:
					specials_to_create.append({
						"cell": spawn_cell,
						"base_type": base_piece.get_type(),
						"special": special,
					})

		for cell in match_group.cells:
			var piece = get_cell(cell)
			if not piece:
				continue

			if piece.special_type != Piece.SpecialType.NONE and not fx_already_triggered.has(cell):
				fx_already_triggered[cell] = true
				_trigger_fx_for_piece(piece, cell)

			var affected_cells = piece.activate(self, cell)
			for affected in affected_cells:
				if not seen_remove.has(affected):
					seen_remove[affected] = true
					pieces_to_remove.append(affected)

	pieces_to_remove = pieces_to_remove.filter(func(c): return not seen_special.has(c))

	var combo_multiplier = 1.0 + current_combo * COMBO_MULTIPLIER_INCREMENT
	var pieces_count = pieces_to_remove.size() + specials_to_create.size()
	var match_score = int(pieces_count * SCORE_PER_PIECE * combo_multiplier)
	match_score += specials_to_create.size() * SCORE_PER_SPECIAL_CREATED
	GameState.add_score(match_score)
	current_combo += 1

	await remove_pieces(pieces_to_remove)

	for spec in specials_to_create:
		var old_piece = get_cell(spec.cell)
		if old_piece:
			logic.set_cell(spec.cell, null)
			old_piece.queue_free()

	for spec in specials_to_create:
		var piece = create_piece_at(spec.cell, spec.base_type)
		piece.special_type = spec.special
		piece.update_visual()
		piece.scale = Vector2(0.5, 0.5)
		var pop_tween = create_tween()
		pop_tween.tween_property(piece, "scale", Vector2(1.0, 1.0), 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await _fill_board()

	var new_matches = match_detector.check_and_emit(logic)
	if new_matches.size() > 0:
		await get_tree().create_timer(0.15).timeout
		await process_matches(new_matches)
	else:
		match_detector.check_has_moves(logic)
		GameState.check_end_conditions_after_cascades()

func _find_moved_cell_in_group(cells: Array, moved_a: Vector2i, moved_b: Vector2i) -> Vector2i:
	for cell in cells:
		if cell == moved_a or cell == moved_b:
			return cell
	return Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Color Bomb
# ---------------------------------------------------------------------------

func _activate_color_bomb_swap(piece1: Piece, piece2: Piece, cell_a: Vector2i, cell_b: Vector2i) -> void:
	var bomb: Piece
	var target: Piece
	var bomb_cell: Vector2i

	if piece1.special_type == Piece.SpecialType.COLOR_BOMB:
		bomb = piece1
		bomb_cell = cell_b
		target = piece2
	else:
		bomb = piece2
		bomb_cell = cell_a
		target = piece1

	if target.special_type == Piece.SpecialType.COLOR_BOMB:
		var all_cells = logic.get_all_occupied_cells()
		_trigger_fx_for_piece(bomb, bomb_cell)
		emit_signal("swap_completed", true)
		current_combo = 0
		GameState.consume_move()
		await remove_pieces(all_cells)
		await _fill_board()

		var post_matches = match_detector.check_and_emit(logic)
		if post_matches.size() > 0:
			await get_tree().create_timer(0.15).timeout
			await process_matches(post_matches)
		else:
			match_detector.check_has_moves(logic)
			GameState.check_end_conditions_after_cascades()
		return

	var positions = get_all_positions_of_type(target.get_type())
	if not positions.has(bomb_cell):
		positions.append(bomb_cell)

	_trigger_fx_for_piece(bomb, bomb_cell)
	emit_signal("swap_completed", true)
	current_combo = 0
	GameState.consume_move()
	await remove_pieces(positions)
	await _fill_board()

	var new_matches = match_detector.check_and_emit(logic)
	if new_matches.size() > 0:
		await get_tree().create_timer(0.15).timeout
		await process_matches(new_matches)
	else:
		match_detector.check_has_moves(logic)
		GameState.check_end_conditions_after_cascades()

# ---------------------------------------------------------------------------
# Eliminación y relleno
# ---------------------------------------------------------------------------

func _fill_board() -> void:
	await BoardFiller.drop_existing_pieces(self)
	await BoardFiller.spawn_new_pieces(self)

func remove_pieces(positions: Array) -> void:
	if positions.is_empty():
		return

	var unique := {}
	for cell in positions:
		unique[cell] = true

	var pieces_by_type := {}

	var master_tween = create_tween().set_parallel(true)
	var any_animated = false

	for cell in unique:
		var piece = get_cell(cell)
		if not piece:
			continue

		var ptype = piece.get_type()
		if not pieces_by_type.has(ptype):
			pieces_by_type[ptype] = 0
		pieces_by_type[ptype] += 1

		logic.set_cell(cell, null)
		master_tween.tween_property(piece, "scale", Vector2.ZERO, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		master_tween.tween_callback(piece.queue_free).set_delay(0.15)
		any_animated = true

	if pieces_by_type.size() > 0:
		GameState.report_pieces_removed(pieces_by_type)

	if any_animated:
		await master_tween.finished
