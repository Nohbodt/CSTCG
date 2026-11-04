extends SceneTree

const World = preload("res://scripts/spatial/dust_world.gd")
const Probe = preload("res://scripts/spatial/route_probe.gd")
const PAIRS = [["t_spawn", "site_a"], ["t_spawn", "site_b"], ["ct_spawn", "site_a"], ["ct_spawn", "site_b"], ["site_a", "site_b"], ["mid", "catwalk"]]

var checks = 0
var failures = 0
var finished = false
var report: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("SPATIAL FAIL: " + name)

func _run() -> void:
	var timeout = create_timer(15)
	timeout.timeout.connect(func():
		if not finished:
			printerr("SPATIAL FAIL: map initialization timed out")
			quit(1))
	var world = World.new()
	world.navigation_failed.connect(func(reason):
		printerr("SPATIAL FAIL: " + reason)
		quit(1))
	root.add_child(world)
	await world.navigation_ready
	check(world.is_ready, "ready requires usable server navigation")
	check(world.region.navigation_mesh.get_polygon_count() > 0, "nonempty derived navigation")
	check(world.collision_faces.size() / 3 == world.metadata.render_collision_triangles, "collision uses every converted face")
	check(FileAccess.get_sha256("res://assets/maps/dust2/source.stl") == world.metadata.source_sha256, "original source preserved byte for byte")
	check(FileAccess.get_sha256("res://assets/maps/dust2/dust2.obj") == world.metadata.obj_sha256, "converted asset matches manifest")
	for id in world.landmarks:
		var authored = world.landmark(id)
		var nearest = world.closest(authored)
		check(nearest.distance_to(authored) < 0.6, "landmark close to authored surface: " + id)
		check(world.body_clear(nearest), "capsule clearance at: " + id)
		var support = world.floor_at(nearest)
		check(not support.is_empty() and support.normal.y > 0.65, "actual mesh supports: " + id)
	for pair in PAIRS:
		_walk(world, pair[0], pair[1])
		_walk(world, pair[1], pair[0])
	var t = world.floor_at(world.closest(world.landmark("t_spawn"))).position + Vector3.UP * 0.04
	var a = world.floor_at(world.closest(world.landmark("site_a"))).position + Vector3.UP * 0.04
	var eye = Vector3.UP * world.EYE
	check(world.has_sight(t + eye, t + eye + Vector3.RIGHT), "local clear eye-height sightline")
	check(not world.has_sight(t + eye, a + eye), "intervening walls block T to A sightline")
	var blocked = world.ray(t + eye, a + eye)
	check(blocked.has("position") and blocked.collider == world.static_body, "blocked ray reports real mesh hit")
	var mid = world.floor_at(world.closest(world.landmark("mid"))).position
	check(not world.has_sight(mid - Vector3.UP * 0.5, mid + eye), "a floor blocks vertical sight instead of flattening levels")
	check(not world.body_clear(mid - Vector3.UP * 0.5), "a capsule cannot occupy the floor solid")
	var high = world.map_mesh.get_aabb().end.y + 3.0
	check(world.has_sight(Vector3(t.x, high, t.z), Vector3(a.x, high, a.z)), "ray query has no artificial universal distance cutoff")
	check(world.route(t, Vector3(500, 500, 500)).is_empty(), "void destinations are rejected instead of snapped across the map")
	check(world.route(Vector3(500, 500, 500), a).is_empty(), "void starts are rejected")
	print("CSTCG_SPATIAL_ROUTES: ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	finished = true
	print("CSTCG_SPATIAL_TESTS: %d checks, 12 collision-walked routes, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _walk(world: Node3D, from_id: String, to_id: String) -> void:
	var title = from_id + " -> " + to_id
	var path = world.route(world.landmark(from_id), world.landmark(to_id))
	check(not path.is_empty(), "connected route: " + title)
	if path.is_empty():
		return
	var probe = Probe.new()
	probe.world = world
	world.add_child(probe)
	probe.set_physics_process(false)
	var support = world.floor_at(path[0])
	check(not support.is_empty(), "route start has support: " + title)
	if support.is_empty():
		probe.free()
		return
	probe.position = support.position + Vector3.UP * 0.04
	probe.set_route(path)
	var max_step = 0.0
	for _tick in range(15000):
		var previous = probe.position
		probe.advance(1.0 / 60.0)
		var moved = probe.position - previous
		var horizontal = Vector2(moved.x, moved.z).length()
		max_step = maxf(max_step, absf(moved.y))
		check(horizontal <= probe.speed / 60.0 + 0.001, "bounded horizontal movement")
		check(absf(moved.y) <= world.MAX_STEP + 0.041, "no vertical teleport")
		check(world.body_clear(probe.position), "player capsule remains outside map collision")
		if probe.completed or not probe.blocked_reason.is_empty():
			break
	check(probe.completed, "probe reaches destination: " + title + " / " + probe.blocked_reason)
	check(probe.position.distance_to(path[-1]) < 0.65, "arrival matches requested level: " + title)
	report.append({"from": from_id, "to": to_id, "completed": probe.completed,
		"seconds": snappedf(probe.elapsed, 0.01), "distance": snappedf(probe.travelled, 0.01),
		"max_vertical_step": snappedf(max_step, 0.001)})
	probe.free()
