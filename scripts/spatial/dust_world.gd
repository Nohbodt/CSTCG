class_name DustWorld
extends Node3D

signal navigation_ready
signal navigation_failed(reason: String)

const MAP_PATH = "res://assets/maps/dust2/dust2.obj"
const METADATA_PATH = "res://assets/maps/dust2/manifest.json"
const LANDMARK_PATH = "res://assets/maps/dust2/landmarks.json"
const RADIUS = 0.35
const HEIGHT = 1.8
const EYE = 1.55
const MAX_STEP = 0.5
const NAV_RADIUS = 0.5 # Conservative voxel-aligned clearance around a 0.35-radius capsule.
const NAV_HEIGHT = 1.875
const WALL_LAYER = 1

var metadata: Dictionary
var landmarks: Dictionary = {}
var region: NavigationRegion3D
var map_mesh: Mesh
var static_body: StaticBody3D
var collision_faces: PackedVector3Array
var is_ready = false
var bake_seconds = 0.0

func _ready() -> void:
	metadata = JSON.parse_string(FileAccess.get_file_as_string(METADATA_PATH))
	landmarks = JSON.parse_string(FileAccess.get_file_as_string(LANDMARK_PATH)).landmarks
	_build_geometry()
	_build_lighting()
	call_deferred("_bake")

func from_source(point: Array) -> Vector3:
	var origin = metadata.source_origin
	var scale_factor = float(metadata.scale)
	return Vector3((point[0] - origin[0]) * scale_factor,
		(point[2] - origin[2]) * scale_factor, -(point[1] - origin[1]) * scale_factor)

func landmark(id: String) -> Vector3:
	return from_source(landmarks[id].source)

func _build_geometry() -> void:
	map_mesh = load(MAP_PATH)
	var instance = MeshInstance3D.new()
	instance.name = "UploadedMapGeometry"
	instance.mesh = map_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("64766f")
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	add_child(instance)
	static_body = StaticBody3D.new()
	static_body.name = "MapCollision"
	static_body.collision_layer = WALL_LAYER
	static_body.collision_mask = 0
	var collision = CollisionShape3D.new()
	collision_faces = map_mesh.get_faces()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(collision_faces)
	shape.backface_collision = true
	collision.shape = shape
	static_body.add_child(collision)
	add_child(static_body)

func _build_lighting() -> void:
	var environment = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("0c1118")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b6c6d2")
	settings.ambient_light_energy = 0.35
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65, -35, 0)
	sun.light_color = Color("fff2d6")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)

