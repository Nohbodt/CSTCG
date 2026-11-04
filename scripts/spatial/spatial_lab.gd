extends Control

const U = preload("res://scripts/ui.gd")
const World = preload("res://scripts/spatial/dust_world.gd")
const Probe = preload("res://scripts/spatial/route_probe.gd")
const MAIN = "res://scenes/main.tscn"
const LABELS = ["t_spawn", "ct_spawn", "site_a", "site_b", "mid", "catwalk", "a_long", "tunnels"]

var world: DustWorld
var camera: Camera3D
var viewport: SubViewport
var view: SubViewportContainer
var status: Label
var inspector: Label
var metrics: Label
var sight_status: Label
var from_select: OptionButton
var to_select: OptionButton
var probe_select: OptionButton
var nav_checkbox: CheckButton
var camera_button: Button
var pause_button: Button
var probes: Array = []
var selected_index = 0
var route_visual: Node3D
var sight_visual: Node3D
var navigation_visual: MeshInstance3D
var preview_path = PackedVector3Array()
var angled = false
var running = true
var focus = Vector3(0, 5, 0)
var zoom = 118.0
var sight_start = Vector3.ZERO
var has_sight_start = false
var smoke_failures = 0

func _ready() -> void:
	theme = U.theme()
	_build_ui()
	world = World.new()
	viewport.add_child(world)
	world.navigation_ready.connect(_world_ready)
	world.navigation_failed.connect(func(reason): status.text = reason)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 400
	world.add_child(camera)
	camera.current = true
	_update_camera()

func _build_ui() -> void:
	var background = ColorRect.new()
	background.color = U.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 22)
	add_child(margin)
	var shell = U.vbox(16)
	margin.add_child(shell)
	var header = U.hbox(16)
	var titles = U.vbox(3)
	titles.add_child(U.label("CSTCG / MAP TOOLS", 10, U.ORANGE, true))
	titles.add_child(U.label("DUST II / SPATIAL LAB", 28, U.TEXT, true))
	header.add_child(titles)
	header.add_child(U.spacer())
	header.add_child(U.badge("USER-SUPPLIED STL", U.LIME))
	header.add_child(U.button("Back to club   →", func(): get_tree().change_scene_to_file(MAIN)))
	shell.add_child(header)
	var layout = U.hbox(16)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(layout)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_FILL
	layout.add_child(scroll)
	var controls = U.vbox(15)
	controls.custom_minimum_size.x = 282
	scroll.add_child(controls)
	status = U.paragraph("Importing geometry and validating navigation…", 12, U.LIME)
	controls.add_child(U.panel(status))
	controls.add_child(U.section("01 / ROUTE PREVIEW"))
	from_select = _selector(["T SPAWN", "CT SPAWN", "A SITE", "B SITE", "MID", "CATWALK", "A LONG", "TUNNELS"])
	controls.add_child(U.label("FROM", 10, U.MUTED, true))
	controls.add_child(from_select)
	to_select = _selector(["T SPAWN", "CT SPAWN", "A SITE", "B SITE", "MID", "CATWALK", "A LONG", "TUNNELS"])
	to_select.selected = 2
	controls.add_child(U.label("TO", 10, U.MUTED, true))
	controls.add_child(to_select)
	from_select.item_selected.connect(func(_index): _preview())
	to_select.item_selected.connect(func(_index): _preview())
	metrics = U.paragraph("Route metrics appear after the map is ready.", 12)
	controls.add_child(metrics)
	controls.add_child(U.button("Reset & walk route   →", _walk_preview, true))
	controls.add_child(U.button("Deploy 5 + 5 probes", _deploy))
	controls.add_child(U.section("02 / INSPECT A PROBE"))
	probe_select = _selector(["No probes deployed"])
	probe_select.item_selected.connect(func(index): _select_probe(index))
	controls.add_child(probe_select)
	inspector = U.paragraph("Ten movement probes. No combat or match rewards are generated in this lab.", 12)
	controls.add_child(U.panel(inspector))
	controls.add_child(U.section("03 / VIEW & SIGHTLINES"))
	camera_button = U.button("View: Overhead   [V]", _toggle_camera)
	controls.add_child(camera_button)
	pause_button = U.button("Pause movement   [Space]", _toggle_running)
	controls.add_child(pause_button)
	nav_checkbox = CheckButton.new()
	nav_checkbox.text = "Navigation overlay"
	nav_checkbox.toggled.connect(func(value):
		if is_instance_valid(navigation_visual):
			navigation_visual.visible = value)
	controls.add_child(nav_checkbox)
	controls.add_child(U.button("Reset camera   [F]", func():
		focus = Vector3(0, 5, 0)
		zoom = 118
		_update_camera()))
	sight_status = U.paragraph("Shift-click two surfaces to test an eye-height sightline. Green: clear. Red: blocked by geometry.", 11)
	controls.add_child(U.panel(sight_status))
	controls.add_child(U.paragraph("Left-click: select a probe or send it to a connected surface.\nMiddle-drag: pan. Wheel: zoom.\nMarkers and scale are provisional authoring settings.", 10))
	view = SubViewportContainer.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.stretch = true
	view.mouse_default_cursor_shape = Control.CURSOR_CROSS
	layout.add_child(view)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	view.add_child(viewport)
	view.gui_input.connect(_view_input)
	var footer = U.hbox()
	footer.add_child(U.label("COLLISION + NAVIGATION + EYE-LEVEL RAYS", 10, U.MUTED, true))
	footer.add_child(U.spacer())
	footer.add_child(U.label("GEOMETRY TEST SCENE / NO MATCH SIMULATION", 10, U.ORANGE, true))
	shell.add_child(footer)

