extends SceneTree
## Generate the actual extruded wordmark used by the lightweight menu shell.
const U = preload("res://scripts/ui.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Brand capture requires a graphical renderer.")
		quit(1)
		return
	var viewport = SubViewport.new()
	viewport.size = Vector2i(960, 320)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.7
	camera.position = Vector3(0, 0.2, 10)
	camera.current = true
	viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -30, 0)
	light.light_color = U.BLUE
	light.light_energy = 2.8
	viewport.add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 50, 0)
	fill.light_color = U.RED
	fill.light_energy = 1.4
	viewport.add_child(fill)
	for i in range(3):
		var text = TextMesh.new()
		text.text = "CSTCG"
		text.font = U.DISPLAY
		text.font_size = 96
		text.pixel_size = 0.014
		text.depth = 0.18
		var mesh = MeshInstance3D.new()
		mesh.mesh = text
		mesh.position = Vector3((i - 1) * 0.035, -0.12, 0.1 if i == 1 else 0)
		mesh.rotation_degrees = Vector3(-5, -10, 0)
		var material = StandardMaterial3D.new()
		material.albedo_color = U.TEXT if i == 1 else (U.BLUE if i == 0 else U.RED)
		material.metallic = 0.5 if i == 1 else 0
		material.roughness = 0.25
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.25
		mesh.material_override = material
		viewport.add_child(mesh)
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var error = viewport.get_texture().get_image().save_png("res://assets/ui/phase_shift_brand.png")
	print("CSTCG_BRAND: ", error_string(error))
	quit(0 if error == OK else 1)
