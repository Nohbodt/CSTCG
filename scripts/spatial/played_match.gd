extends Control

const U = preload("res://scripts/ui.gd")
const World = preload("res://scripts/spatial/dust_world.gd")
const Live = preload("res://scripts/spatial/spatial_match_sim.gd")
const MAIN = "res://scenes/main.tscn"
const TEAM_COLORS = [Color("c4df86"), Color("69adf3")]
const SPEEDS = [1, 2, 4, 8, 16]

var world: DustWorld
var sim: SpatialMatchSim
var camera: Camera3D
var viewport: SubViewport
var view: SubViewportContainer
var status: Label
var score_label: Label
var clock_label: Label
var bomb_label: Label
var phase_label: Label
var feed: RichTextLabel
var pause_button: Button
var speed_button: Button
var camera_button: Button
var retry_button: Button
var return_button: Button
var roster_rows: Array = []
var actor_nodes: Array = []
var actor_labels: Array = []
var actor_rings: Array = []
var effects: Array = []
var smoke_nodes: Array = []
var bomb_node: MeshInstance3D
var selected = -1
var focus = Vector3(0, 3, 0)
var zoom = 48.0
var angled = true
var follow_action = true
var speed_index = 3
var paused = false
var accumulator = 0.0
var between_rounds = 0.0
var pending_checkpoint = false
var pending_result: Dictionary = {}
var settled: Dictionary = {}
var is_smoke = false
var smoke_failures = 0
var captured = false

func _ready() -> void:
	theme = U.theme()
	is_smoke = "--live-match-smoke" in OS.get_cmdline_user_args()
	_build_ui()
	if not Game.has_active_match():
		status.text = "No match is in progress. Return to the club to choose your next fixture."
		return
	world = World.new()
	viewport.add_child(world)
	world.navigation_ready.connect(_start)
	world.navigation_failed.connect(func(reason): status.text = reason)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 450
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
		margin.add_theme_constant_override("margin_" + edge, 18)
	add_child(margin)
	var shell = U.vbox(12)
	margin.add_child(shell)
	var header = U.hbox(18)
	var title = U.vbox(3)
	title.add_child(U.label("C / C    THE OPEN CIRCUIT", 10, U.ORANGE, true))
	title.add_child(U.label("DUST II", 28, U.TEXT, true))
	header.add_child(title)
	header.add_child(U.spacer())
	score_label = U.label("NORTHLINE   00 : 00", 29, TEAM_COLORS[0], true)
	header.add_child(score_label)
	header.add_child(U.spacer())
	return_button = U.button("Return to club   →", _return_to_club)
	return_button.tooltip_text = "Your completed rounds are saved. Returning resumes at the start of the current round."
	header.add_child(return_button)
	shell.add_child(header)
	var ribbon = U.hbox(22)
	phase_label = U.label("PREPARING THE SERVER", 12, U.TEXT, true)
	ribbon.add_child(phase_label)
	ribbon.add_child(U.spacer())
	bomb_label = U.label("BOMB / CARRIED", 12, U.ORANGE, true)
	ribbon.add_child(bomb_label)
	clock_label = U.label("01:40", 22, U.TEXT, true)
	ribbon.add_child(clock_label)
	shell.add_child(U.panel(ribbon, U.SURFACE, 12))
	var layout = U.hbox(12)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(layout)
	var map_column = U.vbox(8)
	layout.add_child(map_column)
	view = SubViewportContainer.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.stretch = true
	map_column.add_child(view)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	view.add_child(viewport)
	view.gui_input.connect(_view_input)
	var tools_row = U.hbox(8)
	pause_button = U.button("Pause   [Space]", _toggle_pause)
	tools_row.add_child(pause_button)
	speed_button = U.button("Speed: 8×", _cycle_speed)
	tools_row.add_child(speed_button)
	camera_button = U.button("View: Angled   [V]", _toggle_camera)
	tools_row.add_child(camera_button)
	tools_row.add_child(U.button("Follow action", _follow_action))
	tools_row.add_child(U.button("Whole map   [F]", _whole_map))
	map_column.add_child(tools_row)
	var sidebar_scroll = ScrollContainer.new()
	sidebar_scroll.custom_minimum_size.x = 260
	sidebar_scroll.size_flags_horizontal = Control.SIZE_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(sidebar_scroll)
	var sidebar = U.vbox(8)
	sidebar.custom_minimum_size.x = 248
	sidebar_scroll.add_child(sidebar)
	for team in range(2):
		sidebar.add_child(U.section("NORTHLINE" if team == 0 else "OPPOSITION"))
		for slot in range(5):
			var index = team * 5 + slot
			var button = U.button("Loading player…", func(): _select(index))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_size_override("font_size", 11)
			button.custom_minimum_size.y = 49
			sidebar.add_child(button)
			roster_rows.append(button)
		if team == 0:
			sidebar.add_child(U.divider())
	status = U.paragraph("Loading Dust II…", 11, U.MUTED)
	sidebar.add_child(status)
	retry_button = U.button("Retry save", _retry_save, true)
	retry_button.visible = false
	sidebar.add_child(retry_button)
	var feed_column = U.vbox(5)
	feed_column.add_child(U.section("LIVE MATCH FEED", "FULL MATCH REWARDS"))
	feed = RichTextLabel.new()
	feed.bbcode_enabled = true
	feed.custom_minimum_size.y = 94
	feed.add_theme_font_size_override("normal_font_size", 12)
	feed.scroll_following = true
	feed_column.add_child(feed)
	shell.add_child(U.panel(feed_column, U.SURFACE, 12))
	shell.add_child(U.label("Wheel: zoom   ·   Middle-drag: pan   ·   Select a player to follow   ·   Lime: your club / Blue: opposition", 10, U.MUTED))

