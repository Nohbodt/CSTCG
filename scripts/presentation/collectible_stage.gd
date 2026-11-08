class_name CollectibleStage
extends Control
## Visual-only stage. Secured inventory and reveal progress belong to Game.

signal animation_finished(kind: String)
signal opening_step_changed(step: String)
signal open_requested
signal tear_interaction(progress: float, active: bool)

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
const Pack = preload("res://scripts/pack_art.gd")
const Card = preload("res://scripts/card_art.gd")
const Back = preload("res://scripts/card_back_art.gd")
const FOIL = preload("res://scripts/presentation/foil.gdshader")
const PRINT = preload("res://scripts/presentation/printed_foil.gdshader")
const FX = preload("res://scripts/presentation/opening_effects.gd")
const Gesture = preload("res://scripts/presentation/pack_gesture.gd")
const EDGE = preload("res://scripts/presentation/edge_glow.gdshader")
const BACKDROP = preload("res://scripts/presentation/studio_backdrop.gdshader")

var mode = "pack" # pack, opening, card
var pack_id = "contender"
var cards: Array = []
var new_flags: Array = []
var back_origins: Array = []
var viewing_back = false
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
var opening_step = "idle"
var tear_progress = 0.0
var explosion_age = -1.0
var flip_age = -1.0
var flip_origin = Vector3.ZERO
var flip_color = U.BLUE
var seam_segments: Array[Node3D] = []
var effects: Node3D
var rip_line: MeshInstance3D
var edge_materials: Array[ShaderMaterial] = []
var gesture = Gesture.new()
var pointer_source = -2 # -1 mouse; nonnegative touch index
var interaction_overlay: Control

static func fragment_count(level: int) -> int:
	return 8 + level * 6

func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(180, 240))
	clip_contents = true
	add_to_group("collectible_stages")
	flair = int(C.PACKS[pack_id].get("flair", 0))
	if mode == "card":
		flair = int(C.card(cards[0]).rarity)
	if back_origins.is_empty():
		for id in cards:
			back_origins.append(pack_id if mode == "opening" else "legacy")
	tint = C.PACKS[pack_id].color if mode != "card" else C.COLORS[C.card(cards[0]).rarity]
	_build()
	resized.connect(_resize_view)
	gui_input.connect(_pointer_input)
	mouse_exited.connect(func(): cursor = Vector2.ZERO)
	if mode == "opening":
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _build() -> void:
	if not use_3d or DisplayServer.get_name() == "headless":
		_build_fallback()
		_build_overlay()
		return
	view = SubViewportContainer.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.stretch = true
	add_child(view)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	# Additive halos need an opaque composition target to retain their light
	# outside the pouch/card silhouette in the GL renderer.
	viewport.transparent_bg = false
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var backdrop = MeshInstance3D.new()
	var backdrop_quad = QuadMesh.new()
	backdrop_quad.size = Vector2(30, 16)
	backdrop.mesh = backdrop_quad
	backdrop.position.z = -3.0
	var backdrop_material = ShaderMaterial.new()
	backdrop_material.shader = BACKDROP
	backdrop_material.set_shader_parameter("tint", tint)
	backdrop.material_override = backdrop_material
	world.add_child(backdrop)
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
	camera.size = (4.6 if mode == "opening" else 4.2) if mode != "card" else 3.5
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
	if mode == "opening":
		effects = FX.new()
		effects.level = flair
		effects.tint = tint
		world.add_child(effects)
	if mode == "opening" and not sealed:
		_set_fan()
	if mode == "card":
		card_roots[0].scale = Vector3.ONE * 1.15
		card_roots[0].rotation_degrees = Vector3(-3, 171 if viewing_back else -9, -2)
	_resize_view()
	_build_overlay()
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

