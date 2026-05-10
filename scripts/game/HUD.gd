class_name HUD
extends Control

# ---------------------------------------------------------------------------
# HUD del nivel: movimientos, score, objetivos.
# ---------------------------------------------------------------------------

var moves_label: Label
var score_label: Label
var objectives_container: VBoxContainer

func _ready() -> void:
	# El Control raíz ocupa toda la pantalla pero no bloquea input al tablero
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	_build_ui()
	_connect_signals()
	_refresh()

func _build_ui() -> void:
	# Panel con fondo semitransparente, anclado arriba
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0
	panel.anchor_top = 0
	panel.anchor_right = 1
	panel.anchor_bottom = 0
	panel.offset_left = 16
	panel.offset_top = 16
	panel.offset_right = -16
	panel.offset_bottom = 0
	add_child(panel)

	# Estilo de fondo
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	# Fila superior: movs + score
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(top_row)

	moves_label = Label.new()
	moves_label.add_theme_font_size_override("font_size", 24)
	moves_label.add_theme_color_override("font_color", Color.WHITE)
	top_row.add_child(moves_label)

	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 0)
	top_row.add_child(sep)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	top_row.add_child(score_label)

	# Container de objetivos
	objectives_container = VBoxContainer.new()
	objectives_container.add_theme_constant_override("separation", 4)
	objectives_container.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(objectives_container)

func _connect_signals() -> void:
	GameState.moves_changed.connect(_on_moves_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.objectives_changed.connect(_refresh_objectives)

func _refresh() -> void:
	_on_moves_changed(GameState.moves_remaining)
	_on_score_changed(GameState.current_score)
	_refresh_objectives()

func _on_moves_changed(remaining: int) -> void:
	if moves_label:
		moves_label.text = "Movs: %d" % remaining

func _on_score_changed(score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % score

func _refresh_objectives() -> void:
	if not objectives_container:
		return

	for child in objectives_container.get_children():
		child.queue_free()

	if not GameState.current_level_data:
		return

	for obj in GameState.current_level_data.objectives:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var prefix = "✓ " if obj.is_complete() else "• "
		label.text = prefix + obj.get_display_text()
		if obj.is_complete():
			label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
		objectives_container.add_child(label)
