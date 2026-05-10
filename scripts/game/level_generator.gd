class_name LevelGenerator
extends RefCounted

# ---------------------------------------------------------------------------
# Genera proceduralmente un LevelData a partir del número de nivel.
# ---------------------------------------------------------------------------

enum Mechanic {
	BASIC_SCORE,
	COLLECT,
	TIGHT_MOVES,
	JELLY,
	FROSTING,
	CHOCOLATE,
	LOCKS,
	BRING_DOWN,
}

const INTRO_BAND = {
	Mechanic.BASIC_SCORE:  1,
	Mechanic.COLLECT:      2,
	Mechanic.TIGHT_MOVES:  5,
	Mechanic.JELLY:        8,
	Mechanic.FROSTING:    11,
	Mechanic.CHOCOLATE:   14,
	Mechanic.LOCKS:       17,
	Mechanic.BRING_DOWN:  20,
}

# Formas "fáciles": las que no requieren mucha planificación espacial.
# Se usan en niveles tempranos.
const EASY_SHAPES = [
	BoardShapeCatalog.ShapeType.RECTANGLE,
	BoardShapeCatalog.ShapeType.CROSS,
	BoardShapeCatalog.ShapeType.DIAMOND,
]

# Formas "intermedias": empiezan en niveles medios.
const MEDIUM_SHAPES = [
	BoardShapeCatalog.ShapeType.DOUBLE_COLUMN,
	BoardShapeCatalog.ShapeType.LADDER,
	BoardShapeCatalog.ShapeType.T_SHAPE,
]

# Formas "difíciles": las más exigentes, niveles altos.
const HARD_SHAPES = [
	BoardShapeCatalog.ShapeType.PYRAMID,
	BoardShapeCatalog.ShapeType.CROSS_THIN,
	BoardShapeCatalog.ShapeType.U_SHAPE,
]

static func generate(level_number: int) -> LevelData:
	var data = LevelData.new(level_number)
	var rng = RandomNumberGenerator.new()
	rng.seed = level_number * 7919

	_apply_continuous_curves(data, level_number)
	_apply_band_archetype(data, level_number, rng)
	_apply_board_variation(data, level_number, rng)

	return data

# ---------------------------------------------------------------------------
# Curvas continuas
# ---------------------------------------------------------------------------

static func _apply_continuous_curves(data: LevelData, n: int) -> void:
	data.moves_limit = _moves_for_level(n)
	data.score_target = _score_target_for_level(n)
	data.star_thresholds = [
		data.score_target,
		int(data.score_target * 2.5),
		int(data.score_target * 5.0),
	]
	data.available_piece_types = _piece_types_for_level(n)

static func _moves_for_level(n: int) -> int:
	if n == 1:    return 30
	if n <= 4:    return 25
	if n <= 7:    return 20
	if n <= 15:   return 22
	if n <= 30:   return 20
	return 18

static func _score_target_for_level(n: int) -> int:
	var base = 1000
	var multiplier = pow(1.0 + n * 0.15, 2)
	var raw = int(base * multiplier)
	return int(raw / 500) * 500

static func _piece_types_for_level(n: int) -> Array:
	var all_types = Piece.PieceType.values()
	var count: int
	if n <= 5:    count = 4
	elif n <= 15: count = 5
	else:         count = 6

	count = min(count, all_types.size())

	var rng = RandomNumberGenerator.new()
	rng.seed = n * 7919
	var shuffled = all_types.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp

	return shuffled.slice(0, count)

# ---------------------------------------------------------------------------
# Arquetipo: qué mecánicas están activas en este nivel
# ---------------------------------------------------------------------------

static func _apply_band_archetype(data: LevelData, n: int, rng: RandomNumberGenerator) -> void:
	data.objectives = []

	if is_tutorial(n):
		var tutorial_obj = ScoreObjective.new()
		tutorial_obj.target_amount = data.score_target
		data.objectives.append(tutorial_obj)
		return

	var available = get_available_mechanics(n)
	var built_objectives: Array = []

	var use_collect = available.has(Mechanic.COLLECT) and rng.randf() < 0.8

	if use_collect:
		var num_types: int
		if n <= 4:
			num_types = 1
		elif n <= 9:
			num_types = 2 if rng.randf() < 0.4 else 1
		else:
			num_types = 1 + rng.randi_range(0, 2)

		num_types = min(num_types, data.available_piece_types.size())

		var types_pool: Array = []
		for t in data.available_piece_types:
			types_pool.append(t)

		for i in num_types:
			if types_pool.is_empty():
				break
			var idx = rng.randi() % types_pool.size()
			var chosen_type = types_pool[idx]
			types_pool.remove_at(idx)

			var amount_per_type = _collect_amount(n, num_types)

			var collect_obj = CollectObjective.new()
			collect_obj.piece_type = chosen_type
			collect_obj.target_amount = amount_per_type
			collect_obj.current_amount = 0
			built_objectives.append(collect_obj)
	else:
		var score_obj = ScoreObjective.new()
		score_obj.target_amount = data.score_target
		built_objectives.append(score_obj)

	if use_collect and available.has(Mechanic.TIGHT_MOVES):
		var secondary_score = ScoreObjective.new()
		secondary_score.target_amount = int(data.score_target * 0.7)
		built_objectives.append(secondary_score)

	for obj in built_objectives:
		data.objectives.append(obj)

static func _collect_amount(n: int, num_types: int) -> int:
	var base = 8 + n
	if num_types == 2: base = int(base * 0.7)
	elif num_types == 3: base = int(base * 0.55)
	return max(5, base)

# ---------------------------------------------------------------------------
# Forma de tablero: rectangular en tutorial, varía desde el nivel 2
# ---------------------------------------------------------------------------

static func _apply_board_variation(data: LevelData, n: int, rng: RandomNumberGenerator) -> void:
	data.rows = 9
	data.columns = 9

	# Pool de formas según el nivel
	var pool: Array = []

	if is_tutorial(n):
		# Tutorial: siempre rectangular
		pool = [BoardShapeCatalog.ShapeType.RECTANGLE]
	elif n <= 5:
		# Niveles tempranos: solo formas fáciles
		pool = EASY_SHAPES
	elif n <= 12:
		# Niveles medios: fáciles + intermedias
		pool = EASY_SHAPES + MEDIUM_SHAPES
	else:
		# Niveles altos: todas las formas
		pool = EASY_SHAPES + MEDIUM_SHAPES + HARD_SHAPES

	var chosen_shape_type = pool[rng.randi() % pool.size()]
	data.shape = BoardShapeCatalog.create(chosen_shape_type, data.rows, data.columns)

	print(">>> Nivel ", n, " | Forma: ", BoardShapeCatalog.get_shape_name(chosen_shape_type),
		" | Jugables: ", data.shape.get_playable_count())

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

static func is_tutorial(n: int) -> bool:
	return n == 1

static func get_introduced_mechanic(n: int):
	for mech in INTRO_BAND:
		if INTRO_BAND[mech] == n:
			return mech
	return null

static func get_available_mechanics(n: int) -> Array:
	var result: Array = []
	for mech in INTRO_BAND:
		if INTRO_BAND[mech] <= n:
			result.append(mech)
	return result
