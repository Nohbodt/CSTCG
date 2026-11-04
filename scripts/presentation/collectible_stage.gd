class_name CollectibleStage
extends Control
## Visual-only stage. Secured inventory and reveal progress belong to Game.

signal animation_finished(kind: String)

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
const Pack = preload("res://scripts/pack_art.gd")
const Card = preload("res://scripts/card_art.gd")
const FOIL = preload("res://scripts/presentation/foil.gdshader")
const PRINT = preload("res://scripts/presentation/printed_foil.gdshader")

var mode = "pack" # pack, opening, card
var pack_id = "contender"
var cards: Array = []
var new_flags: Array = []
var revealed = 0
var sealed = true
var reduced_motion = false
var use_3d = true
var sound_enabled = true
var phase = "idle"
var last_animation = ""
var flair = 0
var clock = 0.0
var charge = 0.0
var burst = 0.0
var foil_phase = 0.0
var cursor = Vector2.ZERO
var active_tween: Tween
var viewport: SubViewport
var view: SubViewportContainer
var world: Node3D
var rig: Node3D
var pack_root: Node3D
var seam: Node3D
var card_roots: Array[Node3D] = []
var shards: Array[MeshInstance3D] = []
var foil_materials: Array[ShaderMaterial] = []
var printed_materials: Array[ShaderMaterial] = []
var fallback: Control
var tint = U.BLUE
var pending_target = 0
var light: OmniLight3D
var audio: AudioStreamPlayer
var camera: Camera3D
var static_frames = 4

static func fragment_count(level: int) -> int:
	return 8 + level * 6

func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(180, 240))
	clip_contents = true
	add_to_group("collectible_stages")
	flair = int(C.PACKS[pack_id].get("flair", 0))
	if mode == "card":
		flair = int(C.card(cards[0]).rarity)
	tint = C.PACKS[pack_id].color if mode != "card" else C.COLORS[C.card(cards[0]).rarity]
	_build()
	resized.connect(_resize_view)
	gui_input.connect(_pointer_input)
	mouse_exited.connect(func(): cursor = Vector2.ZERO)

func _build() -> void:
	if not use_3d or DisplayServer.get_name() == "headless":
		_build_fallback()
		return
	view = SubViewportContainer.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.stretch = true
	add_child(view)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = U.BG
	environment.environment.background_energy_multiplier = 0.0
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b3a2df")
	environment.environment.ambient_light_energy = 0.85
	world.add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0, 0.2, 12)
	camera.size = 4.2 if mode != "card" else 3.5
	camera.near = 0.05
	camera.far = 40
	camera.current = true
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, -35, 0)
	key.light_color = Color("e4deff")
	key.light_energy = 1.4
	world.add_child(key)
	light = OmniLight3D.new()
	light.position = Vector3(2, 1, 3)
	light.light_color = tint
	light.omni_range = 9
	light.light_energy = 2.0
	world.add_child(light)
	var rim = OmniLight3D.new()
	rim.position = Vector3(-3, -1, 2)
	rim.light_color = U.RED
	rim.light_energy = 2.8
	rim.omni_range = 10
	world.add_child(rim)
	rig = Node3D.new()
	world.add_child(rig)
	if mode != "card":
		_build_pack()
	_build_cards()
	_build_fragments()
	if mode == "opening" and not sealed:
		_set_fan()
	if mode == "card":
		card_roots[0].scale = Vector3.ONE * 1.15
		card_roots[0].rotation_degrees = Vector3(-3, -9, -2)
	_resize_view()
	queue_redraw()