func _selector(items: Array) -> OptionButton:
	var node = OptionButton.new()
	node.custom_minimum_size.y = 42
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		node.add_item(item)
	return node

func _world_ready() -> void:
	status.text = "%d FACES\n%d navigation polygons · %.2fs bake" % [world.metadata.render_collision_triangles, world.region.navigation_mesh.get_polygon_count(), world.bake_seconds]
	_add_landmarks()
	_make_navigation_overlay()
	_deploy()
	_preview()
	if "--spatial-smoke" in OS.get_cmdline_user_args():
		call_deferred("_smoke")

func _update_camera() -> void:
	if not is_instance_valid(camera):
		return
	camera.size = zoom * (1.2 if angled else 1.0)
	if angled:
		camera.position = focus + Vector3(65, 95, 85)
		camera.look_at(focus, Vector3.UP)
	else:
		camera.position = focus + Vector3(0, 130, 0)
		camera.look_at(focus, Vector3.FORWARD)

func _toggle_camera() -> void:
	angled = not angled
	camera_button.text = "View: Angled   [V]" if angled else "View: Overhead   [V]"
	_update_camera()

func _toggle_running() -> void:
	running = not running
	pause_button.text = "Pause movement   [Space]" if running else "Resume movement   [Space]"
	for probe in probes:
		probe.paused = not running

func _add_landmarks() -> void:
	for id in world.landmarks:
		var definition = world.landmarks[id]
		var position = world.closest(world.landmark(id))
		var node = Node3D.new()
		node.position = position
		world.add_child(node)
		var label = Label3D.new()
		label.text = definition.name
		label.font = U.BOLD
		label.font_size = 40
		label.pixel_size = 0.05
		label.position.y = 2.6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = U.LIME if id.begins_with("site") else Color("c9d4dd")
		node.add_child(label)
		if definition.kind.begins_with("spawn") or definition.kind == "site":
			var mesh = MeshInstance3D.new()
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 1.4 if definition.kind == "site" else 2.2
			cylinder.bottom_radius = cylinder.top_radius
			cylinder.height = 0.06
			mesh.mesh = cylinder
			mesh.position.y = 0.1
			mesh.material_override = _material(Color(U.LIME if definition.kind == "site" else U.ORANGE, 0.35), true)
			node.add_child(mesh)

func _material(color: Color, xray: bool = false) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = xray
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _make_navigation_overlay() -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(Color("69adf390"), true))
	var vertices = world.region.navigation_mesh.get_vertices()
	for i in range(world.region.navigation_mesh.get_polygon_count()):
		var polygon = world.region.navigation_mesh.get_polygon(i)
		for edge in range(polygon.size()):
			mesh.surface_add_vertex(vertices[polygon[edge]] + Vector3.UP * 0.12)
			mesh.surface_add_vertex(vertices[polygon[(edge + 1) % polygon.size()]] + Vector3.UP * 0.12)
	mesh.surface_end()
	navigation_visual = MeshInstance3D.new()
	navigation_visual.mesh = mesh
	navigation_visual.visible = false
	world.add_child(navigation_visual)