func _print(parent: Node3D, texture: Texture2D, extent: Vector2, z: float, protect_portrait: bool = false) -> MeshInstance3D:
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
	material.set_shader_parameter("portrait_protection", 1.0 if protect_portrait else 0.0)
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
	art.printed_crimps = false
	var canvas = _printed_texture(art, Vector2i(720, 960))
	_print(pack_root, canvas.get_texture(), Vector2(2.42, 3.42), 0.12)
	seam = Node3D.new()
	seam.position = Vector3(0, 1.63, 0.04)
	pack_root.add_child(seam)
	var crimp_material = _foil(tint)
	var ridge_material = _solid(tint.lerp(U.TEXT, 0.55), 0.6)
	for i in range(24):
		var segment = Node3D.new()
		segment.position.x = -1.15 + i * 0.1
		seam.add_child(segment)
		seam_segments.append(segment)
		_box(segment, Vector3(0.1, 0.16, 0.12), Vector3.ZERO, crimp_material)
		_box(segment, Vector3(0.025, 0.14, 0.025), Vector3(0, 0, 0.08), ridge_material)
		# The underside becomes visible as each section curls away from the pouch.
		_box(segment, Vector3(0.10, 0.24, 0.014), Vector3(0, -0.07, -0.04), _foil(Color("c4d3ee")))
	rip_line = _box(pack_root, Vector3(1, 0.018, 0.02), Vector3(-1.2, 1.54, 0.19), _solid(tint.lerp(U.TEXT, 0.6), 0.0, true))
	rip_line.visible = false
	_edge_strip(pack_root, Vector2(2.5, 0.28), Vector3(0, 1.54, 0.24), true)
	_edge_strip(seam, Vector2(2.5, 0.22), Vector3(0, -0.06, 0.20), true)
	for side in [-1, 1]:
		var edge = _edge_strip(pack_root, Vector2(3.2, 0.14), Vector3(side * 1.18, -0.08, 0.19), false)
		edge.rotation.z = PI * 0.5
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
	var back_textures: Dictionary = {}
	for i in range(cards.size()):
		var origin = str(back_origins[i])
		if not back_textures.has(origin):
			var back = Card.new()
			back.face_down = true
			back.back_origin = origin
			back_textures[origin] = _printed_texture(back, Vector2i(380, 580)).get_texture()
		var node = Node3D.new()
		rig.add_child(node)
		card_roots.append(node)
		node.set_meta("index", i)
		_box(node, Vector3(1.52, 2.32, 0.055), Vector3.ZERO, _foil(U.PURPLE))
		var art = Card.new()
		art.card = C.card(cards[i])
		art.fresh = new_flags[i] if i < new_flags.size() else false
		var texture = _printed_texture(art, Vector2i(380, 580)).get_texture()
		_print(node, texture, Vector2(1.52, 2.32), 0.031, true)
		var rear = _print(node, back_textures[origin], Vector2(1.52, 2.32), -0.031)
		rear.material_override.set_shader_parameter("tint", Back.style(origin).color)
		rear.rotation.y = PI
		node.rotation.y = 0 if i < revealed else PI
		node.visible = mode == "card" or not sealed

func _edge_strip(parent: Node3D, extent: Vector2, position: Vector3, torn: bool) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = extent
	mesh.mesh = quad
	mesh.position = position
	var material = ShaderMaterial.new()
	material.shader = EDGE
	material.set_shader_parameter("tint", tint)
	material.set_meta("torn", torn)
	mesh.material_override = material
	edge_materials.append(material)
	parent.add_child(mesh)
	return mesh

func _build_fragments() -> void:
	for i in range(fragment_count(flair)):
		var foil = i % 3 == 0
		var extent = Vector3(0.17 + (i % 2) * 0.12, 0.3, 0.014) if foil else Vector3(0.025, 0.35 + (i % 4) * 0.12, 0.025)
		var material: Material = _foil(Color("bfcbea")) if foil else _solid(tint if i % 2 else U.RED, 0.0, true)
		var fragment = _box(world, extent, Vector3.ZERO, material)
		fragment.set_meta("foil", foil)
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
			art.face_down = viewing_back if mode == "card" else i >= revealed
			art.back_origin = str(back_origins[i])
			art.fresh = new_flags[i] if i < new_flags.size() else false
			row.add_child(art)

