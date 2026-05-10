class_name BoardShapeCatalog
extends RefCounted

# ---------------------------------------------------------------------------
# Catálogo de formas de tablero predefinidas.
# Cada función static devuelve un BoardShape válido para caída bloqueante.
# ---------------------------------------------------------------------------

enum ShapeType {
	RECTANGLE,
	CROSS,
	DIAMOND,
	DOUBLE_COLUMN,
	LADDER,
	PYRAMID,
	CROSS_THIN,
	U_SHAPE,
	T_SHAPE,
}

# ---------------------------------------------------------------------------
# Factory principal
# ---------------------------------------------------------------------------

static func create(shape_type: ShapeType, rows: int = 9, columns: int = 9) -> BoardShape:
	match shape_type:
		ShapeType.RECTANGLE:     return _rectangle(rows, columns)
		ShapeType.CROSS:         return _cross(rows, columns)
		ShapeType.DIAMOND:       return _diamond(rows, columns)
		ShapeType.DOUBLE_COLUMN: return _double_column(rows, columns)
		ShapeType.LADDER:        return _ladder(rows, columns)
		ShapeType.PYRAMID:       return _pyramid(rows, columns)
		ShapeType.CROSS_THIN:    return _cross_thin(rows, columns)
		ShapeType.U_SHAPE:       return _u_shape(rows, columns)
		ShapeType.T_SHAPE:       return _t_shape(rows, columns)
		_: return _rectangle(rows, columns)

# ---------------------------------------------------------------------------
# Formas
# ---------------------------------------------------------------------------

static func _rectangle(rows: int, columns: int) -> BoardShape:
	return BoardShape.new(rows, columns)

static func _cross(rows: int, columns: int) -> BoardShape:
	var shape = BoardShape.new(rows, columns)
	var center_col_min = columns / 3
	var center_col_max = columns - center_col_min - 1
	var center_row_min = rows / 3
	var center_row_max = rows - center_row_min - 1

	for row in rows:
		for col in columns:
			var in_horizontal_band = row >= center_row_min and row <= center_row_max
			var in_vertical_band = col >= center_col_min and col <= center_col_max
			shape.set_playable(Vector2i(col, row), in_horizontal_band or in_vertical_band)
	return shape

static func _diamond(rows: int, columns: int) -> BoardShape:
	var shape = BoardShape.new(rows, columns)
	var center_row = rows / 2
	var center_col = columns / 2
	var radius = (rows + columns) / 4

	for row in rows:
		for col in columns:
			var dist = abs(row - center_row) + abs(col - center_col)
			shape.set_playable(Vector2i(col, row), dist <= radius)
	return shape

static func _double_column(rows: int, columns: int) -> BoardShape:
	var shape = BoardShape.new(rows, columns)
	var gap_col_min = columns / 2 - columns / 8
	var gap_col_max = columns / 2 + columns / 8

	for row in rows:
		for col in columns:
			var in_gap = col >= gap_col_min and col <= gap_col_max
			shape.set_playable(Vector2i(col, row), not in_gap)
	return shape

static func _ladder(rows: int, columns: int) -> BoardShape:
	var shape = BoardShape.new(rows, columns)
	var step_height = max(1, rows / 4)

	for row in rows:
		for col in columns:
			var step = row / step_height
			var col_min = step
			var col_max = columns - 1 - (rows / step_height - step - 1)
			shape.set_playable(Vector2i(col, row), col >= col_min and col <= col_max)
	return shape

static func _pyramid(rows: int, columns: int) -> BoardShape:
	var shape = BoardShape.new(rows, columns)

	for row in rows:
		var inset = row * columns / (rows * 2)
		for col in columns:
			var playable = col >= inset and col < columns - inset
			shape.set_playable(Vector2i(col, row), playable)
	return shape

static func _cross_thin(rows: int, columns: int) -> BoardShape:
	# Cruz con brazos delgados (1 celda) pero núcleo central grueso
	var shape = BoardShape.new(rows, columns)
	var center_col = columns / 2
	var center_row = rows / 2

	for row in rows:
		for col in columns:
			var in_v_arm = col == center_col
			var in_h_arm = row == center_row
			var in_core = abs(col - center_col) <= 1 and abs(row - center_row) <= 1
			shape.set_playable(Vector2i(col, row), in_v_arm or in_h_arm or in_core)
	return shape

static func _u_shape(rows: int, columns: int) -> BoardShape:
	# U: dos columnas laterales completas + fila inferior. Hueco arriba en el medio.
	var shape = BoardShape.new(rows, columns)
	var side_width = max(2, columns / 4)
	var bottom_height = max(2, rows / 4)

	for row in rows:
		for col in columns:
			var in_left = col < side_width
			var in_right = col >= columns - side_width
			var in_bottom = row >= rows - bottom_height
			shape.set_playable(Vector2i(col, row), in_left or in_right or in_bottom)
	return shape

static func _t_shape(rows: int, columns: int) -> BoardShape:
	# T: fila superior completa + columna central
	var shape = BoardShape.new(rows, columns)
	var top_height = max(2, rows / 4)
	var center_width = max(2, columns / 4)
	var center_col_min = columns / 2 - center_width / 2
	var center_col_max = columns / 2 + center_width / 2

	for row in rows:
		for col in columns:
			var in_top = row < top_height
			var in_center_col = col >= center_col_min and col <= center_col_max
			shape.set_playable(Vector2i(col, row), in_top or in_center_col)
	return shape

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func get_all_shape_types() -> Array:
	return [
		ShapeType.RECTANGLE,
		ShapeType.CROSS,
		ShapeType.DIAMOND,
		ShapeType.DOUBLE_COLUMN,
		ShapeType.LADDER,
		ShapeType.PYRAMID,
		ShapeType.CROSS_THIN,
		ShapeType.U_SHAPE,
		ShapeType.T_SHAPE,
	]

static func get_shape_name(shape_type: ShapeType) -> String:
	match shape_type:
		ShapeType.RECTANGLE:     return "Rectángulo"
		ShapeType.CROSS:         return "Cruz"
		ShapeType.DIAMOND:       return "Diamante"
		ShapeType.DOUBLE_COLUMN: return "Doble columna"
		ShapeType.LADDER:        return "Escalera"
		ShapeType.PYRAMID:       return "Pirámide"
		ShapeType.CROSS_THIN:    return "Cruz delgada"
		ShapeType.U_SHAPE:       return "U"
		ShapeType.T_SHAPE:       return "T"
		_: return "Desconocido"