func _preview() -> void:
	if not is_instance_valid(world) or not world.is_ready:
		return
	var start = world.landmark(LABELS[from_select.selected])
	var goal = world.landmark(LABELS[to_select.selected])
	preview_path = world.route(start, goal)
	if is_instance_valid(route_visual):
		route_visual.queue_free()
	route_visual = Node3D.new()
	world.add_child(route_visual)
	if preview_path.is_empty():
		metrics.text = "No connected, player-clear route to this seed."
		return
	var length = 0.0
	for i in range(1, preview_path.size()):
		length += preview_path[i].distance_to(preview_path[i - 1])
	_draw_line(route_visual, preview_path, U.ORANGE, true)
	metrics.text = "%.1f game units · %d corners\n%.1fs at test speed 5.0" % [length, preview_path.size(), length / 5.0]

func _draw_line(parent: Node3D, points: PackedVector3Array, color: Color, xray: bool = false, lift: float = 0.2) -> void:
	if points.size() < 2:
		return
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(color, xray))
	for i in range(1, points.size()):
		mesh.surface_add_vertex(points[i - 1] + Vector3.UP * lift)
		mesh.surface_add_vertex(points[i] + Vector3.UP * lift)
	mesh.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	parent.add_child(instance)

func _new_probe(team: int, number: int, feet: Vector3) -> Node3D:
	var probe = Probe.new()
	probe.world = world
	probe.team = team
	probe.number = number
	probe.handle = "%s%02d" % ["T" if team == 0 else "CT", number]
	probe.position = feet
	probe.paused = not running
	world.add_child(probe)
	probes.append(probe)
	return probe

func _spawn_positions(spawn: String, count: int) -> Array:
	var center = world.closest(world.landmark(spawn))
	var positions: Array = []
	for ring in range(5):
		for z in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				var test = center + Vector3(x, 0, z) * 1.1
				var nearest = world.closest(test)
				if test.distance_to(nearest) > 0.6 or world.route(center, nearest).is_empty():
					continue
				var ground = world.floor_at(nearest)
				if ground.is_empty():
					continue
				var feet = ground.position + Vector3.UP * 0.04
				if not world.body_clear(feet):
					continue
				if positions.any(func(p): return p.distance_to(feet) < 0.95):
					continue
				positions.append(feet)
				if positions.size() == count:
					return positions
	return positions

func _deploy() -> void:
	if not is_instance_valid(world) or not world.is_ready:
		return
	for probe in probes:
		probe.free()
	probes.clear()
	probe_select.clear()
	for team in range(2):
		var positions = _spawn_positions("t_spawn" if team == 0 else "ct_spawn", 5)
		for i in range(positions.size()):
			var probe = _new_probe(team, i + 1, positions[i])
			probe_select.add_item("%s / movement probe" % probe.handle)
	if not probes.is_empty():
		_select_probe(0)
	else:
		inspector.text = "No clear probe spawn positions were found."

func _select_probe(index: int) -> void:
	if index < 0 or index >= probes.size():
		return
	selected_index = index
	probe_select.selected = index
	for i in range(probes.size()):
		probes[i].selected = i == index

func _walk_preview() -> void:
	if probes.is_empty() or preview_path.is_empty():
		return
	var probe = probes[selected_index]
	# Reset is an explicit authoring operation; traversal itself never teleports.
	var floor_hit = world.floor_at(preview_path[0])
	if floor_hit.is_empty():
		return
	probe.position = floor_hit.position + Vector3.UP * 0.04
	probe.set_route(preview_path)
	probe.paused = not running