func _start() -> void:
	var active = Game.data.active_match
	sim = Live.new()
	sim.configure(world, active.snapshot, active.checkpoint)
	sim.event_created.connect(_event)
	sim.shot_created.connect(_shot)
	sim.round_finished.connect(_round_finished)
	sim.match_finished.connect(_match_finished)
	_create_markers()
	status.text = "Automatic match · %s\nCompleted rounds save automatically.\nExit resumes this round from its start." % _tactic_name()
	sim.start_next_round()
	focus = sim.actors[0].position
	_update_camera()
	if is_smoke:
		if Game.save_enabled:
			get_tree().quit(1)
			return
		_toggle_pause()
		_smoke_check(paused, "pause control")
		_toggle_pause()
		_toggle_camera()
		_toggle_camera()
		_cycle_speed()
		_smoke_check(SPEEDS[speed_index] == 16 and angled, "speed and camera controls")
	_update_display()

func _tactic_name() -> String:
	return ["Balanced", "Fast execute", "Map control"][int(Game.data.active_match.snapshot.tactic)]

func _material(color: Color, xray: bool = false) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = xray
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _create_markers() -> void:
	for id in sim.sites:
		var site = sim.sites[id]
		var marker = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = site.radius
		cylinder.bottom_radius = site.radius
		cylinder.height = 0.035
		marker.mesh = cylinder
		marker.position = site.position + Vector3.UP * 0.03
		marker.material_override = _material(Color(U.ORANGE, 0.2))
		world.add_child(marker)
		var label = Label3D.new()
		label.text = "A" if id == "site_a" else "B"
		label.font = U.BOLD
		label.font_size = 64
		label.pixel_size = 0.06
		label.position = site.position + Vector3.UP * 2.8
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = U.ORANGE
		world.add_child(label)
	for i in range(10):
		var actor = Node3D.new()
		world.add_child(actor)
		var body = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.35
		capsule.height = 1.8
		body.mesh = capsule
		body.position.y = 0.9
		body.material_override = _material(TEAM_COLORS[int(i / 5)])
		body.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		actor.add_child(body)
		var gun = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.12, 0.15, 0.85)
		gun.mesh = box
		gun.position = Vector3(0.3, 1.25, -0.55)
		gun.material_override = _material(U.TEXT)
		actor.add_child(gun)
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.65
		torus.outer_radius = 0.82
		ring.mesh = torus
		ring.position.y = 0.15
		ring.material_override = _material(TEAM_COLORS[int(i / 5)], true)
		actor.add_child(ring)
		actor_rings.append(ring)
		var label = Label3D.new()
		label.font = U.BOLD
		label.font_size = 32
		label.pixel_size = 0.035
		label.position.y = 3.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = TEAM_COLORS[int(i / 5)]
		actor.add_child(label)
		actor_labels.append(label)
		actor_nodes.append(actor)
	bomb_node = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.65, 0.3, 0.5)
	bomb_node.mesh = box
	bomb_node.material_override = _material(U.ORANGE, true)
	world.add_child(bomb_node)

