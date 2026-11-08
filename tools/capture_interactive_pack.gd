extends SceneTree
## Captures the real application using viewport-routed mouse input.

var app: Control
var opening: Control
var frame = 0
var directory = "/tmp/cstcg-interactive-pack"

func _initialize() -> void:
	call_deferred("_record")

func _mouse(point: Vector2, pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func _motion(point: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)

func _capture(label: String = "") -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var captured = root.get_texture().get_image()
	assert(captured.save_png(directory.path_join("frame%04d.png" % frame)) == OK)
	if not label.is_empty():
		assert(captured.save_png(directory.path_join(label + ".png")) == OK)
	frame += 1

func _record() -> void:
	if not "--ephemeral" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Recording requires --ephemeral and a graphical renderer.")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):
			directory = arg.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1440, 960)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var game = root.get_node("Game")
	assert(not game.save_enabled)
	game.rng.seed = 731
	assert(game.purchase_pack("elite"))
	app.pack_sound = false
	app._open_pack("elite")
	for i in range(5):
		await process_frame
	opening = app.modal.find_child("PackOpening", true, false)
	var stage = opening.stage
	var secured = game.data.pending_pack.duplicate(true)
	var rng_state = game.rng.state
	for i in range(15):
		await _capture("sealed" if i == 0 else "")
	var rect: Rect2 = stage.pack_rect()
	var start = rect.position + rect.size * Vector2(0.12, 0.08)
	_mouse(stage.get_global_transform_with_canvas() * start, true)
	await process_frame
	assert(stage.gesture.held, "Wrapper did not receive a viewport-routed mouse press.")
	for i in range(46):
		_motion(stage.get_global_transform_with_canvas() * (start + Vector2(rect.size.x * 0.82 * 0.43 * i / 45.0, 0)))
		await _capture("tear-low" if i == 22 else "")
	_mouse(stage.get_global_transform_with_canvas() * (start + Vector2(rect.size.x * 0.82 * 0.43, 0)), false)
	await process_frame
	assert(stage.sealed and stage.phase == "idle" and stage.tear_progress > 0.4, "Mouse release did not preserve a paused tear.")
	for i in range(15):
		await _capture("paused" if i == 7 else "")
	rect = stage.pack_rect()
	start = rect.position + rect.size * Vector2(0.12, 0.08)
	var partial: float = stage.tear_progress
	_mouse(stage.get_global_transform_with_canvas() * start, true)
	for i in range(61):
		_motion(stage.get_global_transform_with_canvas() * (start + Vector2(rect.size.x * 0.82 * (1.0 - partial) * i / 60.0, 0)))
		await _capture("tear-bright" if i == 50 else "")
	_mouse(stage.get_global_transform_with_canvas() * (start + Vector2(rect.size.x, 0)), false)
	for i in range(80):
		await _capture("burst" if i == 3 else "")
	assert(not stage.sealed and stage.phase == "idle" and stage.revealed == 0)
	opening._reveal(true)
	for i in range(190):
		await _capture("revealed" if i == 180 else "")
	assert(game.data.pending_pack.cards == secured.cards and game.rng.state == rng_state)
	assert(stage.revealed == 5)
	print("CSTCG_INTERACTIVE_CAPTURE: %d frames; real mouse drag, pause, resume and reveal; secured contents/RNG preserved" % frame)
	quit(0)
