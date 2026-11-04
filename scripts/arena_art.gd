class_name ArenaArt
extends Control

const U = preload("res://scripts/ui.gd")
var map_mode = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("171e24"))
	for i in range(22):
		var x = size.x * 0.4 + i * 40
		draw_line(Vector2(x, 0), Vector2(x - 130, size.y), Color("28323a"), 1)
	for i in range(8):
		draw_line(Vector2(size.x * 0.4, i * 40), Vector2(size.x, i * 40), Color("28323a"), 1)
	if map_mode:
		var scale_factor = minf(size.x / 620.0, size.y / 330.0)
		draw_set_transform((size - Vector2(620, 330) * scale_factor) * 0.5, 0, Vector2.ONE * scale_factor)
		var rooms = [Rect2(70, 55, 125, 95), Rect2(240, 35, 100, 85), Rect2(410, 60, 130, 95), Rect2(235, 170, 155, 75), Rect2(90, 218, 100, 70), Rect2(460, 230, 90, 65)]
		for room in rooms:
			draw_rect(room, Color("28353e"))
			draw_rect(room, Color("52616b"), false, 2)
		for points in [[Vector2(195, 102), Vector2(288, 102), Vector2(288, 206)], [Vector2(340, 78), Vector2(475, 78)], [Vector2(142, 150), Vector2(142, 250), Vector2(235, 207)], [Vector2(390, 208), Vector2(503, 208), Vector2(503, 230)]]:
			draw_polyline(PackedVector2Array(points), Color("465761"), 15)
		draw_circle(Vector2(130, 100), 21, Color(U.ORANGE, 0.2))
		draw_string(U.DISPLAY, Vector2(122, 108), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, U.ORANGE)
		draw_circle(Vector2(475, 107), 21, Color(U.LIME, 0.15))
		draw_string(U.DISPLAY, Vector2(468, 115), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, U.LIME)
		for point in [Vector2(142, 256), Vector2(125, 270), Vector2(166, 255), Vector2(110, 246), Vector2(153, 239)]:
			draw_circle(point, 4, U.ORANGE)
		draw_set_transform(Vector2.ZERO)
	else:
		var center = Vector2(size.x * 0.82, size.y * 0.49)
		draw_circle(center, 110, Color(U.ORANGE, 0.035))
		draw_arc(center, 106, -PI * 0.85, PI * 0.85, 80, Color(U.ORANGE, 0.32), 1)
		draw_arc(center, 84, -PI * 0.4, PI * 1.4, 80, U.ORANGE, 2)
		draw_line(center + Vector2(-128, 0), center + Vector2(128, 0), Color(U.ORANGE, 0.35), 1)
		draw_line(center + Vector2(0, -120), center + Vector2(0, 120), Color(U.ORANGE, 0.35), 1)
		draw_string(U.DISPLAY, center + Vector2(-57, 27), "01", HORIZONTAL_ALIGNMENT_LEFT, -1, 82, U.ORANGE)
