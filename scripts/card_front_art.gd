class_name CardFrontArt
extends RefCounted
## Printed collectible artwork, shared by the collection and physical 3D cards.

const C = preload("res://scripts/catalog.gd")
const U = preload("res://scripts/ui.gd")
const FLAVOR = {"ENTRY": "FIRST CONTACT", "AWPER": "LONG SIGHT", "IGL": "ROUND CALLER", "SUPPORT": "TEAM FIRST", "LURKER": "LATE ROTATE"}
const PORTRAIT_RECT = Rect2(46, 29, 132, 164)

static func _plate(canvas: CanvasItem, rect: Rect2, cut: float, color: Color) -> void:
	var a = rect.position
	var b = rect.end
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), Vector2(b.x, b.y - cut), Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), Vector2(a.x, a.y + cut)]), color)

static func _text(canvas: CanvasItem, value: String, point: Vector2, size: int, color: Color, font: Font = U.DISPLAY) -> void:
	canvas.draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func _fit(canvas: CanvasItem, value: String, point: Vector2, size: int, width: float, color: Color, font: Font = U.DISPLAY) -> void:
	while size > 6 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	_text(canvas, value, point, size, color, font)

static func _circuit(canvas: CanvasItem, color: Color) -> void:
	for i in range(6):
		var y = 44 + i * 23
		var points = PackedVector2Array([Vector2(61, y + 18), Vector2(82, y + 18), Vector2(100, y), Vector2(172, y)])
		canvas.draw_polyline(points, Color(color, 0.24), 0.7, true)
		canvas.draw_circle(points[0], 1.6, Color(color, 0.55))
		canvas.draw_rect(Rect2(166, y - 3, 7, 7), Color(color, 0.2))
	for x in range(72, 176, 12):
		canvas.draw_line(Vector2(x, 27), Vector2(x, 177), Color(color, 0.07), 0.5)

static func _contours(canvas: CanvasItem, color: Color) -> void:
	for level in range(10):
		var points = PackedVector2Array()
		for i in range(45):
			var angle = i * TAU / 44
			var radius = 16.0 + level * 10 + sin(angle * 3 + level * 0.5) * 7
			points.append(Vector2(clampf(118 + cos(angle) * radius, 59, 175), clampf(102 + sin(angle) * radius * 0.75, 26, 176)))
		canvas.draw_polyline(points, Color(color, 0.25), 0.6, true)

static func _shards(canvas: CanvasItem, color: Color) -> void:
	for i in range(9):
		var x = 14.0 + i * 18
		var y = 157.0 - (i % 4) * 35
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 24), Vector2(minf(176, x + 43), maxf(28, y - 45)), Vector2(minf(176, x + 13), y)]), Color(color, 0.12 + (i % 3) * 0.04))
		canvas.draw_line(Vector2(x, y + 24), Vector2(minf(176, x + 43), maxf(28, y - 45)), Color(color.lerp(Color.WHITE, 0.5), 0.55), 0.8, true)

