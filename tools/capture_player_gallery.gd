extends SceneTree

const C = preload("res://scripts/catalog.gd")
const U = preload("res://scripts/ui.gd")
const Card = preload("res://scripts/card_art.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Player gallery requires a graphical renderer.")
		quit(1)
		return
	var all_players = OS.get_cmdline_user_args().has("--all")
	var ids = ["yekindar", "gla1ve", "jks", "broky", "donk", "zywoo", "niko", "s1mple"]
	if all_players:
		ids.clear()
		for card in C.cards():
			ids.append(card.id)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/players/portrait_sources.json"))
	var installed = 0
	for card in C.cards():
		var path = Card.portrait_path_for(card)
		assert(path.is_empty() == manifest.missing_players.has(card.id), "Portrait coverage mismatch: " + card.id)
		if path.is_empty():
			continue
		installed += 1
		var texture = load(path)
		assert(texture is Texture2D and texture.get_width() > 0 and texture.get_height() > 0)
		var legacy = card.duplicate()
		legacy.portrait = str(card.portrait).get_basename() + ".jpg"
		assert(Card.portrait_path_for(legacy) == path, "Legacy snapshot lost its photo: " + card.id)
	assert(installed == manifest.portraits.size())
	root.size = Vector2i(1440, 1800 if all_players else 960)
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
	layout.add_child(U.label("CSTCG / PLAYER PORTRAITS", 30, U.TEXT, true))
	layout.add_child(U.label("Alpha 0.5.1 / %d real photos, %d monograms / temporary art for playtesting" % [installed, C.cards().size() - installed], 14, U.MUTED))
	var grid = GridContainer.new()
	grid.columns = 6 if all_players else 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)
	var photo_controls: Array[Card] = []
	for id in ids:
		var tile = U.vbox(4)
		var art = Card.new()
		art.card = C.card(id)
		art.custom_minimum_size.y = 296 if all_players else 346
		tile.add_child(art)
		if not Card.portrait_path_for(art.card).is_empty():
			photo_controls.append(art)
		var label = U.label("MONOGRAM" if Card.portrait_path_for(art.card).is_empty() else "TEMPORARY PHOTO", 10, U.MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)
		grid.add_child(tile)
	layout.add_child(U.label("Photo sources and replacement notes: assets/players/SOURCES.md", 12, U.MUTED))
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var captured = root.get_texture().get_image()
	# Decodable textures can still render blank if their resources are released
	# before the canvas uses their RIDs. Check the actual printed photo pixels.
	for art in photo_controls:
		var factor = minf(art.size.x / 190.0, art.size.y / 290.0)
		var offset = (art.size - Vector2(190, 290) * factor) * 0.5
		var colors = {}
		for y in range(5):
			for x in range(5):
				var point = art.global_position + offset + Vector2(60 + x * 26, 28 + y * 31) * factor
				colors[captured.get_pixelv(Vector2i(point)).to_rgba32()] = true
		assert(colors.size() > 8, "Portrait rendered blank: " + str(art.card.id))
	var output = "res://docs/screenshots/portraits/player-cards" + ("-all" if all_players else "") + ".png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error = captured.save_png(output)
	print("CSTCG_PLAYER_GALLERY: %d portraits, %d monograms; %s" % [installed, C.cards().size() - installed, error_string(error)])
	quit(0 if error == OK else 1)