func _solid(color: Color, metallic: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.32
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material

func _foil(color: Color) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = FOIL
	material.set_shader_parameter("tint", color)
	foil_materials.append(material)
	return material

func _box(parent: Node3D, extent: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = extent
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func _printed_texture(art: Control, extent: Vector2i) -> SubViewport:
	var canvas = SubViewport.new()
	canvas.size = extent
	canvas.transparent_bg = true
	canvas.disable_3d = true
	canvas.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.add_child(canvas)
	art.size = Vector2(extent)
	canvas.add_child(art)
	return canvas

func _print(parent: Node3D, texture: Texture2D, extent: Vector2, z: float) -> MeshInstance3D:
	var front = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = extent
	front.mesh = quad
	front.position.z = z
	var material = ShaderMaterial.new()
	material.shader = PRINT
	material.set_shader_parameter("print_texture", texture)
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("strength", 0.13 + flair * 0.065)
	printed_materials.append(material)
	front.material_override = material
	parent.add_child(front)
	return front

func _build_pack() -> void:
	pack_root = Node3D.new()
	rig.add_child(pack_root)
	pack_root.rotation_degrees = Vector3(-3, -11, -3)
	# A dimensional pouch with raised foil facets and a separate tearable crimp.
	_box(pack_root, Vector3(2.32, 3.25, 0.16), Vector3(0, -0.08, 0), _foil(tint))
	for side in [-1, 1]:
		var fold = _box(pack_root, Vector3(0.10, 3.22, 0.11), Vector3(side * 1.14, -0.08, 0.09), _foil(tint.lerp(U.TEXT, 0.25)))
		fold.rotation_degrees.y = side * 20
	var art = Pack.new()
	art.pack_id = pack_id
	art.animate = false
	var canvas = _printed_texture(art, Vector2i(720, 960))
	_print(pack_root, canvas.get_texture(), Vector2(2.42, 3.42), 0.12)
	seam = Node3D.new()
	seam.position = Vector3(0, 1.63, 0.04)
	pack_root.add_child(seam)
	_box(seam, Vector3(2.4, 0.16, 0.12), Vector3.ZERO, _foil(tint))
	for i in range(24):
		_box(seam, Vector3(0.025, 0.14, 0.025), Vector3(-1.14 + i * 0.1, 0, 0.08), _solid(tint.lerp(U.TEXT, 0.55), 0.6))
	_box(pack_root, Vector3(2.38, 0.12, 0.1), Vector3(0, -1.72, 0), _foil(tint))
	_box(world, Vector3(3.6, 0.10, 1.3), Vector3(0, -1.93, -0.1), _solid(Color("221635"), 0.6))
	_box(world, Vector3(3.58, 0.018, 0.035), Vector3(0, -1.87, 0.56), _solid(tint.darkened(0.35), 0.0, true))
	if flair > 0:
		# The Elite crest is raised, faceted geometry rather than printed glow.
		var vertices = PackedVector3Array()
		for i in range(10):
			var a = -PI * 0.5 + i * PI / 5
			var b = -PI * 0.5 + (i + 1) * PI / 5
			vertices.append(Vector3(0, 0.20, 0.33))
			vertices.append(Vector3(cos(a), -sin(a), 0) * (0.47 if i % 2 == 0 else 0.2) + Vector3(0, 0.20, 0.17))
			vertices.append(Vector3(cos(b), -sin(b), 0) * (0.47 if (i + 1) % 2 == 0 else 0.2) + Vector3(0, 0.20, 0.17))
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for vertex in vertices:
			surface.add_vertex(vertex)
		surface.generate_normals()
		var crest = MeshInstance3D.new()
		crest.mesh = surface.commit()
		crest.material_override = _foil(tint.lerp(U.TEXT, 0.6))
		pack_root.add_child(crest)

func _build_cards() -> void:
	if mode == "pack":
		return
	var back = Card.new()
	back.face_down = true
	var back_texture = _printed_texture(back, Vector2i(380, 580)).get_texture()
	for i in range(cards.size()):
		var node = Node3D.new()
		rig.add_child(node)
		card_roots.append(node)
		node.set_meta("index", i)
		_box(node, Vector3(1.52, 2.32, 0.055), Vector3.ZERO, _foil(U.PURPLE))
		var art = Card.new()
		art.card = C.card(cards[i])
		art.fresh = new_flags[i] if i < new_flags.size() else false
		var texture = _printed_texture(art, Vector2i(380, 580)).get_texture()
		_print(node, texture, Vector2(1.52, 2.32), 0.031)
		var rear = _print(node, back_texture, Vector2(1.52, 2.32), -0.031)
		rear.rotation.y = PI
		node.rotation.y = 0 if i < revealed else PI
		node.visible = mode == "card" or not sealed

func _build_fragments() -> void:
	for i in range(fragment_count(flair)):
		var fragment = _box(world, Vector3(0.025, 0.35 + (i % 4) * 0.12, 0.025), Vector3.ZERO, _solid(tint if i % 3 else U.RED, 0.0, true))
		shards.append(fragment)
		fragment.visible = false

func _build_fallback() -> void:
	fallback = Control.new()
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)
	if mode == "pack" or (mode == "opening" and sealed):
		var pack = Pack.new()
		pack.pack_id = pack_id
		pack.animate = false
		pack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.add_child(pack)
	else:
		var row = U.hbox(12)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.add_child(row)
		for i in range(cards.size()):
			var art = Card.new()
			art.compact = true
			art.card = C.card(cards[i])
			art.face_down = i >= revealed
			art.fresh = new_flags[i] if i < new_flags.size() else false
			row.add_child(art)

func _refresh_fallback() -> void:
	if is_instance_valid(fallback):
		remove_child(fallback)
		fallback.queue_free()
		_build_fallback()

func _resize_view() -> void:
	if is_instance_valid(viewport):
		if mode == "opening" and not sealed:
			camera.size = _fan_camera_size()
	static_frames = 4
	queue_redraw()

func _pointer_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not reduced_motion:
		cursor = (event.position / size - Vector2.ONE * 0.5) * 2.0

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if reduced_motion and phase == "idle" and static_frames <= 0:
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	clock += delta
	if is_instance_valid(rig) and not reduced_motion:
		rig.rotation.y = lerp_angle(rig.rotation.y, cursor.x * 0.12, minf(1.0, delta * 7))
		rig.rotation.x = lerp_angle(rig.rotation.x, cursor.y * 0.055, minf(1.0, delta * 7))
		if phase == "idle" and (mode == "pack" or sealed):
			rig.position.y = sin(clock * 1.1) * 0.035
	if is_instance_valid(viewport):
		# Freeze an idle reduced-motion stage after the first texture update.
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if phase != "idle" or not reduced_motion or static_frames > 0 else SubViewport.UPDATE_DISABLED
		static_frames = maxi(0, static_frames - 1)
		for material in foil_materials:
			material.set_shader_parameter("energy", charge + burst)
			material.set_shader_parameter("phase", foil_phase + (0.0 if reduced_motion else clock * 0.15))
		for material in printed_materials:
			material.set_shader_parameter("phase", rig.rotation.y * 3 + (0.0 if reduced_motion else clock * 0.22))
		light.light_energy = 2.0 + charge * 3.0 + burst * 2.5
		for i in range(shards.size()):
			var fragment = shards[i]
			fragment.visible = (charge + burst > 0.05) and not reduced_motion
			var angle = i * TAU / shards.size() + clock * (0.7 + flair * 0.15)
			var radius = 1.8 + burst * 1.5 + (i % 3) * 0.13
			fragment.position = Vector3(cos(angle) * radius, sin(angle) * (1.2 + burst), 0.4 + sin(angle * 2) * 0.4)
			fragment.rotation.z = angle - PI * 0.25
			fragment.scale.y = 0.5 + charge + burst
	queue_redraw()

func _draw() -> void:
	draw_style_box(U.box(Color("100b1d"), 8, Color("3a2554"), 0), Rect2(Vector2.ZERO, size))
	# The floor grid, chromatic silhouettes and shards sit behind legible prints.
	var horizon = size.y * 0.85
	for i in range(9):
		var x = size.x * i / 8.0
		draw_line(Vector2(size.x * 0.5, size.y * 0.35), Vector2(x, size.y), Color(U.PURPLE, 0.08), 1)
	for i in range(4):
		var y = horizon + i * 11
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(U.BLUE, 0.08), 1)
	draw_line(Vector2(size.x * 0.18, horizon), Vector2(size.x * 0.82, horizon), Color(tint, 0.3), 1)
	if not reduced_motion and charge + burst > 0.05:
		for i in range(5 + flair * 3):
			var x = fposmod(i * 93.0 + clock * 64, maxf(1, size.x))
			var y = size.y * (0.2 + fposmod(i * 0.137, 0.55))
			draw_rect(Rect2(x, y, 8 + i % 5 * 4, 2), Color(U.RED if i % 2 else tint, minf(0.65, (charge + burst) * 0.5)))

