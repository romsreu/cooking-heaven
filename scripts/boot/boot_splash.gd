extends Control
const MAIN_MENU = preload("uid://2p6oiybfwr5m")
const BOOT_SOUND = preload("uid://dk6lw16a7rchi")
const GENERAL_SETTINGS = preload("uid://bb7o8cneasyfo")
const GAME_BOARD = preload("uid://rq6gudt8vaw5")

@onready var loader: ColorRect = $Loader
@onready var admob: Admob = $Admob

const SHADERS_TO_PRELOAD = [
	"res://resources/shaders/shiny_text.gdshader",
]

func _ready():
	AudioManager.play_sfx(BOOT_SOUND)
	
	if OS.get_name() == "Android":
		admob.initialize()
		await admob.initialization_completed
		remove_child(admob)
		get_tree().root.add_child(admob)
		AdmobUtil.set_admob(admob)

	await precompile_shaders()
	get_tree().change_scene_to_packed(MAIN_MENU)

func precompile_shaders():
	print("Iniciando precompilación de shaders...")
	var temp_nodes = []
	var compiled_count = 0
	
	for shader_path in SHADERS_TO_PRELOAD:
		if not FileAccess.file_exists(shader_path):
			push_warning("Shader no encontrado: " + shader_path)
			continue
		
		var shader = load(shader_path)
		if shader == null:
			push_warning("No se pudo cargar el shader: " + shader_path)
			continue
		
		var material_ = ShaderMaterial.new()
		material_.shader = shader
		
		var rect = ColorRect.new()
		rect.material = material_
		rect.size = Vector2(1, 1) 
		rect.visible = false
		
		add_child(rect)
		temp_nodes.append(rect)
		compiled_count += 1
		print(shader_path.get_file())
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	for node in temp_nodes:
		node.queue_free()
	
	print("Shaders precompilados: %d/%d" % [compiled_count, SHADERS_TO_PRELOAD.size()])
