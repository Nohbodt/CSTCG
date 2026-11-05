class_name CardArt
extends Control

const C = preload("res://scripts/catalog.gd")
const U = preload("res://scripts/ui.gd")
const Back = preload("res://scripts/card_back_art.gd")
var card: Dictionary = {}
var face_down = false
var compact = false
var fresh = false
var selected = false
var back_origin = "legacy"
var _portrait_path = ""
var _portrait: Texture2D

static func portrait_path_for(data: Dictionary) -> String:
	var requested = str(data.get("portrait", ""))
	if requested.is_empty():
		return ""
	# Prefer a later reviewed PNG while supporting the temporary WebP set and
	# legacy JPEG paths retained in saved match snapshots.
	var base = requested.get_basename()
	for extension in [".png", ".webp", ".jpg"]:
		var candidate = base + extension
		if ResourceLoader.exists(candidate):
			return candidate
	return requested if ResourceLoader.exists(requested) else ""

func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(120, 200) if compact else Vector2(175, 284))
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
		Back.draw(self, back_origin)
		draw_set_transform(Vector2.ZERO)
		return
	if card.is_empty():
		return
	var color = C.COLORS[card.rarity]
	var border = U.BLUE if selected else Color(color, 0.6)
	draw_style_box(U.box(Color("181226"), 7, border, 0), Rect2(0, 0, 190, 290))
	draw_rect(Rect2(1, 1, 188, 175), Color(color, 0.08))
	draw_style_box(U.box(Color.TRANSPARENT, 5, Color(color, 0.18), 0), Rect2(5, 5, 180, 280))
	# Real identities use a supplied portrait when available; the alpha fallback
	# is a neutral nameplate, never an invented face presented as the player.
	for i in range(7):
		_stripe(Vector2(-20 + i * 37, 174), Vector2(100 + i * 37, 1), Color(color, 0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(132, 8), Vector2(182, 8), Vector2(182, 93)]), Color(U.PURPLE, 0.09))
	draw_line(Vector2(8, 24), Vector2(8, 169), Color(U.BLUE, 0.28), 1)
	draw_line(Vector2(181, 87), Vector2(181, 170), Color(U.RED, 0.18), 1)
	var portrait_path = portrait_path_for(card)
	if portrait_path != _portrait_path:
		_portrait_path = portrait_path
		# Canvas draw commands retain the texture RID, so keep the resource alive
		# between redraws and until a stage has captured its printed card face.
		_portrait = load(portrait_path) if not portrait_path.is_empty() else null
	if _portrait != null:
		var target = Rect2(51, 8, 130, 166)
		var image_size = _portrait.get_size()
		var crop_size = Vector2(image_size.y * target.size.x / target.size.y, image_size.y)
		if crop_size.x > image_size.x:
			crop_size = Vector2(image_size.x, image_size.x * target.size.y / target.size.x)
		draw_texture_rect_region(_portrait, target, Rect2((image_size - crop_size) * 0.5, crop_size))
	else:
		draw_circle(Vector2(109, 91), 48, Color(color, 0.07))
		draw_arc(Vector2(109, 91), 49, 0, TAU, 60, Color(color, 0.4), 1.3)
		var monogram = card.handle.left(2).to_upper()
		var width = U.DISPLAY.get_string_size(monogram, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		_text(monogram, Vector2(109 - width / 2, 105), 40, Color(color, 0.85))
		_text("CSTCG", Vector2(83, 159), 8, color, U.BOLD)
	_text(str(card.overall), Vector2(12, 35), 27, U.TEXT)
	_text(card.role, Vector2(13, 51), 9, color, U.BOLD)
	_text(card.country, Vector2(154, 22), 11, U.TEXT, U.BOLD)
	draw_rect(Rect2(10, 175, 170, 1), color)
	for i in range(int(card.rarity) + 1):
		draw_line(Vector2(14 + i * 9, 61), Vector2(18 + i * 9, 57), color, 1.5)
	_text(card.handle, Vector2(12, 204), 20 if card.handle.length() > 8 else 25, U.TEXT)
	_text(card.name, Vector2(13, 222), 10, U.MUTED, U.BOLD)
	draw_line(Vector2(13, 234), Vector2(177, 234), U.BORDER, 1)
	for i in range(3):
		var x = 13 + i * 58
		_text(str([card.aim, card.sense, card.utility][i]), Vector2(x, 253), 16, U.TEXT)
		_text(["AIM", "IQ", "UTIL"][i], Vector2(x, 267), 8, U.MUTED, U.BOLD)
	_text(C.RARITIES[card.rarity] + " / ALPHA", Vector2(13, 283), 8, color, U.BOLD)
	if fresh:
		draw_rect(Rect2(126, 184, 53, 19), color)
		_text("NEW", Vector2(135, 197), 10, U.BG)
	draw_set_transform(Vector2.ZERO)