func play_open() -> void:
	if phase != "idle" or not sealed:
		return
	phase = "opening"
	last_animation = "open"
	_play_sound("pack_tear" if flair == 0 or reduced_motion else "elite_charge")
	if reduced_motion:
		_finish_animation()
		return
	active_tween = create_tween()
	var anticipation = 0.16 + flair * 0.23
	active_tween.tween_property(self, "charge", 1.0, anticipation).set_trans(Tween.TRANS_CUBIC)
	if is_instance_valid(pack_root):
		active_tween.parallel().tween_property(pack_root, "rotation_degrees:y", 9.0 + flair * 8.0, anticipation)
		active_tween.tween_property(seam, "position", Vector3(0.75, 2.22, 0.65), 0.28).set_trans(Tween.TRANS_CUBIC)
		active_tween.parallel().tween_property(seam, "rotation_degrees:z", -28.0, 0.28)
		active_tween.tween_callback(func():
			for i in range(card_roots.size()):
				card_roots[i].visible = true
				card_roots[i].scale = Vector3.ONE * 0.6
				card_roots[i].position = Vector3(0, 0.25, -0.4 - i * 0.01))
		active_tween.tween_property(pack_root, "position", Vector3(0, -3.5, -1), 0.4)
		active_tween.parallel().tween_property(pack_root, "scale", Vector3.ONE * 0.7, 0.4)
		active_tween.parallel().tween_property(camera, "size", _fan_camera_size(), 0.5)
		for i in range(card_roots.size()):
			active_tween.parallel().tween_property(card_roots[i], "position", _fan_position(i), 0.48).set_delay(i * 0.025).set_trans(Tween.TRANS_BACK)
			active_tween.parallel().tween_property(card_roots[i], "scale", Vector3.ONE, 0.48).set_delay(i * 0.025)
			active_tween.parallel().tween_property(card_roots[i], "rotation_degrees:z", _fan_roll(i), 0.48)
	else:
		active_tween.tween_interval(0.78)
	active_tween.tween_property(self, "charge", 0.0, 0.18 + flair * 0.06)
	active_tween.tween_callback(_finish_animation)