func _bake() -> void:
	var start = Time.get_ticks_msec()
	var navigation = NavigationMesh.new()
	navigation.cell_size = 0.25
	navigation.cell_height = 0.125
	navigation.agent_radius = NAV_RADIUS
	navigation.agent_height = NAV_HEIGHT
	navigation.agent_max_climb = MAX_STEP
	navigation.agent_max_slope = 46.0
	navigation.region_min_size = 1.0
	navigation.region_merge_size = 8.0
	navigation.edge_max_length = 8.0
	navigation.edge_max_error = 1.1
	var geometry = NavigationMeshSourceGeometryData3D.new()
	geometry.add_faces(collision_faces, Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(navigation, geometry)
	region = NavigationRegion3D.new()
	region.name = "DerivedNavigation"
	add_child(region)
	region.set_navigation_map(navigation_map())
	NavigationServer3D.map_set_cell_height(navigation_map(), navigation.cell_height)
	NavigationServer3D.map_set_cell_size(navigation_map(), navigation.cell_size)
	region.navigation_mesh = navigation
	NavigationServer3D.map_set_active(navigation_map(), true)
	# The server synchronizes the region with its world map on physics frames.
	for _frame in range(120):
		if NavigationServer3D.map_get_iteration_id(navigation_map()) > 0:
			if NavigationServer3D.map_get_closest_point_owner(navigation_map(), landmark("t_spawn")).is_valid():
				break
		await get_tree().physics_frame
	if not NavigationServer3D.map_get_closest_point_owner(navigation_map(), landmark("t_spawn")).is_valid():
		navigation_failed.emit("Navigation server did not synchronize the imported map.")
		return
	bake_seconds = (Time.get_ticks_msec() - start) / 1000.0
	is_ready = true
	navigation_ready.emit()

func navigation_map() -> RID:
	return get_world_3d().navigation_map

func closest(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(navigation_map(), point)

func route(start: Vector3, destination: Vector3) -> PackedVector3Array:
	if not is_ready:
		return PackedVector3Array()
	if start.distance_to(closest(start)) > 0.75 or destination.distance_to(closest(destination)) > 0.75:
		return PackedVector3Array()
	var path = NavigationServer3D.map_get_path(navigation_map(), start, destination, true)
	if path.is_empty() or path[-1].distance_to(closest(destination)) > 0.75:
		return PackedVector3Array()
	return path

func ray(start: Vector3, finish: Vector3) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(start, finish, WALL_LAYER)
	query.hit_from_inside = true
	query.hit_back_faces = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func has_sight(start: Vector3, finish: Vector3) -> bool:
	return ray(start, finish).is_empty()

func floor_at(point: Vector3, above: float = 0.5, below: float = 1.0) -> Dictionary:
	return ray(point + Vector3.UP * above, point - Vector3.UP * below)

func supported_feet(point: Vector3) -> Vector3:
	var hit = floor_at(point)
	return hit.position + Vector3.UP * 0.04 if not hit.is_empty() else point

func formation(center: Vector3, count: int) -> Array:
	center = closest(center)
	var positions: Array = []
	for ring in range(6):
		for z in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				var candidate = center + Vector3(x, 0, z) * 1.1
				var nearest = closest(candidate)
				if candidate.distance_to(nearest) > 0.6 or route(center, nearest).is_empty():
					continue
				var hit = floor_at(nearest)
				if hit.is_empty():
					continue
				var feet = hit.position + Vector3.UP * 0.04
				if not body_clear(feet) or positions.any(func(p): return p.distance_to(feet) < 0.95):
					continue
				positions.append(feet)
				if positions.size() == count:
					return positions
	return positions

func trace_route(start: Vector3, destination: Vector3) -> Dictionary:
	# Cacheable physical travel track for a static map. Every sample is checked by
	# the same support/capsule/sweep contract as the interactive route probes.
	var path = route(start, destination)
	if path.is_empty():
		return {"ok": false, "reason": "No connected route"}
	var position = start
	var samples = PackedVector3Array([position])
	var cumulative = PackedFloat32Array([0.0])
	var cursor = 0
	var length = 0.0
	for _tick in range(18000):
		while cursor < path.size():
			var target = path[cursor]
			if Vector2(target.x - position.x, target.z - position.z).length() > 0.02 or absf(target.y - position.y) > MAX_STEP + 0.25:
				break
			cursor += 1
		if cursor >= path.size():
			return {"ok": true, "points": samples, "cumulative": cumulative, "length": length}
		var movement = walk_step(position, path[cursor], 5.0 / 60.0)
		if not movement.ok:
			return {"ok": false, "reason": movement.reason}
		length += position.distance_to(movement.position)
		position = movement.position
		samples.append(position)
		cumulative.append(length)
	return {"ok": false, "reason": "Physical route exceeded its time bound"}

func body_clear(feet: Vector3, radius: float = RADIUS) -> bool:
	var capsule = CapsuleShape3D.new()
	capsule.height = HEIGHT - 0.1
	capsule.radius = radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = feet + Vector3.UP * (HEIGHT / 2.0 + 0.08)
	query.collision_mask = WALL_LAYER
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _sweep_clear(feet: Vector3, motion: Vector3) -> bool:
	if motion.length_squared() < 0.0000001:
		return true
	var capsule = CapsuleShape3D.new()
	capsule.height = HEIGHT - 0.1
	capsule.radius = RADIUS
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = feet + Vector3.UP * (HEIGHT / 2.0 + 0.08)
	query.collision_mask = WALL_LAYER
	query.motion = motion
	query.margin = 0.01
	var fractions = get_world_3d().direct_space_state.cast_motion(query)
	return fractions[0] >= 0.999

func walk_step(feet: Vector3, destination: Vector3, distance: float) -> Dictionary:
	# A bounded stair step, supported by actual collision, never a floor teleport.
	var direction = Vector3(destination.x - feet.x, 0, destination.z - feet.z)
	var desired = feet + direction.normalized() * minf(distance, direction.length())
	var floor_hit = floor_at(desired, MAX_STEP + 0.2, MAX_STEP + 0.6)
	if floor_hit.is_empty() or floor_hit.normal.y < cos(deg_to_rad(46.0)):
		return {"ok": false, "position": feet, "reason": "No walkable support"}
	var support_y = floor_hit.position.y
	# Support spans the capsule footprint: front edge for ascent, rear edge for
	# descent, and lateral edges on diagonal stairs. Every sample hits real mesh.
	for i in range(8):
		var angle = i * TAU / 8.0
		var offset = Vector3(cos(angle), 0, sin(angle)) * RADIUS
		var support = floor_at(desired + offset, MAX_STEP + 0.2, MAX_STEP + 0.6)
		if not support.is_empty() and support.normal.y >= cos(deg_to_rad(46.0)):
			if support.position.y - feet.y <= MAX_STEP:
				support_y = maxf(support_y, support.position.y)
	desired.y = support_y + 0.04
	var rise = desired.y - feet.y
	if absf(rise) > MAX_STEP + 0.04:
		return {"ok": false, "position": feet, "reason": "Step exceeds clearance"}
	if not body_clear(desired):
		var capsule = CapsuleShape3D.new()
		capsule.height = HEIGHT - 0.1
		capsule.radius = RADIUS
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform.origin = desired + Vector3.UP * (HEIGHT / 2.0 + 0.08)
		query.collision_mask = WALL_LAYER
		var contact = get_world_3d().direct_space_state.get_rest_info(query)
		return {"ok": false, "position": feet, "reason": "Capsule blocked", "contact": contact, "desired": desired}
	var raised = feet + Vector3.UP * maxf(0, rise)
	var horizontal = Vector3(desired.x - feet.x, 0, desired.z - feet.z)
	if not _sweep_clear(feet, raised - feet) or not _sweep_clear(raised, horizontal):
		return {"ok": false, "position": feet, "reason": "Movement sweep blocked"}
	return {"ok": true, "position": desired, "reason": ""}
