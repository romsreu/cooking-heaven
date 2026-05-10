class_name Piece
extends Control

const DONUT_PIECE = preload("uid://bknuqfd8bh253")
const EXPLOSIVE_DONUT = preload("uid://c115qf6ed8ugl")
const HORIZONTAL_DONUT = preload("uid://bhuc6uhmkm54c")
const VERTICAL_DONUT = preload("uid://s2sya5g8f3d4")

const EXPLOSIVE_FISH = preload("uid://lk5m0nu2ssma")
const FISH_PIECE = preload("uid://djxrqjju6c1xk")
const HORIZONTAL_FISH = preload("uid://b2013jhlwtnxe")
const VERTICAL_FISH = preload("uid://cknlv2s50sgpg")

const EXPLOSIVE_MILK = preload("uid://behgnjypjr32h")
const HORIZONTAL_MILK = preload("uid://c7qwujb7v5ojw")
const MILK_PIECE = preload("uid://c8q6efu750dlu")
const VERTICAL_MILK = preload("uid://c0n0b6wl4qvpr")

const EXPLOSIVE_SANDWICH = preload("uid://ccecxfjk8r23r")
const HORIZONTAL_SANDWICH = preload("uid://dx4lr1gatem5f")
const SANDWICH_PIECE = preload("uid://bltv6xo34nsks")
const VERTICAL_SANDWICH = preload("uid://b430lximtwumm")

const EXPLOSIVE_TOMATO = preload("uid://b27jdh0scidfh")
const HORIZONTAL_TOMATO = preload("uid://c8kqflpucyhtq")
const TOMATO_PIECE = preload("uid://b38g2fpwio0wf")
const VERTICAL_TOMATO = preload("uid://cmw8ewbln2qpn")

const COLOR_BOMB = preload("uid://dsbew44qeoymg")

enum SpecialType {
	NONE,
	STRIPED_H,
	STRIPED_V,
	WRAPPED,
	COLOR_BOMB,
}

enum PieceType {
	DONUT,
	FISH,
	MILK,
	SANDWICH,
	TOMATO
}

var type: PieceType
var special_type: SpecialType = SpecialType.NONE
var texture_rect: TextureRect

func _ready():
	texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(texture_rect)
	texture_rect.anchor_left = 0
	texture_rect.anchor_top = 0
	texture_rect.anchor_right = 1
	texture_rect.anchor_bottom = 1

func setup(p_type: PieceType) -> void:
	type = p_type
	special_type = SpecialType.NONE
	if texture_rect:
		update_visual()

func get_type() -> PieceType:
	return type

# ---------------------------------------------------------------------------
# Visual
# ---------------------------------------------------------------------------

func update_visual() -> void:
	texture_rect.texture = get_current_texture()

func get_current_texture() -> Texture2D:
	if special_type == SpecialType.COLOR_BOMB:
		return COLOR_BOMB

	match special_type:
		SpecialType.STRIPED_H: return _get_horizontal_texture()
		SpecialType.STRIPED_V: return _get_vertical_texture()
		SpecialType.WRAPPED:   return _get_explosive_texture()
		_:                     return _get_base_texture()

func _get_base_texture() -> Texture2D:
	match type:
		PieceType.DONUT:    return DONUT_PIECE
		PieceType.FISH:     return FISH_PIECE
		PieceType.MILK:     return MILK_PIECE
		PieceType.SANDWICH: return SANDWICH_PIECE
		PieceType.TOMATO:   return TOMATO_PIECE
		_:                  return null

func _get_horizontal_texture() -> Texture2D:
	match type:
		PieceType.DONUT:    return HORIZONTAL_DONUT
		PieceType.FISH:     return HORIZONTAL_FISH
		PieceType.MILK:     return HORIZONTAL_MILK
		PieceType.SANDWICH: return HORIZONTAL_SANDWICH
		PieceType.TOMATO:   return HORIZONTAL_TOMATO
		_:                  return null

func _get_vertical_texture() -> Texture2D:
	match type:
		PieceType.DONUT:    return VERTICAL_DONUT
		PieceType.FISH:     return VERTICAL_FISH
		PieceType.MILK:     return VERTICAL_MILK
		PieceType.SANDWICH: return VERTICAL_SANDWICH
		PieceType.TOMATO:   return VERTICAL_TOMATO
		_:                  return null

func _get_explosive_texture() -> Texture2D:
	match type:
		PieceType.DONUT:    return EXPLOSIVE_DONUT
		PieceType.FISH:     return EXPLOSIVE_FISH
		PieceType.MILK:     return EXPLOSIVE_MILK
		PieceType.SANDWICH: return EXPLOSIVE_SANDWICH
		PieceType.TOMATO:   return EXPLOSIVE_TOMATO
		_:                  return null

# ---------------------------------------------------------------------------
# Activación
# ---------------------------------------------------------------------------

func activate(board: GameBoard, cell: Vector2i) -> Array:
	match special_type:
		SpecialType.STRIPED_H:  return _get_full_row(board, cell.y)
		SpecialType.STRIPED_V:  return _get_full_column(board, cell.x)
		SpecialType.WRAPPED:    return _get_area(board, cell, 1)
		SpecialType.COLOR_BOMB: return board.get_all_positions_of_type(type)
		_:                      return [cell]

func _get_full_row(board: GameBoard, row: int) -> Array:
	var positions: Array = []
	for col in board.columns:
		positions.append(Vector2i(col, row))
	return positions

func _get_full_column(board: GameBoard, col: int) -> Array:
	var positions: Array = []
	for row in board.rows:
		positions.append(Vector2i(col, row))
	return positions

func _get_area(board: GameBoard, center: Vector2i, radius: int) -> Array:
	var positions: Array = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell = Vector2i(x, y)
			if board.is_valid_cell(cell):
				positions.append(cell)
	return positions
