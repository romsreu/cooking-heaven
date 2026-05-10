class_name ScoreObjective
extends Objective

func _init() -> void:
	type = Type.SCORE

func on_score_added(points: int) -> void:
	current_amount += points

func get_display_text() -> String:
	return "%d / %d pts" % [min(current_amount, target_amount), target_amount]
