class_name BoardShape
extends Resource

# ---------------------------------------------------------------------------
# Define qué celdas del tablero son jugables y cuáles no.
# Es un Resource para poder asignarlo a un LevelData.
#
# Internamente: Array[Array] de booleanos (true = jugable).
# Acceso: is_playable(Vector2i) — Vector2i(col, row).
# ---------------------------------------------------------------------------

var rows: int
var columns: int
var playable: Array[Array] = []  # playable[row][col] = bool

func _init(p_rows: int = 9, p_columns: int = 9) -> void:
	rows = p_rows
	columns = p_columns
	_init_all_playable()

func _init_all_playable() -> void:
	playable.clear()
	playable.resize(rows)
	for row in rows:
		playable[row] = []
		playable[row].resize(columns)
		for col in columns:
			playable[row][col] = true

# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

func is_playable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
		return false
	return playable[cell.y][cell.x]

func set_playable(cell: Vector2i, value: bool) -> void:
	if cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows:
		playable[cell.y][cell.x] = value

func get_playable_count() -> int:
	var count = 0
	for row in rows:
		for col in columns:
			if playable[row][col]:
				count += 1
	return count

func get_all_playable_cells() -> Array:
	var cells: Array = []
	for row in rows:
		for col in columns:
			if playable[row][col]:
				cells.append(Vector2i(col, row))
	return cells

# ---------------------------------------------------------------------------
# Validación y spawn
# ---------------------------------------------------------------------------

# Verifica que cada columna no tenga secciones aisladas verticalmente.
# Una columna válida es: "...XXX..." (jugable es contiguo).
# Inválida: "X.X" o "XX.X".
func is_valid() -> bool:
	for col in columns:
		var seen_playable = false
		var seen_gap_after_playable = false
		for row in rows:
			var cell = Vector2i(col, row)
			if is_playable(cell):
				if seen_gap_after_playable:
					# Ya vimos un gap, ahora vemos otra X → sección aislada
					return false
				seen_playable = true
			else:
				if seen_playable:
					seen_gap_after_playable = true
	return true

# Devuelve la fila más alta jugable de una columna (desde donde spawnean piezas).
# Devuelve -1 si toda la columna es no jugable.
func get_spawn_row_for_column(col: int) -> int:
	for row in rows:
		if is_playable(Vector2i(col, row)):
			return row
	return -1

# Devuelve la fila más baja jugable de una columna.
# Útil para saber dónde "termina" una columna jugable.
func get_bottom_row_for_column(col: int) -> int:
	for row in range(rows - 1, -1, -1):
		if is_playable(Vector2i(col, row)):
			return row
	return -1
	
# ---------------------------------------------------------------------------
# Útil para debug
# ---------------------------------------------------------------------------

func to_string_grid() -> String:
	var s = ""
	for row in rows:
		for col in columns:
			s += "X " if playable[row][col] else ". "
		s += "\n"
	return s
