class_name GameStateClass
extends Node

# ---------------------------------------------------------------------------
# Estado global del juego. Sobrevive entre escenas.
# Registrado como autoload con el nombre "GameState".
# ---------------------------------------------------------------------------

signal score_changed(new_score: int)
signal moves_changed(remaining: int)
signal objectives_changed()
signal level_won(stars: int, final_score: int)
signal level_lost(final_score: int)

var current_level_data: LevelData = null
var current_score: int = 0
var moves_remaining: int = 0
var level_active: bool = false

var highest_level_unlocked: int = 1

# ---------------------------------------------------------------------------
# Vida del nivel
# ---------------------------------------------------------------------------

func start_level(level_number: int) -> void:
	current_level_data = LevelGenerator.generate(level_number)
	current_score = 0
	moves_remaining = current_level_data.moves_limit
	level_active = true

	# Reset de objetivos (importante: los Resources se comparten, no querés
	# que el progreso quede colgado entre intentos)
	for obj in current_level_data.objectives:
		obj.current_amount = 0

	emit_signal("score_changed", current_score)
	emit_signal("moves_changed", moves_remaining)
	emit_signal("objectives_changed")

func add_score(points: int) -> void:
	if not level_active:
		return
	current_score += points
	for obj in current_level_data.objectives:
		obj.on_score_added(points)
	emit_signal("score_changed", current_score)
	emit_signal("objectives_changed")
	# NO chequeamos victoria aquí — esperamos al final de las cascadas

func report_pieces_removed(pieces_by_type: Dictionary) -> void:
	if not level_active:
		return
	for obj in current_level_data.objectives:
		obj.on_pieces_removed(pieces_by_type)
	emit_signal("objectives_changed")
	# NO chequeamos victoria aquí — esperamos al final de las cascadas

func consume_move() -> void:
	if not level_active:
		return
	moves_remaining -= 1
	emit_signal("moves_changed", moves_remaining)
	# No chequeamos end aquí: dejamos que las cascadas terminen primero.
	# El check final se hace cuando el board emite "swap_completed" + cascadas terminan.

func check_end_conditions_after_cascades() -> void:
	# Llamado por GameBoard cuando todas las cascadas de un swap terminaron.
	# Acá decidimos victoria o derrota, después de que los puntos finales
	# de la cascada ya se contabilizaron.
	if not level_active:
		return
	if all_objectives_complete():
		_win_level()
	elif moves_remaining <= 0:
		_lose_level()

func all_objectives_complete() -> bool:
	for obj in current_level_data.objectives:
		if not obj.is_complete():
			return false
	return true

func _win_level() -> void:
	if not level_active:
		return
	level_active = false
	var stars = _calculate_stars()
	if current_level_data.level_number >= highest_level_unlocked:
		highest_level_unlocked = current_level_data.level_number + 1
	emit_signal("level_won", stars, current_score)

func _lose_level() -> void:
	if not level_active:
		return
	level_active = false
	emit_signal("level_lost", current_score)

func _calculate_stars() -> int:
	var thresholds = current_level_data.star_thresholds
	if current_score >= thresholds[2]: return 3
	if current_score >= thresholds[1]: return 2
	return 1
