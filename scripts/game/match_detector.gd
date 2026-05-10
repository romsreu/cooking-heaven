class_name MatchDetector
extends Node

signal matches_found(matches: Array)
signal no_moves_available()

# ---------------------------------------------------------------------------
# match_group es un Dictionary:
# {
#   "cells": Array[Vector2i],
#   "is_tl": bool,
#   "intersection": Vector2i,
#   "orientation": String,   # "h", "v", "tl"
# }
# ---------------------------------------------------------------------------

func check_and_emit(logic: BoardLogic) -> Array:
	var matches = _check_matches(logic)
	if matches.size() > 0:
		emit_signal("matches_found", matches)
	return matches

func check_has_moves(logic: BoardLogic) -> void:
	if not _has_valid_moves(logic):
		emit_signal("no_moves_available")

# ---------------------------------------------------------------------------
# Detección
# ---------------------------------------------------------------------------

func _check_matches(logic: BoardLogic) -> Array:
	var h_groups: Array = []
	var v_groups: Array = []

	for row in logic.rows:
		var col := 0
		while col < logic.columns:
			var cells = _expand_horizontal(logic, row, col)
			if cells.size() >= 3:
				h_groups.append({
					"cells": cells,
					"is_tl": false,
					"intersection": Vector2i(-1, -1),
					"orientation": "h",
				})
				col += cells.size()
			else:
				col += 1

	for col in logic.columns:
		var row := 0
		while row < logic.rows:
			var cells = _expand_vertical(logic, row, col)
			if cells.size() >= 3:
				v_groups.append({
					"cells": cells,
					"is_tl": false,
					"intersection": Vector2i(-1, -1),
					"orientation": "v",
				})
				row += cells.size()
			else:
				row += 1

	return _resolve_groups(h_groups, v_groups)

func _resolve_groups(h_groups: Array, v_groups: Array) -> Array:
	var matches: Array = []
	var used_h := {}
	var used_v := {}

	for hi in h_groups.size():
		for vi in v_groups.size():
			var intersection = _find_intersection(h_groups[hi].cells, v_groups[vi].cells)
			if intersection.x != -1:
				var merged_cells = _merge_cells(h_groups[hi].cells, v_groups[vi].cells)
				matches.append({
					"cells": merged_cells,
					"is_tl": true,
					"intersection": intersection,
					"orientation": "tl",
				})
				used_h[hi] = true
				used_v[vi] = true

	for hi in h_groups.size():
		if not used_h.has(hi):
			matches.append(h_groups[hi])

	for vi in v_groups.size():
		if not used_v.has(vi):
			matches.append(v_groups[vi])

	return matches

func _find_intersection(cells_a: Array, cells_b: Array) -> Vector2i:
	for a in cells_a:
		for b in cells_b:
			if a == b:
				return a
	return Vector2i(-1, -1)

func _merge_cells(cells_a: Array, cells_b: Array) -> Array:
	var merged: Array = []
	var seen := {}
	for cell in cells_a + cells_b:
		if not seen.has(cell):
			seen[cell] = true
			merged.append(cell)
	return merged

func _expand_horizontal(logic: BoardLogic, row: int, start_col: int) -> Array:
	var piece = logic.get_cell(Vector2i(start_col, row))
	if not piece:
		return []

	var cells: Array = [Vector2i(start_col, row)]
	var type = piece.get_type()

	for col in range(start_col + 1, logic.columns):
		var current = logic.get_cell(Vector2i(col, row))
		if current and current.get_type() == type:
			cells.append(Vector2i(col, row))
		else:
			break

	return cells

func _expand_vertical(logic: BoardLogic, start_row: int, col: int) -> Array:
	var piece = logic.get_cell(Vector2i(col, start_row))
	if not piece:
		return []

	var cells: Array = [Vector2i(col, start_row)]
	var type = piece.get_type()

	for row in range(start_row + 1, logic.rows):
		var current = logic.get_cell(Vector2i(col, row))
		if current and current.get_type() == type:
			cells.append(Vector2i(col, row))
		else:
			break

	return cells

func get_special_type_for_match(match_group: Dictionary) -> Piece.SpecialType:
	if match_group.is_tl:
		return Piece.SpecialType.WRAPPED

	var size = match_group.cells.size()
	if size >= 5:
		return Piece.SpecialType.COLOR_BOMB
	if size == 4:
		return Piece.SpecialType.STRIPED_H if match_group.orientation == "h" else Piece.SpecialType.STRIPED_V
	return Piece.SpecialType.NONE

# ---------------------------------------------------------------------------
# Movimientos válidos
# ---------------------------------------------------------------------------

func _has_valid_moves(logic: BoardLogic) -> bool:
	for row in logic.rows:
		for col in logic.columns:
			var a = Vector2i(col, row)
			if col + 1 < logic.columns:
				var b = Vector2i(col + 1, row)
				logic.swap_cells(a, b)
				var found_h = _check_matches(logic).size() > 0
				logic.swap_cells(a, b)
				if found_h:
					return true
			if row + 1 < logic.rows:
				var b = Vector2i(col, row + 1)
				logic.swap_cells(a, b)
				var found_v = _check_matches(logic).size() > 0
				logic.swap_cells(a, b)
				if found_v:
					return true
	return false
