extends ColorRect
## Presentation only. BackgroundSession and route transactions retain ownership.

const AtmosphereShader = preload("res://assets/shaders/diamond_atmosphere.gdshader")

var motion_enabled := true
var phase := 0.0
var profile := "menu"
var shader_material: ShaderMaterial

static func install(host: Control, context: String = "menu") -> Control:
	var existing := host.get_node_or_null("ProceduralAtmosphere") as Control
	if existing != null:
		return existing
	var view := new()
	view.name = "ProceduralAtmosphere"
	view.profile = context
	host.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return view

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	phase = float(Time.get_ticks_msec()) / 1000.0
	shader_material = ShaderMaterial.new()
	shader_material.shader = AtmosphereShader
	material = shader_material
	shader_material.set_shader_parameter("strength", 0.45 if profile == "gameplay" else (0.8 if profile == "library" else 1.0))
	resized.connect(_update_aspect)
	_update_aspect()
	shader_material.set_shader_parameter("phase", phase)

func _update_aspect() -> void:
	if shader_material != null:
		shader_material.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))

func _process(delta: float) -> void:
	if not motion_enabled or not is_visible_in_tree() or get_tree().paused:
		return
	# Gameplay already pauses the owning renderer for pause/countdown/results.
	if profile == "gameplay" and not get_parent().is_processing():
		return
	phase += delta
	shader_material.set_shader_parameter("phase", phase)

func set_motion_enabled(enabled: bool) -> void:
	motion_enabled = enabled
