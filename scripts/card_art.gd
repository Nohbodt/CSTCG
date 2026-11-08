class_name CardArt
extends Control

const C = preload("res://scripts/catalog.gd")
const U = preload("res://scripts/ui.gd")
const Back = preload("res://scripts/card_back_art.gd")
const Front = preload("res://scripts/card_front_art.gd")
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

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var factor = minf(size.x / 190.0, size.y / 290.0)
	var offset = (size - Vector2(190, 290) * factor) * 0.5
	draw_set_transform(offset, 0, Vector2.ONE * factor)
	if face_down:
		Back.draw(self, back_origin)
	elif not card.is_empty():
		var path = portrait_path_for(card)
		if path != _portrait_path:
			_portrait_path = path
			_portrait = load(path) if not path.is_empty() else null
		Front.draw(self, card, _portrait, fresh, selected)
	draw_set_transform(Vector2.ZERO)
