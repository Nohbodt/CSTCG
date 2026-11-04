extends SceneTree

const World = preload("res://scripts/spatial/dust_world.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Map artwork capture requires a graphical renderer.")
		quit(1)
		return
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1080, 680)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world = World.new()
	viewport.add_child(world)
	await world.navigation_ready
	world.get_node("UploadedMapGeometry").material_override.albedo_color = Color("607b86")
	for node in world.get_children():
		if node is WorldEnvironment:
			node.environment.background_color = Color("0b1017")
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 127
	camera.far = 500
	camera.position = Vector3(65, 110, 85)
	world.add_child(camera)
	camera.look_at(Vector3(0, 3, 0))
	camera.current = true
	for id in ["site_a", "site_b"]:
		var label = Label3D.new()
		label.text = "A" if id == "site_a" else "B"
		label.position = world.landmark(id) + Vector3.UP * 5
		label.font_size = 70
		label.pixel_size = 0.07
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = Color("f37645")
		world.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://assets/ui")
	var error = viewport.get_texture().get_image().save_png("res://assets/ui/dust2_preview.png")
	print("CSTCG_MENU_MAP: ", error_string(error))
	quit(0 if error == OK else 1)
