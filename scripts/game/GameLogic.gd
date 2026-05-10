class_name BoardLogic
extends RefCounted

# ---------------------------------------------------------------------------
# Lógica pura del tablero. NO maneja nodos, tweens, ni input.
#
# Convención: Vector2i(x=col, y=row)
# Acceso al grid: SIEMPRE vía get_cell/set_cell, nunca grid[][] directo.
#
# Ahora soporta una "forma" (BoardShape): celdas no jugables son inválidas.
# ---------------------------------------------------------------------------

var rows: int
var columns: int
var grid: Array[Array] = []
var shape: BoardShape  # forma del tablero (qué celdas son jugables)

func _init(p_rows: int = 9, p_columns: int = 9, p_shape: BoardShape = null) -> void:
	rows = p_rows
	columns = p_columns
	# Si no se da forma, asumimos rectangular (toda jugable)
	shape = p_shape if p_shape else BoardShape.new(p_rows, p_columns)
	_init_grid()

func _init_grid() -> void:
	grid.clear()
	grid.resize(rows)
	for row in rows:
		grid[row] = []
		grid[row].resize(columns)

# ---------------------------------------------------------------------------
# Acceso al grid
# ---------------------------------------------------------------------------

func get_cell(pos: Vector2i) -> Piece:
	if not is_valid_cell(pos):
		return null
	return grid[pos.y][pos.x]

func set_cell(pos: Vector2i, piece) -> void:
	if is_valid_cell(pos):
		grid[pos.y][pos.x] = piece

# Una celda es válida si está dentro del rango Y es jugable según la forma
func is_valid_cell(pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= rows or pos.x < 0 or pos.x >= columns:
		return false
	return shape.is_playable(pos)

# Está dentro del grid (sin importar si es jugable o no)
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < rows and pos.x >= 0 and pos.x < columns

func is_empty(pos: Vector2i) -> bool:
	return get_cell(pos) == null

# ---------------------------------------------------------------------------
# Operaciones de grid
# ---------------------------------------------------------------------------

func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var piece_a = get_cell(a)
	var piece_b = get_cell(b)
	set_cell(a, piece_b)
	set_cell(b, piece_a)

func clear_cell(pos: Vector2i) -> Piece:
	var piece = get_cell(pos)
	set_cell(pos, null)
	return piece

func get_all_positions_of_type(type: Piece.PieceType) -> Array:
	var positions: Array = []
	for cell in shape.get_all_playable_cells():
		var piece = get_cell(cell)
		if piece and piece.get_type() == type:
			positions.append(cell)
	return positions

func get_all_occupied_cells() -> Array:
	var cells: Array = []
	for cell in shape.get_all_playable_cells():
		if get_cell(cell) != null:
			cells.append(cell)
	return cells

func get_all_playable_cells() -> Array:
	return shape.get_all_playable_cells()

# ---------------------------------------------------------------------------
# Generación segura
# ---------------------------------------------------------------------------

func get_safe_random_type(pos: Vector2i, available_types: Array = []) -> Piece.PieceType:
	var all_types = available_types if available_types.size() > 0 else Piece.PieceType.values()
	var forbidden: Array = []

	# Check vertical (2 arriba)
	var above1 = Vector2i(pos.x, pos.y - 1)
	var above2 = Vector2i(pos.x, pos.y - 2)
	if is_valid_cell(above1) and is_valid_cell(above2):
		var p1 = get_cell(above1)
		var p2 = get_cell(above2)
		if p1 and p2 and p1.get_type() == p2.get_type():
			forbidden.append(p1.get_type())

	# Check horizontal (2 izquierda)
	var left1 = Vector2i(pos.x - 1, pos.y)
	var left2 = Vector2i(pos.x - 2, pos.y)
	if is_valid_cell(left1) and is_valid_cell(left2):
		var p1 = get_cell(left1)
		var p2 = get_cell(left2)
		if p1 and p2 and p1.get_type() == p2.get_type():
			forbidden.append(p1.get_type())

	var available = all_types.filter(func(t): return not forbidden.has(t))
	if available.is_empty():
		available = all_types
	return available.pick_random()