static func draw(canvas: CanvasItem, card: Dictionary, portrait: Texture2D, fresh: bool, selected: bool) -> void:
	var rarity = int(card.rarity)
	var color: Color = C.COLORS[rarity]
	var metal = color.lerp(Color.WHITE, 0.38)
	_plate(canvas, Rect2(0, 0, 190, 290), 12, Color("080911"))
	_plate(canvas, Rect2(1, 1, 188, 288), 11, U.BLUE if selected else color.darkened(0.2))
	_plate(canvas, Rect2(3, 3, 184, 284), 10, metal)
	_plate(canvas, Rect2(5, 5, 180, 280), 9, Color("11111f"))
	_plate(canvas, Rect2(8, 8, 174, 274), 7, Color("161323").lerp(color.darkened(0.85), 0.38))
	# Faceted corners and side rails catch light independently of the print.
	for corner in [Vector2(4, 4), Vector2(176, 4), Vector2(4, 276), Vector2(176, 276)]:
		canvas.draw_colored_polygon(PackedVector2Array([corner, corner + Vector2(10, 0), corner + Vector2(0, 10)]), metal)
		canvas.draw_line(corner, corner + Vector2(9, 8), U.BLUE if corner.y < 20 else U.PURPLE, 1.0, true)
	canvas.draw_line(Vector2(9, 28), Vector2(9, 170), Color(metal, 0.75), 0.8)
	canvas.draw_line(Vector2(181, 100), Vector2(181, 174), Color(color, 0.85), 1.2)
	if rarity == 1:
		_circuit(canvas, color)
	elif rarity == 2:
		_contours(canvas, color)
	elif rarity == 3:
		_shards(canvas, color)
	else:
		for i in range(8):
			canvas.draw_line(Vector2(59, 35 + i * 20), Vector2(175, 22 + i * 20), Color(color, 0.10), 0.7)
	# Small chromatic discontinuities carry the Phase Shift motif through every tier.
	for i in range(7):
		var x = 66 + (i * 23) % 105
		var y = 37 + i * 21
		canvas.draw_rect(Rect2(x, y, 5 + i % 3 * 4, 1.5), Color(U.RED if i % 2 else U.BLUE, 0.55))
	if portrait != null:
		var image_size = portrait.get_size()
		var factor = minf(PORTRAIT_RECT.size.x / image_size.x, PORTRAIT_RECT.size.y / image_size.y)
		var extent = image_size * factor
		canvas.draw_texture_rect(portrait, Rect2(PORTRAIT_RECT.position + (PORTRAIT_RECT.size - extent) * 0.5, extent), false)
	else:
		canvas.draw_arc(Vector2(115, 112), 39, 0, TAU, 64, Color(color, 0.6), 1.0)
		canvas.draw_circle(Vector2(115, 112), 36, Color(color, 0.06))
		_fit(canvas, str(card.handle).left(2).to_upper(), Vector2(91, 123), 35, 65, color)
	# Live names and ratings are text layers, never part of generated portrait art.
	_text(canvas, "CSTCG", Vector2(13, 19), 11, U.TEXT)
	_text(canvas, "ALPHA COLLECTION", Vector2(83, 18), 6, metal, U.BOLD)
	_text(canvas, str(card.overall), Vector2(13, 55), 33, U.TEXT)
	_text(canvas, "OVR", Vector2(15, 65), 6, color, U.BOLD)
	_fit(canvas, card.role, Vector2(14, 82), 10, 42, U.TEXT)
	canvas.draw_rect(Rect2(13, 89, 29, 14), Color("10101c"))
	_text(canvas, card.country, Vector2(18, 100), 9, color, U.BOLD)
	for i in range(rarity + 1):
		canvas.draw_line(Vector2(15 + i * 7, 113), Vector2(19 + i * 7, 109), color, 1.7, true)
	canvas.draw_line(Vector2(14, 122), Vector2(14, 167), Color(color, 0.36), 0.8)
	# Slanted nameplate overlays the chest while leaving the complete face visible.
	var name_ink = Color("17121a") if rarity == 3 else U.TEXT
	var name_fill = color.lerp(Color.WHITE, 0.16) if rarity == 3 else Color("0d0e19")
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(10, 179), Vector2(180, 174), Vector2(180, 216), Vector2(10, 221)]), name_fill)
	if rarity == 3:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(10, 179), Vector2(180, 174), Vector2(174, 179), Vector2(15, 184)]), Color("fff0c9"))
	canvas.draw_line(Vector2(10, 179), Vector2(180, 174), metal, 1.0, true)
	_fit(canvas, card.handle, Vector2(14, 202), 27, 159, name_ink)
	_fit(canvas, card.name, Vector2(15, 215), 9, 157, name_ink if rarity == 3 else U.MUTED, U.BOLD)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(12, 223), Vector2(178, 218), Vector2(170, 232), Vector2(12, 236)]), color.darkened(0.15))
	_text(canvas, str(FLAVOR.get(card.role, "OPEN CIRCUIT")), Vector2(19, 231), 7, Color("11101b"), U.BOLD)
	var stats = [card.aim, card.sense, card.utility]
	for i in range(3):
		var x = 16 + i * 55
		_text(canvas, str(stats[i]), Vector2(x, 257), 22, metal)
		_text(canvas, ["AIM", "IQ", "UTIL"][i], Vector2(x + 1, 266), 6, U.TEXT, U.BOLD)
		if i < 2:
			canvas.draw_line(Vector2(x + 42, 239), Vector2(x + 42, 265), Color(color, 0.25), 0.6)
	canvas.draw_line(Vector2(12, 272), Vector2(178, 272), Color(color, 0.6), 0.6)
	_text(canvas, C.RARITIES[rarity], Vector2(14, 282), 7, color, U.BOLD)
	var number = 0
	for i in range(C.PLAYERS.size()):
		if C.PLAYERS[i][0] == card.id:
			number = i + 1
	_text(canvas, "CC-%03d/030" % number, Vector2(122, 282), 6, U.MUTED, U.BOLD)
	if fresh:
		canvas.draw_rect(Rect2(143, 23, 33, 13), U.RED)
		_text(canvas, "NEW", Vector2(150, 32), 8, U.TEXT, U.BOLD)
