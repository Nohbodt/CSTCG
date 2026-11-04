class_name PackArt
extends Control

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
var pack_id = "contender"
var large = false
var animate = true
var clock = 0.0
var printed_crimps = true

func _ready() -> void:
	if not has_meta("thumbnail"):
		custom_minimum_size = custom_minimum_size.max(Vector2(180, 250) if not large else Vector2(260, 350))
	size_flags_horizontal = Control.SIZE_FILL if has_meta("thumbnail") else Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("pack_art")
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		clock += delta
		queue_redraw()

func _text(value: String, point: Vector2, font_size: int, color: Color, font: Font = U.BOLD) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var factor = minf(size.x / 240.0, size.y / 320.0)
	var offset = (size - Vector2(240, 320) * factor) * 0.5
	if animate:
		offset.y += sin(clock * 1.1) * 2
	draw_set_transform(offset, -0.018, Vector2.ONE * factor)
	var pack = C.PACKS[pack_id]
	var color = pack.color
	var premium = pack.get("flair", 0) > 0
	draw_style_box(U.box(Color(0, 0, 0, 0.4), 4, Color.TRANSPARENT, 0), Rect2(20, 16, 211, 295))
	draw_colored_polygon(PackedVector2Array([Vector2(18, 5), Vector2(222, 5), Vector2(230, 309), Vector2(10, 309)]), color.darkened(0.48))
	draw_colored_polygon(PackedVector2Array([Vector2(20, 20), Vector2(220, 20), Vector2(228, 293), Vector2(12, 293)]), Color("171025"))
	# Printed interference planes remain still in lightweight/reduced-motion views.
	for i in range(8):
		var x = 15 + i * 26
		var sheen = Color(color.lerp(U.PURPLE, 0.45), 0.07 + (i % 3) * 0.035)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 22), Vector2(mini(x + 36, 218), 22), Vector2(mini(x + 8, 218), 292), Vector2(maxi(x - 22, 15), 292)]), sheen)
	draw_line(Vector2(19, 26), Vector2(12, 291), U.BLUE, 1.6)
	draw_line(Vector2(221, 26), Vector2(228, 291), Color(U.RED, 0.7), 1.6)
	if printed_crimps:
		for i in range(18):
			var x = 22 + i * 11
			draw_line(Vector2(x, 6), Vector2(x - 1, 18), color.lightened(0.2), 2)
			draw_line(Vector2(x - 7, 295), Vector2(x - 7, 307), color.lightened(0.1), 2)
	for i in range(5):
		var x = 36 + i * 39
		draw_line(Vector2(x, 76), Vector2(x - 40, 207), Color(color, 0.09), 1)
	draw_line(Vector2(25, 203), Vector2(214, 104), Color(color, 0.16), 1)
	for i in range(4 if premium else 2):
		var y = 110 + i * 32
		draw_rect(Rect2(21, y, 13 + i * 3, 2), Color(U.BLUE, 0.65))
		draw_rect(Rect2(207 - i * 2, y + 3, 12, 2), Color(U.RED, 0.5))
	_text("CSTCG", Vector2(29, 56), 29, U.TEXT, U.DISPLAY)
	_text("ALPHA COLLECTION", Vector2(30, 73), 8, color)
	draw_line(Vector2(29, 85), Vector2(211, 85), Color(color, 0.35), 1)
	if premium:
		var star = PackedVector2Array()
		for i in range(10):
			var angle = -PI / 2 + i * PI / 5
			star.append(Vector2(120, 145) + Vector2(cos(angle), sin(angle)) * (47 if i % 2 == 0 else 20))
		draw_colored_polygon(star, color)
		for i in range(5):
			var angle = -PI / 2 + i * TAU / 5
			draw_line(Vector2(120, 145), Vector2(120, 145) + Vector2(cos(angle), sin(angle)) * 47, color.lightened(0.3), 1)
			draw_colored_polygon(PackedVector2Array([Vector2(120, 145), star[i * 2], star[(i * 2 + 1) % 10]]), color.lerp(U.TEXT, 0.45))
	else:
		draw_arc(Vector2(120, 145), 44, PI * 0.23, PI * 1.77, 30, color, 12, true)
		draw_line(Vector2(84, 173), Vector2(156, 116), color.lightened(0.25), 2)
	_text("ELITE" if premium else "CONTENDER", Vector2(28, 226), 30 if premium else 24, U.TEXT, U.DISPLAY)
	_text("CIRCUIT" if premium else "YOUR NEXT FIVE", Vector2(30, 243), 10, color)
	draw_line(Vector2(29, 253), Vector2(211, 253), Color(color, 0.45), 1)
	_text("5 PLAYER CARDS", Vector2(29, 270), 11, U.TEXT)
	_text(pack.guarantee, Vector2(29, 286), 8, color)
	draw_set_transform(Vector2.ZERO)
