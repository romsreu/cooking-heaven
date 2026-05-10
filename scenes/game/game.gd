extends Control

@onready var game_grid: GameBoard = $GameBoard/GameGrid
@onready var levelend: LevelEndPanel = $LEVELEND
@onready var hud: HUD = $HUD

var current_level: int = 1

func _ready() -> void:
	print(">>> Main._ready ejecutado")
	print(">>> Main hijos: ", get_children())
	print(">>> hud encontrado: ", hud)
	levelend.retry_requested.connect(_restart_level)
	levelend.next_level_requested.connect(_next_level)
	# DEBUG TEMPORAL: imprimir todas las formas para verificar
	print(">>> === FORMAS DE TABLERO ===")
	for shape_type in BoardShapeCatalog.get_all_shape_types():
		var shape = BoardShapeCatalog.create(shape_type, 9, 9)
		var valid = shape.is_valid()
		var playable_count = shape.get_playable_count()
		print(">>> Forma: ", BoardShapeCatalog.get_shape_name(shape_type), 
			" | Válida: ", valid, " | Jugables: ", playable_count)
		print(shape.to_string_grid())
	_start_level(current_level)

func _start_level(n: int) -> void:
	print(">>> Main._start_level(", n, ")")
	current_level = n
	# 1. Setear el nivel ANTES de inicializar el board
	GameState.start_level(n)
	# 2. Aplicar dimensiones del LevelData al board
	game_grid._apply_level_data(GameState.current_level_data)
	# 3. Inicializar el tablero
	game_grid.initialize_board()
	# 4. Esperar un frame para garantizar que el HUD esté listo, después refrescar
	await get_tree().process_frame
	if hud:
		print(">>> Refrescando HUD")
		hud._refresh()
	else:
		print(">>> ERROR: HUD es null")

func _restart_level() -> void:
	_start_level(current_level)

func _next_level() -> void:
	_start_level(current_level + 1)
