class_name LevelData
extends Resource

@export var level_number: int = 1
@export var rows: int = 9
@export var columns: int = 9
@export var moves_limit: int = 25
@export var score_target: int = 1000
@export var available_piece_types: Array = []
@export var star_thresholds: Array[int] = [1000, 2500, 5000]
@export var objectives: Array[Objective] = []

# Forma del tablero (qué celdas son jugables)
var shape: BoardShape = null

func _init(p_level_number: int = 1) -> void:
	level_number = p_level_number
