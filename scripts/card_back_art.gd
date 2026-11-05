class_name CardBackArt
extends RefCounted

const U = preload("res://scripts/ui.gd")
const STYLES = {
	"contender": {"title": "CONTENDER", "line": "THE OPEN CIRCUIT", "color": U.BLUE, "emblem": "C", "pattern": 0},
	"elite": {"title": "ELITE CIRCUIT", "line": "PREMIUM FOIL", "color": U.PURPLE, "emblem": "STAR", "pattern": 1},
	"starter": {"title": "FOUNDATION", "line": "STARTER SQUAD", "color": Color("9baecf"), "emblem": "CC", "pattern": 2},
	"legacy": {"title": "CLUB ARCHIVE", "line": "PACK NOT RECORDED", "color": Color("b8b6c8"), "emblem": "CC", "pattern": 2},
	"trade": {"title": "CLUB ARCHIVE", "line": "TRADE / PACK NOT RECORDED", "color": Color("b8b6c8"), "emblem": "CC", "pattern": 2},
	"s1.alpha": {"title": "SERIES 1 ALPHA", "line": "FIRST CONTACT", "color": U.BLUE, "emblem": "A", "pattern": 0},
	"s1.bravo": {"title": "SERIES 1 BRAVO", "line": "THE NEXT MOVE", "color": U.RED, "emblem": "B", "pattern": 0},
	"s1.elite": {"title": "SERIES 1 ELITE", "line": "ELITE SHOWCASE", "color": U.PURPLE, "emblem": "STAR", "pattern": 1},
	"s1.beta_event": {"title": "BETA EVENT", "line": "FIRST CIRCUIT", "color": U.PURPLE, "emblem": "BETA", "pattern": 3}
}

static func style(origin: String) -> Dictionary:
	return STYLES.get(origin, STYLES.legacy)

static func _text(canvas: CanvasItem, value: String, y: float, size: int, color: Color, bold: bool = true) -> void:
	var font = U.DISPLAY if size > 16 else (U.BOLD if bold else U.FONT)
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(font, Vector2((190 - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func draw(canvas: CanvasItem, origin: String) -> void:
	var design = style(origin)
	var color: Color = design.color
	canvas.draw_style_box(U.box(Color("151024"), 8, color.darkened(0.12), 0), Rect2(0, 0, 190, 290))
	canvas.draw_style_box(U.box(Color(color, 0.04), 5, Color(color, 0.34), 0), Rect2(5, 5, 180, 280))
	canvas.draw_line(Vector2(9, 16), Vector2(9, 273), Color(U.BLUE, 0.38), 1)
	canvas.draw_line(Vector2(181, 16), Vector2(181, 273), Color(U.RED, 0.28), 1)
	# Each pack has its own geometry; no player, rating or rarity enters the back.
	if design.pattern == 0:
		for i in range(7):
			var x = 17 + i * 24
			canvas.draw_polyline(PackedVector2Array([Vector2(x, 65), Vector2(x, 86), Vector2(minf(176, x + 22), 108), Vector2(minf(176, x + 22), 181)]), Color(color, 0.16), 1)
			canvas.draw_circle(Vector2(x, 65), 1.6, Color(color, 0.55))
	elif design.pattern == 1:
		for i in range(8):
			var angle = i * PI * 0.25
			var point = Vector2(95, 137) + Vector2(cos(angle), sin(angle)) * 83
			canvas.draw_line(Vector2(95, 137), point, Color(color, 0.14), 1)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(12, 70), Vector2(178, 125), Vector2(12, 196)]), Color(color, 0.07))
	elif design.pattern == 3:
		for i in range(7):
			canvas.draw_arc(Vector2(50, 132), 34 + i * 13, -1.1, 1.65, 36, Color(U.BLUE if i % 2 else color, 0.18), 1)
	else:
		for i in range(8):
			canvas.draw_line(Vector2(15 + i * 22, 70), Vector2(15 + i * 22, 196), Color(color, 0.08), 1)
		for i in range(6):
			canvas.draw_line(Vector2(15, 80 + i * 22), Vector2(175, 80 + i * 22), Color(color, 0.08), 1)
	_text(canvas, "CSTCG", 40, 25, U.TEXT)
	_text(canvas, "PLAYER COLLECTION", 55, 8, color)
	canvas.draw_line(Vector2(23, 65), Vector2(167, 65), Color(color, 0.42), 1)
	canvas.draw_circle(Vector2(95, 139), 49, Color(color, 0.065))
	canvas.draw_arc(Vector2(95, 139), 51, 0, TAU, 64, Color(color, 0.5), 1)
	if design.emblem == "STAR":
		var points = PackedVector2Array()
		for i in range(10):
			var angle = -PI * 0.5 + i * PI / 5
			points.append(Vector2(95, 139) + Vector2(cos(angle), sin(angle)) * (39 if i % 2 == 0 else 18))
		canvas.draw_colored_polygon(points, color)
		for i in range(5):
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(95, 139), points[i * 2], points[(i * 2 + 1) % 10]]), color.lerp(U.TEXT, 0.55))
	elif design.emblem == "C":
		canvas.draw_arc(Vector2(95, 139), 32, PI * 0.24, PI * 1.76, 40, color, 7)
		canvas.draw_line(Vector2(67, 165), Vector2(123, 113), U.TEXT, 1.2)
	elif design.emblem == "A":
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(95, 99), Vector2(133, 174), Vector2(111, 162), Vector2(95, 127), Vector2(79, 162), Vector2(57, 174)]), color)
		canvas.draw_line(Vector2(72, 151), Vector2(116, 133), U.TEXT, 2)
	elif design.emblem == "B":
		for i in range(2):
			var y = 104 + i * 34
			canvas.draw_polyline(PackedVector2Array([Vector2(71, y), Vector2(117, y + 17), Vector2(71, y + 34)]), color, 8)
	elif design.emblem == "BETA":
		_text(canvas, "β", 164, 72, color)
		canvas.draw_style_box(U.box(Color(U.RED, 0.15), 2, U.RED, 0), Rect2(121, 177, 51, 17))
		canvas.draw_string(U.BOLD, Vector2(125, 188), "EVENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, U.RED)
	else:
		_text(canvas, "CC", 152, 34, color)
	for i in range(3):
		canvas.draw_rect(Rect2(18, 112 + i * 26, 10 + i * 5, 1), Color(U.BLUE, 0.45))
		canvas.draw_rect(Rect2(159 - i * 3, 120 + i * 26, 13, 1), Color(U.RED, 0.38))
	_text(canvas, "PACK OF ORIGIN" if origin in ["contender", "elite"] or origin.begins_with("s1.") else "CLUB PROVENANCE", 213, 7, U.MUTED)
	_text(canvas, design.title, 234, 17, U.TEXT)
	_text(canvas, design.line, 251, 7 if design.line.length() > 22 else 8, color)
	canvas.draw_line(Vector2(23, 264), Vector2(167, 264), Color(color, 0.4), 1)
	_text(canvas, "SERIES 1" if origin.begins_with("s1.") else "CLUB CIRCUIT", 279, 8, U.MUTED)