func reveal_to(target: int) -> void:
	if phase != "idle":
		return
	pending_target = clampi(target, revealed, cards.size())
	phase = "revealing"
	last_animation = "reveal"
	if reduced_motion:
		_play_sound("card_reveal")
		_finish_animation()
		return
	active_tween = create_tween()
	for i in range(revealed, pending_target):
		var rarity = int(C.card(cards[i]).rarity)
		active_tween.tween_callback(_play_sound.bind("card_reveal", 0.95 + rarity * 0.06))
		var duration = 0.28 + rarity * 0.08 + flair * 0.045
		active_tween.tween_property(self, "burst", 0.22 + rarity * 0.2 + flair * 0.12, 0.08)
		if i < card_roots.size():
			var root = card_roots[i]
			active_tween.tween_property(root, "rotation:y", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			active_tween.parallel().tween_property(root, "scale", Vector3.ONE * 1.07, duration * 0.5)
			active_tween.tween_property(root, "scale", Vector3.ONE, duration * 0.5)
		else:
			active_tween.tween_interval(duration)
		active_tween.tween_property(self, "burst", 0.0, 0.1)
	active_tween.tween_callback(_finish_animation)

func _fan_position(index: int) -> Vector3:
	return Vector3((index - (cards.size() - 1) * 0.5) * 1.68, -0.08, 0.0)

func _fan_roll(index: int) -> float:
	return (index - (cards.size() - 1) * 0.5) * -1.4

func _fan_camera_size() -> float:
	return maxf(2.95, (cards.size() * 1.68 + 0.5) * size.y / maxf(1, size.x))

func _set_fan() -> void:
	if is_instance_valid(pack_root):
		pack_root.visible = false
	for i in range(card_roots.size()):
		card_roots[i].visible = true
		card_roots[i].position = _fan_position(i)
		card_roots[i].rotation_degrees = Vector3(0, 0 if i < revealed else 180, _fan_roll(i))
		card_roots[i].scale = Vector3.ONE
	sealed = false
	if is_instance_valid(camera):
		camera.size = _fan_camera_size() if mode == "opening" else 3.5
	static_frames = 4

func skip_animation() -> void:
	if phase == "idle":
		return
	if active_tween:
		active_tween.kill()
	if is_instance_valid(audio):
		audio.stop()
	_finish_animation()

func _finish_animation() -> void:
	if not is_inside_tree() or phase == "idle":
		return
	var completed = last_animation
	if completed == "reveal":
		revealed = pending_target
	_set_fan()
	phase = "idle"
	charge = 0.0
	burst = 0.0
	_refresh_fallback()
	animation_finished.emit(completed)

func set_motion_reduced(value: bool) -> void:
	reduced_motion = value
	cursor = Vector2.ZERO
	if value:
		skip_animation()
		if is_instance_valid(rig):
			rig.rotation = Vector3.ZERO
	queue_redraw()
	static_frames = 4

func set_3d_enabled(value: bool) -> void:
	if use_3d == value:
		return
	skip_animation()
	use_3d = value
	for node in get_children():
		remove_child(node)
		node.queue_free()
	viewport = null
	view = null
	world = null
	rig = null
	pack_root = null
	seam = null
	camera = null
	fallback = null
	audio = null
	card_roots.clear()
	shards.clear()
	foil_materials.clear()
	printed_materials.clear()
	_build()

func _play_sound(id: String, pitch: float = 1.0) -> void:
	if not sound_enabled or DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(audio):
		audio = AudioStreamPlayer.new()
		audio.volume_db = -9
		add_child(audio)
	audio.stream = load("res://assets/audio/" + id + ".wav")
	audio.pitch_scale = pitch
	audio.play()

func _exit_tree() -> void:
	if active_tween:
		active_tween.kill()
	phase = "closed"
