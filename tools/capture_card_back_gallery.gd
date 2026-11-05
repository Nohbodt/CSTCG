extends SceneTree

const U = preload("res://scripts/ui.gd")
const Card = preload("res://scripts/card_art.gd")
const Back = preload("res://scripts/card_back_art.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Card-back gallery requires a graphical renderer.")
		quit(1)
		return
	root.size = Vector2i(1440, 960)
	var canvas = ColorRect.new()
	canvas.color = U.BG
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.theme = U.theme()
	root.add_child(canvas)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 30)
	canvas.add_child(margin)
	var layout = U.vbox(10)
	margin.add_child(layout)
	layout.add_child(U.label("CSTCG / PACK ORIGIN CARD BACKS", 30, U.TEXT, true))
	layout.add_child(U.label("Top: current pack, starter and archive backs. Bottom: Series 1 design previews.", 14, U.MUTED))
	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 18)
	layout.add_child(grid)
	for origin in ["contender", "elite", "starter", "legacy", "s1.alpha", "s1.bravo", "s1.elite", "s1.beta_event"]:
		var tile = U.vbox(6)
		var tag = U.label("DESIGN PREVIEW" if origin.begins_with("s1.") else "PLAYABLE / " + origin.to_upper(), 10, Back.style(origin).color, true)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(tag)
		var card = Card.new()
		card.face_down = true
		card.back_origin = origin
		card.custom_minimum_size.y = 338
		tile.add_child(card)
		grid.add_child(tile)
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var output = "res://docs/screenshots/card-backs/card-back-gallery.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error = root.get_texture().get_image().save_png(output)
	print("CSTCG_BACK_GALLERY: ", error_string(error))
	quit(0 if error == OK else 1)
