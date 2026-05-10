class_name LevelEndPanel
extends Control

# ---------------------------------------------------------------------------
# Panel modal que aparece al ganar o perder.
# Bloquea input al tablero mientras está visible.
# ---------------------------------------------------------------------------

signal retry_requested()
signal next_level_requested()

var title_label: Label
var stars_label: Label
var score_label: Label
var button_container: HBoxContainer

func _ready() -> void:
	_build_ui()
	hide()
	GameState.level_won.connect(_on_level_won)
	GameState.level_lost.connect(_on_level_lost)

func _build_ui() -> void:
	# Fondo semi-transparente
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_left = 0
	bg.anchor_top = 0
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# Panel central
	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_top = -150
	panel.offset_right = 200
	panel.offset_bottom = 150
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	stars_label = Label.new()
	stars_label.add_theme_font_size_override("font_size", 32)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stars_label)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_label)

	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 16)
	vbox.add_child(button_container)

func _on_level_won(stars: int, final_score: int) -> void:
	title_label.text = "¡Nivel completado!"
	title_label.modulate = Color(0.5, 1.0, 0.5)
	stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	score_label.text = "Score: %d" % final_score
	_set_buttons(true)
	show()

func _on_level_lost(final_score: int) -> void:
	title_label.text = "Sin movimientos"
	title_label.modulate = Color(1.0, 0.5, 0.5)
	stars_label.text = ""
	score_label.text = "Score: %d" % final_score
	_set_buttons(false)
	show()

func _set_buttons(won: bool) -> void:
	for c in button_container.get_children():
		c.queue_free()

	var retry_btn = Button.new()
	retry_btn.text = "Reintentar"
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.pressed.connect(func(): emit_signal("retry_requested"); hide())
	button_container.add_child(retry_btn)

	if won:
		var next_btn = Button.new()
		next_btn.text = "Siguiente nivel"
		next_btn.add_theme_font_size_override("font_size", 18)
		next_btn.pressed.connect(func(): emit_signal("next_level_requested"); hide())
		button_container.add_child(next_btn)
