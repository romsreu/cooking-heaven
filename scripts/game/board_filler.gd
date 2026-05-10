class_name BoardFiller
extends Object

# ---------------------------------------------------------------------------
# Maneja la caída y aparición de piezas, respetando la forma del tablero.
# Lógica bloqueante: las piezas no atraviesan celdas no jugables.
# ---------------------------------------------------------------------------

static func drop_existing_pieces(board: GameBoard) -> void:
	var tweens: Array = []

	for col in board.columns:
		# Obtener las celdas jugables de esta columna en orden de abajo hacia arriba
		var playable_rows: Array = []
		for row in board.rows:
			if board.logic.is_valid_cell(Vector2i(col, row)):
				playable_rows.append(row)

		# Caída: para cada celda jugable de abajo hacia arriba, si está vacía,
		# tirar la siguiente pieza no nula que esté arriba (también jugable).
		# Procesamos de abajo hacia arriba para que las piezas se "apoyen".
		for i in range(playable_rows.size() - 1, -1, -1):
			var target_row = playable_rows[i]
			var target_cell = Vector2i(col, target_row)

			if board.get_cell(target_cell) != null:
				continue  # ya hay pieza ahí

			# Buscar pieza arriba (en celdas jugables más altas)
			for j in range(i - 1, -1, -1):
				var source_row = playable_rows[j]
				var source_cell = Vector2i(col, source_row)
				var piece = board.get_cell(source_cell)
				if piece != null:
					# Mover esa pieza hasta target_cell
					board.logic.set_cell(target_cell, piece)
					board.logic.set_cell(source_cell, null)
					var fall_distance = target_row - source_row
					var duration = 0.1 + fall_distance * 0.04
					var tween = board.create_tween()
					tween.tween_property(piece, "position", board.cell_to_pixel(target_cell), duration) \
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tweens.append(tween)
					break

	if tweens.size() > 0:
		await tweens[tweens.size() - 1].finished

static func spawn_new_pieces(board: GameBoard) -> void:
	var tweens: Array = []

	for col in board.columns:
		# Obtener las celdas jugables de esta columna en orden descendente (de abajo a arriba)
		var playable_rows: Array = []
		for row in board.rows:
			if board.logic.is_valid_cell(Vector2i(col, row)):
				playable_rows.append(row)

		# Contar cuántas piezas faltan en esta columna
		var spawn_offset = 0
		for i in range(playable_rows.size() - 1, -1, -1):
			var row = playable_rows[i]
			var cell = Vector2i(col, row)
			if board.get_cell(cell) == null:
				spawn_offset += 1
				var piece = board.create_piece_at(cell)
				# Las piezas nuevas spawnean desde "arriba" del tablero (off-screen)
				piece.position = board.cell_to_pixel(Vector2i(col, -spawn_offset))
				var duration = 0.1 + spawn_offset * 0.04
				var tween = board.create_tween()
				tween.tween_property(piece, "position", board.cell_to_pixel(cell), duration) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tweens.append(tween)

	if tweens.size() > 0:
		await tweens[tweens.size() - 1].finished
