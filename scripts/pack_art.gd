class_name PackArt
extends Control

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
var pack_id = "contender"
var large = false
var animate = true
var clock = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(180, 250) if not large else Vector2(260, 350)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		clock += delta
		queue_redraw()

func _draw() -> void:
	var scale_factor = minf(size.x / 240.0, size.y / 310.0)
	var offset = (size - Vector2(240, 310) * scale_factor) * 0.5
	if animate:
		offset.y += sin(clock * 1.3) * 3
	draw_set_transform(offset, -0.055, Vector2.ONE * scale_factor)
	var col = C.PACKS[pack_id].color
	draw_style_box(U.box(Color(0, 0, 0, 0.35), 4, Color(0, 0, 0, 0), 0), Rect2(24, 19, 208, 285))
	draw_colored_polygon(PackedVector2Array([Vector2(18, 4), Vector2(215, 4), Vector2(226, 293), Vector2(8, 293)]), col.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(21, 15), Vector2(213, 15), Vector2(222, 281), Vector2(12, 281)]), Color("1d232b"))
	draw_colored_polygon(PackedVector2Array([Vector2(21, 15), Vector2(125, 15), Vector2(222, 167), Vector2(222, 214), Vector2(113, 214), Vector2(17, 70)]), col)
	for i in range(12):
		draw_line(Vector2(23 + i * 17, 6), Vector2(23 + i * 17, 15), col.lightened(0.25), 1.2)
		draw_line(Vector2(15 + i * 18, 282), Vector2(15 + i * 18, 291), col.lightened(0.15), 1)
	for i in range(8):
		draw_line(Vector2(24, 125 + i * 11), Vector2(210, 82 + i * 11), Color("e8e7dc21"), 1)
	draw_string(U.BOLD, Vector2(34, 47), "CLUB CIRCUIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, U.BG)
	draw_string(U.DISPLAY, Vector2(34, 118), "C / C", HORIZONTAL_ALIGNMENT_LEFT, -1, 51, U.TEXT)
	draw_string(U.BOLD, Vector2(34, 142), "PLAYER SERIES  /  01", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, U.TEXT)
	draw_string(U.DISPLAY, Vector2(30, 226), "CONTENDER" if pack_id == "contender" else "ELITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, U.TEXT)
	draw_string(U.BOLD, Vector2(31, 247), "5 PLAYER CARDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	draw_string(U.FONT, Vector2(31, 266), "EARNED ON THE CIRCUIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, U.MUTED)
	draw_line(Vector2(201, 180), Vector2(202, 264), col, 2)
	draw_set_transform(Vector2.ZERO)
