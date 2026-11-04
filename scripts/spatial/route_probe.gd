class_name RouteProbe
extends Node3D

signal arrived
signal blocked(reason: String)

const U = preload("res://scripts/ui.gd")
var world: DustWorld
var path = PackedVector3Array()
var cursor = 0
var speed = 5.0
var paused = false
var elapsed = 0.0
var travelled = 0.0
var blocked_reason = ""
var completed = false
var selected = false
var number = 1
var team = 0
var handle = "PROBE"
var previous_position = Vector3.ZERO
var ring: MeshInstance3D

func _ready() -> void:
	var color = U.BLUE if team == 0 else U.RED
	var mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.29
	capsule.height = 1.8
	mesh.mesh = capsule
	mesh.position.y = 0.9
	mesh.material_override = _material(color)
	add_child(mesh)
	ring = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.6
	cylinder.bottom_radius = 0.6
	cylinder.height = 0.05
	ring.mesh = cylinder
	ring.position.y = 0.04
	ring.material_override = _material(Color(color, 0.3))
	add_child(ring)
	var label = Label3D.new()
	label.text = "%02d" % number
	label.font = U.BOLD
	label.font_size = 42
	label.pixel_size = 0.022
	label.position.y = 2.5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	add_child(label)

func _material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func set_route(points: PackedVector3Array) -> void:
	path = points
	cursor = 0
	elapsed = 0
	travelled = 0
	blocked_reason = ""
	completed = false
	previous_position = position

func advance(delta: float) -> void:
	if paused or completed or not blocked_reason.is_empty() or path.is_empty():
		return
	elapsed += delta
	while cursor < path.size():
		var target = path[cursor]
		var horizontal = Vector2(target.x - position.x, target.z - position.z).length()
		if horizontal > 0.02 or absf(target.y - position.y) > world.MAX_STEP + 0.25:
			break
		cursor += 1
	if cursor >= path.size():
		completed = true
		arrived.emit()
		return
	var result = world.walk_step(position, path[cursor], speed * delta)
	if not result.ok:
		blocked_reason = result.reason
		blocked.emit(blocked_reason)
		return
	var distance = position.distance_to(result.position)
	travelled += distance
	previous_position = position
	position = result.position

func _physics_process(delta: float) -> void:
	advance(delta)
	if is_instance_valid(ring):
		ring.scale = Vector3.ONE * (1.5 if selected else 1.0)