func _refresh_fallback() -> void:
	if is_instance_valid(fallback):
		remove_child(fallback)
		fallback.queue_free()
		_build_fallback()
		if is_instance_valid(interaction_overlay):
			move_child(interaction_overlay, get_child_count() - 1)

func _build_overlay() -> void:
	interaction_overlay = Control.new()
	interaction_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interaction_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_overlay.draw.connect(_draw_interaction_overlay.bind(interaction_overlay))
	add_child(interaction_overlay)

func _draw_interaction_overlay(canvas: Control) -> void:
	canvas.draw_style_box(U.box(Color.TRANSPARENT, 8, U.BLUE if has_focus() else Color("3a2554"), 0), Rect2(Vector2.ZERO, size))
	if mode != "opening" or not sealed:
		return
	var rect = pack_rect()
	var from = rect.position + Vector2(rect.size.x * 0.03, rect.size.y * 0.055)
	var finish = from + Vector2(rect.size.x * 0.94 * tear_progress, 0)
	if not is_instance_valid(viewport) and tear_progress > 0.0:
		for width in [18, 10, 5]:
			canvas.draw_line(from, finish, Color(tint, 0.08 + tear_progress * 0.10), width, true)
		canvas.draw_line(from, finish, tint.lerp(Color.WHITE, tear_progress), 2.0, true)
	if phase in ["idle", "dragging"]:
		var handle = from + Vector2(rect.size.x * 0.94 * tear_progress, 0)
		canvas.draw_circle(handle, 6, Color(tint, 0.24))
		canvas.draw_circle(handle, 2.5, Color.WHITE)
		canvas.draw_line(handle + Vector2(9, -3), handle + Vector2(13, 0), tint, 1.5, true)
		canvas.draw_line(handle + Vector2(13, 0), handle + Vector2(9, 3), tint, 1.5, true)
		var hint = "CONTINUE → / CLICK TO FINISH" if tear_progress > 0 else "CLICK TO OPEN / DRAG →"
		canvas.draw_string(U.BOLD, Vector2(rect.position.x, minf(size.y - 5, rect.end.y + 15)), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, U.MUTED)

func _resize_view() -> void:
	if is_instance_valid(viewport):
		if mode == "opening" and not sealed:
			camera.size = _fan_camera_size()
	static_frames = 4
	queue_redraw()

