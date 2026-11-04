class_name CardArt
extends Control

const C = preload("res://scripts/catalog.gd")
const U = preload("res://scripts/ui.gd")
var card: Dictionary = {}
var face_down = false
var compact = false
var fresh = false
var selected = false

func _ready() -> void:
	custom_minimum_size = Vector2(120, 200) if compact else Vector2(175, 284)
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _text(text: String, point: Vector2, font_size: int, color: Color, font: Font = U.DISPLAY) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _stripe(start: Vector2, finish: Vector2, color: Color) -> void:
	if finish.x < 1 or start.x > 189:
		return
	if start.x < 1:
		start = start.lerp(finish, (1.0 - start.x) / (finish.x - start.x))
	if finish.x > 189:
		finish = start.lerp(finish, (189.0 - start.x) / (finish.x - start.x))
	draw_line(start, finish, color, 1)

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var scale_factor = minf(size.x / 190.0, size.y / 290.0)
	var offset = (size - Vector2(190, 290) * scale_factor) * 0.5
	draw_set_transform(offset, 0, Vector2.ONE * scale_factor)
	if face_down:
		var back = U.box(Color("19212a"), 8, Color("52616f"), 0)
		draw_style_box(back, Rect2(0, 0, 190, 290))
		for i in range(12):
			_stripe(Vector2(i * 24 - 150, 289), Vector2(i * 24 + 90, 1), Color("293440"))
		draw_circle(Vector2(95, 134), 38, Color("202b36"))
		draw_arc(Vector2(95, 134), 40, 0, TAU, 48, U.ORANGE, 1.4)
		_text("C / C", Vector2(57, 144), 28, U.ORANGE)
		_text("CLUB CIRCUIT", Vector2(36, 216), 15, U.TEXT)
		_text("REVEAL YOUR NEXT", Vector2(35, 237), 10, U.MUTED, U.BOLD)
		return
	if card.is_empty():
		return
	var color = C.COLORS[card.rarity]
	var border = U.ORANGE if selected else Color(color, 0.5)
	draw_style_box(U.box(Color("151c24"), 7, border, 0), Rect2(0, 0, 190, 290))
	draw_rect(Rect2(1, 1, 188, 175), Color(color, 0.14))
	# Printed geometric player portrait, deliberately independent of licensed imagery.
	var variant = C.ROLES.find(card.role)
	for i in range(7):
		_stripe(Vector2(-20 + i * 37, 174), Vector2(100 + i * 37, 1), Color(color, 0.13))
	draw_circle(Vector2(102, 83), 55, Color(color, 0.09))
	draw_arc(Vector2(102, 83), 63, -PI * 0.7, PI * 0.4, 32, Color(color, 0.4), 1.3)
	var portrait = absi(card.id.hash())
	var skins = [Color("b6a38b"), Color("c4ae98"), Color("8e7568"), Color("c5b8a4"), Color("a8876c")]
	var skin = skins[portrait % skins.size()].lerp(color, 0.15)
	var hair = [Color("22272d"), Color("7c624a"), Color("bbaa87"), Color("3b3030")][int(portrait / 7) % 4]
	var jersey = Color("293541").lerp(color, 0.12 if card.rarity < 2 else 0.23)
	draw_colored_polygon(PackedVector2Array([Vector2(44, 176), Vector2(49, 139), Vector2(80, 122), Vector2(90, 109), Vector2(114, 109), Vector2(124, 122), Vector2(152, 139), Vector2(165, 176)]), jersey)
	draw_colored_polygon(PackedVector2Array([Vector2(84, 127), Vector2(102, 143), Vector2(121, 127), Vector2(115, 114), Vector2(90, 114)]), skin.darkened(0.32))
	draw_circle(Vector2(102, 87), 28, skin)
	if portrait % 3 == 0:
		draw_colored_polygon(PackedVector2Array([Vector2(76, 84), Vector2(75, 69), Vector2(87, 54 - variant), Vector2(116, 53), Vector2(130, 72), Vector2(127, 85), Vector2(118, 73), Vector2(87, 76)]), hair)
	elif portrait % 3 == 1:
		draw_arc(Vector2(102, 85), 28, -PI, 0, 18, hair, 10)
		draw_line(Vector2(79, 74), Vector2(122, 70), hair, 8)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(75, 86), Vector2(76, 67), Vector2(93, 58), Vector2(124, 61), Vector2(130, 81), Vector2(119, 73), Vector2(104, 79), Vector2(84, 76)]), hair)
	draw_line(Vector2(102, 84), Vector2(98, 99), skin.darkened(0.25), 2)
	draw_line(Vector2(90, 106), Vector2(111, 106), skin.darkened(0.35), 1.5)
	draw_line(Vector2(87, 86), Vector2(96, 86), Color("243340"), 2)
	draw_line(Vector2(109, 86), Vector2(118, 86), Color("243340"), 2)
	if portrait % 4 == 0:
		draw_arc(Vector2(102, 91), 22, 0.15, PI - 0.15, 15, Color(hair, 0.7), 7)
	if card.role == "AWPER":
		draw_rect(Rect2(83, 81, 16, 11), Color("28313b"), false, 1.5)
		draw_rect(Rect2(106, 81, 16, 11), Color("28313b"), false, 1.5)
		draw_line(Vector2(99, 85), Vector2(106, 85), Color("28313b"), 1.5)
	draw_line(Vector2(101, 145), Vector2(101, 176), Color(color, 0.55), 2)
	_text("CC", Vector2(121, 159), 13, color)
	_text(str(card.overall), Vector2(12, 35), 27, U.TEXT)
	_text(card.role, Vector2(13, 51), 9, color, U.BOLD)
	_text(card.country, Vector2(154, 22), 11, U.TEXT, U.BOLD)
	draw_rect(Rect2(1, 175, 188, 3), color)
	_text(card.handle, Vector2(12, 204), 25, U.TEXT)
	_text(card.club, Vector2(13, 222), 10, U.MUTED, U.BOLD)
	draw_line(Vector2(13, 234), Vector2(177, 234), U.BORDER, 1)
	for i in range(3):
		var x = 13 + i * 58
		_text(str([card.aim, card.sense, card.utility][i]), Vector2(x, 253), 16, U.TEXT)
		_text(["AIM", "IQ", "UTIL"][i], Vector2(x, 267), 8, U.MUTED, U.BOLD)
	_text(C.RARITIES[card.rarity] + " / S01", Vector2(13, 283), 8, color, U.BOLD)
	if fresh:
		draw_rect(Rect2(126, 184, 53, 19), color)
		_text("NEW", Vector2(135, 197), 10, U.BG)
	draw_set_transform(Vector2.ZERO)