func _view_input(event: InputEvent) -> void:
	if not is_instance_valid(world) or not world.is_ready:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		focus += Vector3(-event.relative.x, 0, -event.relative.y) * camera.size / maxf(1, view.size.y)
		_update_camera()
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom = clampf(zoom * (0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 20, 180)
		_update_camera()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.shift_pressed:
		var nearest_probe = -1
		var nearest_distance = 15.0
		for i in range(probes.size()):
			var point = camera.unproject_position(probes[i].position + Vector3.UP)
			var distance = point.distance_to(event.position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_probe = i
		if nearest_probe >= 0:
			_select_probe(nearest_probe)
			return
	var origin = camera.project_ray_origin(event.position)
	var hit = world.ray(origin, origin + camera.project_ray_normal(event.position) * 400)
	if hit.is_empty():
		return
	var target = world.closest(hit.position)
	if target.distance_to(hit.position) > 0.75:
		sight_status.text = "Choose a walkable surface close to the navigation overlay."
		return
	if event.shift_pressed:
		_probe_sight(target)
	elif not probes.is_empty():
		var probe = probes[selected_index]
		var path = world.route(probe.position, target)
		if path.is_empty():
			sight_status.text = "That surface is not connected to the selected probe."
		else:
			probe.set_route(path)

func _probe_sight(feet: Vector3) -> void:
	var ground = world.floor_at(feet)
	if ground.is_empty():
		sight_status.text = "No actual floor at this point. Choose another surface."
		return
	var point = ground.position + Vector3.UP * (0.04 + world.EYE)
	if not has_sight_start:
		sight_start = point
		has_sight_start = true
		sight_status.text = "Eye position set. Shift-click the second surface."
		return
	has_sight_start = false
	if is_instance_valid(sight_visual):
		sight_visual.queue_free()
	sight_visual = Node3D.new()
	world.add_child(sight_visual)
	var collision = world.ray(sight_start, point)
	var clear = collision.is_empty()
	var sight_color = U.LIME if clear else Color("ee6f77")
	_draw_line(sight_visual, PackedVector3Array([sight_start, point]), sight_color, true, 0.0)
	if not clear:
		var marker = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		marker.mesh = sphere
		marker.position = collision.position
		marker.material_override = _material(sight_color, true)
		sight_visual.add_child(marker)
	sight_status.text = ("CLEAR" if clear else "BLOCKED BY GEOMETRY") + "\n%.1f game units · eye height %.2f" % [sight_start.distance_to(point), world.EYE]

func _process(_delta: float) -> void:
	if probes.is_empty():
		return
	var probe = probes[selected_index]
	var state = "ARRIVED" if probe.completed else ("BLOCKED: " + probe.blocked_reason if not probe.blocked_reason.is_empty() else ("WALKING" if probe.path.size() > 0 else "READY"))
	inspector.text = "%s / %s\n%.1f units travelled · %.1fs\nPosition %.1f / %.1f / %.1f\nRadius %.2f · height %.2f" % [probe.handle, state, probe.travelled, probe.elapsed, probe.position.x, probe.position.y, probe.position.z, world.RADIUS, world.HEIGHT]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_V: _toggle_camera()
		KEY_SPACE: _toggle_running()
		KEY_F:
			focus = Vector3(0, 5, 0)
			zoom = 118
			_update_camera()

func _smoke() -> void:
	if not "--ephemeral" in OS.get_cmdline_user_args():
		printerr("Spatial smoke requires --ephemeral.")
		get_tree().quit(1)
		return
	var club_before = Game.data.duplicate(true)
	_smoke_check(probes.size() == 10, "ten clear spawn probes")
	_press("Deploy 5 + 5 probes")
	_smoke_check(probes.size() == 10, "deployment button replaces the group")
	_smoke_check(not preview_path.is_empty(), "initial T to A preview")
	await get_tree().process_frame
	await _capture("dust2-overhead")
	pause_button.pressed.emit()
	_smoke_check(probes.all(func(p): return p.paused), "pause controls all probes")
	pause_button.pressed.emit()
	_press("Reset & walk route   →")
	probes[0].set_physics_process(false)
	for _tick in range(15000):
		probes[0].advance(1.0 / 60.0)
		if probes[0].completed or not probes[0].blocked_reason.is_empty():
			break
	_smoke_check(probes[0].completed, "route traversal from viewer control")
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = camera.unproject_position(probes[9].position + Vector3.UP)
	view.gui_input.emit(click)
	_smoke_check(selected_index == 9, "viewport click selects nearest probe")
	from_select.selected = 1
	from_select.item_selected.emit(1)
	to_select.selected = 3
	to_select.item_selected.emit(3)
	_smoke_check(not preview_path.is_empty(), "CT to B preview")
	click.shift_pressed = true
	click.position = camera.unproject_position(world.closest(world.landmark("t_spawn")))
	view.gui_input.emit(click)
	click.position = camera.unproject_position(world.closest(world.landmark("site_a")))
	view.gui_input.emit(click)
	_smoke_check(sight_status.text.begins_with("BLOCKED"), "occluded sightline feedback")
	camera_button.pressed.emit()
	await get_tree().process_frame
	await _capture("dust2-angled")
	nav_checkbox.button_pressed = true
	await get_tree().process_frame
	await _capture("dust2-navigation")
	_smoke_check(Game.data == club_before, "lab does not alter cards, rewards, or saved club")
	print("CSTCG_SPATIAL_UI: ten probes, previews, route walk, sightline, cameras; %d failures" % smoke_failures)
	get_tree().quit(0 if smoke_failures == 0 else 1)

func _press(text: String) -> void:
	var button = _find_button(self, text)
	_smoke_check(button != null, "button exists: " + text)
	if button != null:
		button.pressed.emit()

func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_button(child, text)
		if result != null:
			return result
	return null

func _smoke_check(condition: bool, name: String) -> void:
	if not condition:
		smoke_failures += 1
		printerr("SPATIAL UI FAIL: " + name)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			var directory = argument.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(directory)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))