func _process(delta: float) -> void:
	if sim == null:
		return
	if not paused and not sim.finished and not pending_checkpoint:
		if sim.phase == "round_end":
			between_rounds -= delta
			if between_rounds <= 0:
				sim.start_next_round()
		else:
			accumulator += minf(delta, 0.15) * SPEEDS[speed_index]
			var steps = 220 if is_smoke else mini(48, int(accumulator / Live.DT))
			for _tick in range(steps):
				sim.step()
				if not is_smoke:
					accumulator -= Live.DT
				if sim.phase in ["round_end", "finished"]:
					accumulator = 0
					break
	_update_display()
	for i in range(effects.size() - 1, -1, -1):
		effects[i].left -= delta
		if effects[i].left <= 0:
			effects[i].node.queue_free()
			effects.remove_at(i)
	if selected >= 0 and selected < sim.actors.size() and sim.actors[selected].alive:
		focus = focus.lerp(sim.actors[selected].position, minf(1, delta * 5))
		_update_camera()
	elif follow_action and not sim.actors.is_empty():
		var target = sim.bomb.position
		var engagements = sim.actors.filter(func(a): return a.alive and not a.visible.is_empty())
		if not engagements.is_empty():
			target = engagements[0].position
		elif sim.bomb.status == "carried":
			target = sim.actors[sim.bomb.carrier].position
		focus = focus.lerp(target, minf(1, delta * 3))
		_update_camera()
	if is_smoke and sim.finished and not settled.is_empty():
		_smoke_check(Game.data.matches == 1 and not Game.has_active_match(), "complete match settles once")
		_smoke_check(settled.mode == "played" and settled.reward in [85, 160], "full rewards")
		print("CSTCG_LIVE_UI: chooser, Dust II scene, ten agents, playback controls, complete match, saved rewards; %d failures" % smoke_failures)
		set_process(false)
		get_tree().quit(0 if smoke_failures == 0 else 1)

func _update_display() -> void:
	if sim.actors.is_empty():
		return
	score_label.text = "NORTHLINE   %02d : %02d   %s" % [sim.score[0], sim.score[1], sim.snapshot.opponent.tag]
	phase_label.text = "ROUND %02d  /  %s  /  NORTHLINE ON %s" % [sim.round_number, "BUY PHASE" if sim.phase == "buy" else ("OVERTIME" if sim.round_number > 24 else "REGULATION"), "T" if sim.t_team == 0 else "CT"]
	var seconds = maxf(0, Live.ROUND_SECONDS - sim.round_time)
	if sim.bomb.status == "planted":
		seconds = sim.bomb.time_left
	clock_label.text = "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	bomb_label.text = "BOMB / " + str(sim.bomb.status).to_upper()
	if sim.bomb.defuser >= 0:
		bomb_label.text += " / DEFUSING %.1fs" % sim.bomb.defuse_time
	for i in range(10):
		var actor = sim.actors[i]
		actor_nodes[i].position = actor.position
		if actor.facing.length() > 0.01:
			actor_nodes[i].rotation.y = atan2(-actor.facing.x, -actor.facing.z)
		actor_nodes[i].visible = actor.alive
		actor_labels[i].text = actor.profile.handle + ("  ◈" if sim.bomb.status == "carried" and sim.bomb.carrier == i else "")
		actor_rings[i].scale = Vector3.ONE * (1.5 if selected == i else 1.0)
		roster_rows[i].text = "%s   %d / %d\n%s · %s · $%d" % [actor.profile.handle, sim.totals[i].kills, sim.totals[i].deaths, "%d HP" % actor.hp if actor.alive else "OUT", Live.WEAPONS[actor.weapon].name, actor.cash]
		roster_rows[i].add_theme_color_override("font_color", TEAM_COLORS[actor.team] if actor.alive else U.MUTED)
		roster_rows[i].tooltip_text = actor.profile.name + " · " + actor.profile.role + "\n" + actor.intent + (" · FLASHED" if actor.blind > 0 else "")
	bomb_node.position = sim.bomb.position + Vector3.UP * 0.35
	bomb_node.visible = sim.bomb.status in ["dropped", "planted"]
	while smoke_nodes.size() < sim.smokes.size():
		var mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 3.4
		sphere.height = 6.8
		mesh.mesh = sphere
		mesh.material_override = _material(Color("a9b0b3a0"))
		world.add_child(mesh)
		smoke_nodes.append(mesh)
	for i in range(smoke_nodes.size()):
		smoke_nodes[i].visible = i < sim.smokes.size()
		if i < sim.smokes.size():
			smoke_nodes[i].position = sim.smokes[i].position
	if not settled.is_empty():
		phase_label.text = "VICTORY" if settled.won else "DEFEAT"
		clock_label.text = "FINAL"
		bomb_label.text = "+%d CR / +%d XP" % [settled.reward, settled.xp]

