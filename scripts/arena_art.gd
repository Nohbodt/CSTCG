class_name ArenaArt
extends Control

const U = preload("res://scripts/ui.gd")
const MAP = preload("res://assets/ui/dust2_preview.png")
const BRAND = preload("res://assets/ui/phase_shift_brand.png")
var map_mode = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), U.BG)
	if map_mode:
		var factor = minf(size.x / MAP.get_width(), size.y / MAP.get_height())
		var image_size = MAP.get_size() * factor
		draw_texture_rect(MAP, Rect2((size - image_size) * 0.5, image_size), false)
	else:
		var image_size = Vector2(size.y * 1.9, size.y * 1.2)
		var origin = Vector2(size.x - image_size.x - 10, -size.y * 0.1)
		draw_texture_rect(MAP, Rect2(origin + Vector2(-4, 1), image_size), false, Color(U.BLUE, 0.1))
		draw_texture_rect(MAP, Rect2(origin + Vector2(4, -1), image_size), false, Color(U.RED, 0.06))
		draw_texture_rect(MAP, Rect2(origin, image_size), false, Color(U.PURPLE.lightened(0.25), 0.2))
		draw_texture_rect(BRAND, Rect2(Vector2(size.x * 0.57, size.y * 0.46), Vector2(size.x * 0.34, size.x * 0.113)), false, Color(1, 1, 1, 0.065))
		for i in range(24):
			var x = size.x * 0.38 + i * size.x * 0.015
			draw_rect(Rect2(0, 0, x, size.y), Color(U.SURFACE, 0.08))
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(U.PURPLE, 0.4), 2)
		for i in range(3):
			var start = Vector2(size.x * 0.61 + i * 37, 18 + i * 12)
			draw_polyline(PackedVector2Array([start, start + Vector2(38, -13), start + Vector2(13, 30), start]), Color(U.BLUE if i % 2 else U.PURPLE, 0.15), 1)
