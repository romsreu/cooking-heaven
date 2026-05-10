class_name Objective
extends Resource

enum Type {
	SCORE,
	COLLECT,
}

@export var type: Type = Type.SCORE
@export var target_amount: int = 1000
var current_amount: int = 0

func is_complete() -> bool:
	return current_amount >= target_amount

func get_progress_ratio() -> float:
	if target_amount <= 0:
		return 1.0
	return clamp(float(current_amount) / float(target_amount), 0.0, 1.0)

func get_display_text() -> String:
	return "%d / %d" % [min(current_amount, target_amount), target_amount]

func on_score_added(_points: int) -> void:
	pass

func on_pieces_removed(_pieces_by_type: Dictionary) -> void:
	pass