func _pointer_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not reduced_motion:
		cursor = (event.position / size.max(Vector2.ONE) - Vector2.ONE * 0.5) * 2.0
	if mode != "opening" or not sealed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pointer(event.position, -1)
		elif gesture.held and pointer_source == -1:
			_end_pointer(event.position)
	elif event is InputEventMouseMotion and gesture.held and pointer_source == -1:
		_move_pointer(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_press_pointer(event.position, event.index)
		elif gesture.held and pointer_source == event.index:
			_end_pointer(event.position)
	elif event is InputEventScreenDrag and gesture.held and pointer_source == event.index:
		_move_pointer(event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("ui_accept"):
		if phase in ["idle", "dragging"]:
			_cancel_pointer()
			open_requested.emit()
			accept_event()

func pack_rect() -> Rect2:
	if is_instance_valid(pack_root) and is_instance_valid(camera) and is_instance_valid(viewport):
		var result = Rect2()
		var first = true
		for point in [Vector3(-1.23, -1.80, 0.2), Vector3(1.23, -1.80, 0.2), Vector3(1.23, 1.75, 0.2), Vector3(-1.23, 1.75, 0.2)]:
			var projected = camera.unproject_position(pack_root.to_global(point)) * size / Vector2(viewport.size).max(Vector2.ONE)
			result = Rect2(projected, Vector2.ZERO) if first else result.expand(projected)
			first = false
		return result.intersection(Rect2(Vector2.ZERO, size))
	var extent = Vector2(240, 320) * minf(size.x / 240.0, size.y / 320.0)
	return Rect2((size - extent) * 0.5, extent)

func _press_pointer(position: Vector2, source: int) -> void:
	if phase != "idle" or not sealed or not is_visible_in_tree() or not pack_rect().has_point(position):
		return
	if gesture.press(position, pack_rect().size.x * 0.82):
		pointer_source = source
		grab_focus()
		accept_event()

func _move_pointer(position: Vector2) -> void:
	if not gesture.held or phase not in ["idle", "dragging"]:
		return
	if gesture.motion(position):
		phase = "dragging"
		last_animation = "open"
		_begin_tear()
	static_frames = 4
	if gesture.dragging:
		if not reduced_motion:
			cursor = ((position / size.max(Vector2.ONE) - Vector2.ONE * 0.5) * 2.0).clamp(-Vector2.ONE, Vector2.ONE)
		tear_progress = gesture.progress
		charge = 0.0 if reduced_motion else 0.55 + tear_progress * 0.45
		tear_interaction.emit(tear_progress, true)
		if tear_progress >= 0.995:
			_complete_drag()
	queue_redraw()

func _end_pointer(position: Vector2) -> void:
	if not gesture.held:
		return
	_move_pointer(position)
	if not gesture.held:
		return
	if not gesture.dragging and not pack_rect().has_point(position):
		_cancel_pointer()
		return
	var action = gesture.release(position)
	pointer_source = -2
	if action == "open":
		open_requested.emit()
	elif action == "finish":
		_complete_drag()
	else:
		_pause_drag()

func _pause_drag() -> void:
	if phase != "dragging":
		return
	phase = "idle"
	_set_opening_step("paused")
	if is_instance_valid(audio):
		audio.stop()
	static_frames = 4
	tear_interaction.emit(tear_progress, false)
	queue_redraw()

func _cancel_pointer() -> void:
	gesture.cancel()
	pointer_source = -2
	_pause_drag()

func _complete_drag() -> void:
	if phase != "dragging":
		return
	gesture.cancel()
	pointer_source = -2
	phase = "opening"
	tear_progress = 1.0
	charge = 1.0
	tear_interaction.emit(tear_progress, true)
	if reduced_motion:
		_finish_animation()
		return
	active_tween = create_tween()
	_append_burst(active_tween)

func _input(event: InputEvent) -> void:
	# Continue a captured drag when the pointer leaves the pack or its control.
	if not gesture.held or not is_visible_in_tree():
		return
	if event is InputEventMouseMotion and pointer_source == -1:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_cancel_pointer()
		else:
			_move_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and pointer_source == -1:
		_end_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == pointer_source:
		_move_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed and event.index == pointer_source:
		_end_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and gesture.held:
		_cancel_pointer()

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
	if explosion_age >= 0:
		explosion_age += delta
	if flip_age >= 0:
		flip_age += delta
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
			material.set_shader_parameter("energy", (charge + burst) * (1.0 + flair * 0.3))
			material.set_shader_parameter("phase", foil_phase + (0.0 if reduced_motion else clock * 0.15))
		for material in printed_materials:
			material.set_shader_parameter("phase", rig.rotation.y * 3 + (0.0 if reduced_motion else clock * 0.22))
			material.set_shader_parameter("energy", 0.0 if reduced_motion else charge + burst)
		for material in edge_materials:
			material.set_shader_parameter("progress", tear_progress if material.get_meta("torn") else 1.0)
			material.set_shader_parameter("energy", 0.0 if reduced_motion else 0.06 + charge * 0.35 + pow(tear_progress, 1.7) * (2.0 + flair * 0.5) + burst * 2.5)
		light.light_energy = 2.0 + charge * (3.0 + flair) + burst * (3.0 + flair)
		_update_tear()
		if is_instance_valid(effects):
			var tip = Vector3(-1.2 + tear_progress * 2.4, 1.6, 0.2)
			tip = world.to_local(pack_root.to_global(tip))
			effects.update_fx({"step": opening_step, "charge": charge, "tear": tear_progress,
				"explosion_age": explosion_age, "pulse": burst, "clock": clock, "tip": tip,
				"flip_age": flip_age, "flip_origin": flip_origin, "flip_color": flip_color, "reduced": reduced_motion})
		for i in range(shards.size()):
			var fragment = shards[i]
			fragment.visible = (charge + burst > 0.05) and not reduced_motion and (not fragment.get_meta("foil") or explosion_age >= 0)
			var angle = i * TAU / shards.size() + clock * (0.7 + flair * 0.15)
			var outward = maxf(0, explosion_age)
			var radius = 1.8 + outward * 5.0 + (i % 3) * 0.13
			fragment.position = Vector3(cos(angle) * radius, sin(angle) * (1.2 + outward * 3) - outward * outward, 0.4 + sin(angle * 2) * 0.4)
			fragment.rotation.z = angle - PI * 0.25
			if fragment.get_meta("foil"):
				fragment.rotation.x = clock * 3 + i
				fragment.rotation.y = clock * 4 + i * 0.7
			fragment.scale.y = 0.5 + charge + burst
	queue_redraw()

	if is_instance_valid(interaction_overlay):
		interaction_overlay.queue_redraw()

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
	gesture.cancel()
	pointer_source = -2
	phase = "opening"
	last_animation = "open"
	if reduced_motion:
		_play_sound("card_reveal")
		_finish_animation()
		return
	active_tween = create_tween()
	if tear_progress <= 0.0:
		_set_opening_step("charging")
		if flair > 0:
			_play_sound("elite_charge")
		var anticipation = 0.4 + flair * 0.2
		active_tween.tween_property(self, "charge", 0.6, anticipation).set_trans(Tween.TRANS_SINE)
		if is_instance_valid(pack_root):
			active_tween.parallel().tween_property(pack_root, "rotation_degrees:y", 4.0 + flair * 5.0, anticipation)
			active_tween.parallel().tween_property(pack_root, "rotation_degrees:x", -8.0, anticipation)
	active_tween.tween_callback(_begin_tear)
	var duration = maxf(0.18, (1.35 + flair * 0.35) * (1.0 - tear_progress))
	active_tween.tween_property(self, "tear_progress", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(self, "charge", 1.0, duration)
	_append_burst(active_tween)

func _append_burst(sequence: Tween) -> void:
	sequence.tween_callback(_ignite_burst)
	sequence.tween_property(self, "burst", 1.0 + flair * 0.2, 0.12)
	if is_instance_valid(pack_root):
		sequence.parallel().tween_property(seam, "position", Vector3(0.8, 2.3, 0.6), 0.12)
		sequence.parallel().tween_property(pack_root, "scale", Vector3.ONE * 1.06, 0.12)
	sequence.tween_callback(_start_fan)
	var fan_duration = 0.58 + flair * 0.08
	if is_instance_valid(pack_root):
		sequence.tween_property(pack_root, "position", Vector3(0, -4.2, -1.3), fan_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		sequence.parallel().tween_property(pack_root, "rotation_degrees:z", 32.0, fan_duration)
		sequence.parallel().tween_property(seam, "position", Vector3(2.2, 4.3, 1.2), fan_duration)
		sequence.parallel().tween_property(seam, "rotation_degrees:z", -65.0, fan_duration)
		sequence.parallel().tween_property(camera, "size", _fan_camera_size(), fan_duration)
		for i in range(card_roots.size()):
			sequence.parallel().tween_property(card_roots[i], "position", _fan_position(i), fan_duration).set_delay(i * 0.025).set_trans(Tween.TRANS_BACK)
			sequence.parallel().tween_property(card_roots[i], "scale", Vector3.ONE, fan_duration).set_delay(i * 0.025)
			sequence.parallel().tween_property(card_roots[i], "rotation_degrees:z", _fan_roll(i), fan_duration)
	else:
		sequence.tween_interval(fan_duration + 0.1)
	sequence.parallel().tween_property(self, "burst", 0.0, fan_duration + 0.1)
	sequence.parallel().tween_property(self, "charge", 0.0, fan_duration + 0.1)
	sequence.tween_interval(0.25 + flair * 0.06)
	sequence.tween_callback(_finish_animation)

func _set_opening_step(step: String) -> void:
	opening_step = step
	opening_step_changed.emit(step)

func _begin_tear() -> void:
	_set_opening_step("tearing")
	_play_sound("pack_tear", 2.05 / (1.35 + flair * 0.35))

func _update_tear() -> void:
	if opening_step not in ["tearing", "paused", "bursting"]:
		if is_instance_valid(rip_line):
			rip_line.visible = false
		return
	for i in range(seam_segments.size()):
		var peeled = clampf((tear_progress * (seam_segments.size() + 2) - i) * 0.5, 0.0, 1.0)
		seam_segments[i].position = Vector3(-1.15 + i * 0.1, peeled * (0.30 + 0.16 * sin(i * 0.18)), peeled * 0.38)
		seam_segments[i].rotation_degrees = Vector3(-peeled * 88, peeled * 9, -peeled * 21)
	rip_line.visible = tear_progress > 0.01
	rip_line.scale.x = maxf(0.01, tear_progress * 2.4)
	rip_line.position.x = -1.2 + tear_progress * 1.2

func _ignite_burst() -> void:
	_set_opening_step("bursting")
	explosion_age = 0.0
	_play_sound("elite_burst" if flair > 0 else "pack_burst")

func _start_fan() -> void:
	_set_opening_step("fanning")
	for i in range(card_roots.size()):
		card_roots[i].visible = true
		card_roots[i].scale = Vector3.ONE * 0.28
		card_roots[i].position = Vector3(0, 0.35, -0.4 - i * 0.01)

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
		active_tween.tween_callback(_card_flare.bind(i))
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

func _card_flare(index: int) -> void:
	flip_age = 0.0
	flip_origin = _fan_position(index)
	flip_color = C.COLORS[C.card(cards[index]).rarity]

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
	if phase == "inspecting":
		_finish_inspection()
		return
	_finish_animation()

func inspect_back(value: bool) -> void:
	if mode != "card":
		return
	viewing_back = value
	if active_tween:
		active_tween.kill()
	phase = "inspecting"
	static_frames = 4
	if reduced_motion or card_roots.is_empty():
		_finish_inspection()
		return
	active_tween = create_tween()
	active_tween.tween_property(card_roots[0], "rotation_degrees:y", 171.0 if value else -9.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_callback(_finish_inspection)

func _finish_inspection() -> void:
	if not is_inside_tree():
		return
	if not card_roots.is_empty():
		card_roots[0].rotation_degrees.y = 171 if viewing_back else -9
	phase = "idle"
	static_frames = 4
	_refresh_fallback()

func _finish_animation() -> void:
	if not is_inside_tree() or phase == "idle":
		return
	var completed = last_animation
	if completed == "reveal":
		revealed = pending_target
	_set_fan()
	phase = "idle"
	gesture.reset()
	pointer_source = -2
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	charge = 0.0
	burst = 0.0
	tear_progress = 0.0
	explosion_age = -1.0
	flip_age = -1.0
	_set_opening_step("idle")
	if is_instance_valid(effects):
		effects.visible = false
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
	effects = null
	rip_line = null
	camera = null
	fallback = null
	interaction_overlay = null
	audio = null
	card_roots.clear()
	seam_segments.clear()
	shards.clear()
	foil_materials.clear()
	printed_materials.clear()
	edge_materials.clear()
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
	gesture.cancel()
	pointer_source = -2
