class_name ArenaArt
extends Control

const U = preload("res://scripts/ui.gd")
const MAP = preload("res://assets/ui/dust2_preview.png")
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
		draw_texture_rect(MAP, Rect2(Vector2(size.x - image_size.x - 10, -size.y * 0.1), image_size), false, Color(1, 1, 1, 0.15))
		for i in range(24):
			var x = size.x * 0.38 + i * size.x * 0.015
			draw_rect(Rect2(0, 0, x, size.y), Color(U.SURFACE, 0.08))
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(U.ORANGE, 0.4), 2)
