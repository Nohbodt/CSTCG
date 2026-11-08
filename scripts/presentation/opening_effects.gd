class_name OpeningEffects
extends Node3D
## Local GL-compatible light halos and deterministic sparks; no gameplay RNG.

const U = preload("res://scripts/ui.gd")
const GLOW = preload("res://scripts/presentation/glow.gdshader")
var level = 0
var tint = U.BLUE
var halo: MeshInstance3D
var rip_glow: MeshInstance3D
var shockwave: MeshInstance3D
var card_glow: MeshInstance3D
var spark_pool: MultiMeshInstance3D
var trail_pool: MultiMeshInstance3D
var rip_streak: MeshInstance3D
var rip_cross: MeshInstance3D

static func spark_count(flair: int) -> int:
	return 72 + flair * 32

func _ready() -> void:
	halo = _glow(Vector2(5.6, 5.6), tint, 1.0, 0.0)
	halo.position = Vector3(0, 0.15, -0.25)
	rip_glow = _glow(Vector2(0.9, 0.9), U.BLUE.lerp(U.TEXT, 0.35), 1.0, 0.0)
	rip_streak = _glow(Vector2(3.0 + level * 0.5, 0.18), tint.lerp(Color.WHITE, 0.65), 1.0, 0.0)
	rip_cross = _glow(Vector2(0.12, 1.45), tint.lerp(Color.WHITE, 0.8), 1.0, 0.0)
	shockwave = _glow(Vector2(8.0, 8.0), tint.lerp(U.TEXT, 0.35), 0.0, 1.0)
	shockwave.position.z = 0.4
	card_glow = _glow(Vector2(2.1, 3.0), tint, 0.8, 0.2)
	spark_pool = _sparks(spark_count(level), Vector2(0.035, 0.22))
	trail_pool = _sparks(36 + level * 24, Vector2(0.025, 0.12))
	visible = false

func _glow(size: Vector2, color: Color, core: float, ring: float) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = size
	node.mesh = quad
	var material = ShaderMaterial.new()
	material.shader = GLOW
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("core", core)
	material.set_shader_parameter("ring", ring)
	node.material_override = material
	add_child(node)
	return node

func _sparks(count: int, size: Vector2) -> MultiMeshInstance3D:
	var node = MultiMeshInstance3D.new()
	var instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	var quad = QuadMesh.new()
	quad.size = size
	instances.mesh = quad
	instances.instance_count = count
	node.multimesh = instances
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	node.material_override = material
	# Bounds include all trajectories, independent of the current instance data.
	node.custom_aabb = AABB(Vector3(-12, -8, -3), Vector3(24, 18, 6))
	add_child(node)
	return node

func _unit(index: int, salt: float) -> float:
	return fposmod(sin(index * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

func update_fx(state: Dictionary) -> void:
	var step: String = state.step
	var age: float = state.explosion_age
	var charge: float = state.charge
	var pulse: float = state.pulse
	visible = not state.reduced and (charge > 0.01 or pulse > 0.01 or age >= 0)
	if not visible:
		return
	var blast = pow(maxf(0, 1.0 - age / 1.1), 2) if age >= 0 else 0.0
	halo.material_override.set_shader_parameter("energy", charge * 0.9 + blast * (1.5 + level * 0.3))
	halo.scale = Vector3.ONE * (1.0 + blast * 0.25)
	var tearing = step in ["tearing", "paused"]
	var intensity = (0.5 + pow(float(state.tear), 1.7) * (3.2 + level * 0.55)) * (0.45 if step == "paused" else 1.0)
	rip_glow.visible = tearing
	rip_glow.position = state.tip + Vector3(0, 0, -0.04)
	rip_glow.scale = Vector3.ONE * (0.7 + state.tear * 0.6)
	rip_glow.material_override.set_shader_parameter("energy", intensity)
	for streak in [rip_streak, rip_cross]:
		streak.visible = tearing
		streak.position = state.tip + Vector3(0, 0, 0.04)
		streak.material_override.set_shader_parameter("energy", intensity * 0.5)
	shockwave.visible = age >= 0 and age < 1.1
	shockwave.material_override.set_shader_parameter("radius", 0.08 + clampf(age, 0.0, 1.0) * 0.87)
	shockwave.material_override.set_shader_parameter("energy", blast * (0.65 + level * 0.16))
	card_glow.visible = state.flip_age >= 0 and pulse > 0.01
	card_glow.position = state.flip_origin + Vector3(0, 0, -0.08)
	card_glow.material_override.set_shader_parameter("tint", state.flip_color)
	card_glow.material_override.set_shader_parameter("energy", pulse * 1.3)
	_update_rip_sparks(state)
	_update_burst_sparks(state)

func _update_rip_sparks(state: Dictionary) -> void:
	trail_pool.visible = state.step == "tearing"
	if not trail_pool.visible:
		return
	for i in range(trail_pool.multimesh.instance_count):
		var age = fposmod(state.clock + i * 0.027, 0.45)
		var velocity = Vector3((_unit(i, 1) - 0.55) * 2.3, 0.8 + _unit(i, 2) * 1.6, (_unit(i, 3) - 0.5) * 0.35)
		var origin: Vector3 = state.tip - Vector3(age * 0.55, 0, 0)
		var position = origin + velocity * age - Vector3(0, age * age * 2.5, 0)
		_put_spark(trail_pool.multimesh, i, position, velocity, (1 - age / 0.45) * 0.9, tint, 0.4 + age * 2)

func _update_burst_sparks(state: Dictionary) -> void:
	var opening_burst: bool = state.explosion_age >= 0 and state.explosion_age < 1.4
	var flip_burst: bool = state.flip_age >= 0 and state.flip_age < 0.5
	spark_pool.visible = opening_burst or flip_burst
	if not spark_pool.visible:
		return
	var age: float = state.explosion_age if opening_burst else state.flip_age
	var origin: Vector3 = Vector3(0, 0.3, 0.35) if opening_burst else state.flip_origin
	var lifetime = 1.05 + level * 0.12 if opening_burst else 0.45
	var power = 1.0 if opening_burst else 0.28
	var color: Color = tint if opening_burst else state.flip_color
	for i in range(spark_pool.multimesh.instance_count):
		var delay = _unit(i, 4) * 0.09
		var elapsed = maxf(0, age - delay)
		var angle = i * 2.399963
		var speed = (2.0 + _unit(i, 5) * (4.0 + level)) * power
		var velocity = Vector3(cos(angle), sin(angle), (_unit(i, 6) - 0.5) * 0.7) * speed
		var position = origin + velocity * elapsed - Vector3(0, elapsed * elapsed * 1.7, 0)
		var opacity = pow(maxf(0, 1 - elapsed / lifetime), 1.5) if age >= delay else 0.0
		var tint_color = color.lerp(U.TEXT, 0.55 + _unit(i, 7) * 0.4)
		_put_spark(spark_pool.multimesh, i, position, velocity, opacity, tint_color, 0.6 + elapsed * 3)

func _put_spark(pool: MultiMesh, index: int, position: Vector3, velocity: Vector3, opacity: float, color: Color, length: float) -> void:
	var angle = atan2(velocity.y, velocity.x) - PI * 0.5
	var basis = Basis.from_euler(Vector3(0, 0, angle)).scaled(Vector3(1.0, length, 1.0))
	pool.set_instance_transform(index, Transform3D(basis, position))
	pool.set_instance_color(index, Color(color, opacity))
