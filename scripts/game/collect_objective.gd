class_name CollectObjective
extends Objective

@export var piece_type: int = 0  # Piece.PieceType (int para que sea exportable)

func _init() -> void:
	type = Type.COLLECT

func on_pieces_removed(pieces_by_type: Dictionary) -> void:
	if pieces_by_type.has(piece_type):
		current_amount += pieces_by_type[piece_type]

func get_display_text() -> String:
	var name = _piece_type_name()
	return "%s: %d / %d" % [name, min(current_amount, target_amount), target_amount]

func _piece_type_name() -> String:
	match piece_type:
		Piece.PieceType.DONUT:    return "Donas"
		Piece.PieceType.FISH:     return "Pescados"
		Piece.PieceType.MILK:     return "Leches"
		Piece.PieceType.SANDWICH: return "Sándwiches"
		Piece.PieceType.TOMATO:   return "Tomates"
		_: return "?"