func _event(event: Dictionary) -> void:
	var color = TEAM_COLORS[int(event.get("team", 0))] if event.kind == "kill" else U.MUTED
	feed.append_text("[color=#%s]R%02d  %s[/color]\n" % [color.to_html(false), event.round, event.text])
	if event.kind == "kill" and not captured:
		captured = true
		if is_smoke:
			focus = Vector3(event.position[0], event.position[1], event.position[2])
			_update_camera()
		call_deferred("_capture")

func _shot(start: Vector3, finish: Vector3, team: int, hit: bool) -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(TEAM_COLORS[team] if hit else Color("b5a283")))
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(finish)
	mesh.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	world.add_child(instance)
	effects.append({"node": instance, "left": 0.12})

func _round_finished(_summary: Dictionary) -> void:
	pending_checkpoint = not Game.checkpoint_match(sim.snapshot.id, sim.checkpoint())
	between_rounds = 0.0 if is_smoke else 1.5
	if pending_checkpoint:
		paused = true
		status.text = "Could not save the completed round. Retry to continue. " + Game.last_error
		retry_button.visible = true

func _match_finished(result: Dictionary) -> void:
	pending_result = result
	_settle()

func _settle() -> void:
	settled = Game.complete_spatial_match(pending_result)
	if settled.is_empty():
		paused = true
		status.text = "Match complete. Rewards could not be saved. Retry before leaving. " + Game.last_error
		retry_button.visible = true
		return_button.disabled = true
		return
	pending_result = {}
	status.text = "MATCH COMPLETE\n+%d CR · +%d XP saved\nMVP: %s · %d eliminations" % [settled.reward, settled.xp, sim.actors[sim.snapshot.squad.find(settled.mvp)].profile.handle, settled.kills[settled.mvp]]
	if not settled.earned_pack.is_empty():
		status.text += "\nPACK REWARD: " + ("CONTENDER + ELITE" if settled.earned_pack == "both" else "CONTENDER")
	return_button.disabled = false
	return_button.text = "Collect & return   →"
	retry_button.visible = false
	pause_button.disabled = true

func _retry_save() -> void:
	if not pending_result.is_empty():
		_settle()
	elif pending_checkpoint and Game.checkpoint_match(sim.snapshot.id, sim.checkpoint()):
		pending_checkpoint = false
		paused = false
		retry_button.visible = false
		status.text = "Round saved. Match continues."

func _toggle_pause() -> void:
	if sim != null and sim.finished:
		return
	if pending_checkpoint:
		return
	paused = not paused
	pause_button.text = "Resume   [Space]" if paused else "Pause   [Space]"

func _cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	speed_button.text = "Speed: %d×" % SPEEDS[speed_index]

func _toggle_camera() -> void:
	angled = not angled
	camera_button.text = "View: Angled   [V]" if angled else "View: Overhead   [V]"
	_update_camera()

func _whole_map() -> void:
	selected = -1
	follow_action = false
	focus = Vector3(0, 3, 0)
	zoom = 122
	_update_camera()

func _select(index: int) -> void:
	selected = index
	follow_action = false
	zoom = 42
	if sim != null and sim.actors.size() > index:
		focus = sim.actors[index].position
	_update_camera()

func _follow_action() -> void:
	selected = -1
	follow_action = true
	zoom = 48
	_update_camera()

func _update_camera() -> void:
	if not is_instance_valid(camera):
		return
	camera.size = zoom * (1.15 if angled else 1.0)
	camera.position = focus + (Vector3(65, 95, 85) if angled else Vector3(0, 150, 0))
	camera.look_at(focus, Vector3.UP if angled else Vector3.FORWARD)

func _view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(15, zoom * 0.85)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(185, zoom * 1.15)
		_update_camera()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		selected = -1
		follow_action = false
		focus += Vector3(-event.relative.x, 0, -event.relative.y) * zoom / maxf(1, view.size.y)
		_update_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE:
			_toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			_toggle_camera()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F:
			_whole_map()
			get_viewport().set_input_as_handled()

func _return_to_club() -> void:
	if not pending_result.is_empty() or pending_checkpoint:
		return
	get_tree().change_scene_to_file(MAIN)

func _smoke_check(ok: bool, description: String) -> void:
	if not ok:
		smoke_failures += 1
		printerr("LIVE UI FAIL: " + description)

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			var directory = arg.trim_prefix("--capture-dir=")
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(directory)
			get_viewport().get_texture().get_image().save_png(directory.path_join("10_dust2_live.png"))
