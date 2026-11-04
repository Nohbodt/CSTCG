extends Control

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
const Card = preload("res://scripts/card_art.gd")
const Pack = preload("res://scripts/pack_art.gd")
const Arena = preload("res://scripts/arena_art.gd")
const PAGES = ["Overview", "My squad", "Pack room", "Collection", "Match room", "Trade desk"]

var body: VBoxContainer
var scroll: ScrollContainer
var credit_label: Label
var level_label: Label
var breadcrumb: Label
var nav_buttons: Array = []
var page = 0
var modal: Control
var toast_panel: PanelContainer
var toast_tween: Tween
var reduced_motion = false
var rarity_filter = -1
var role_filter = -1
var owned_only = true
var replay_timer: Timer
var replay_result: Dictionary
var replay_index = 0
var replay_score: Label
var replay_log: RichTextLabel
var replay_round: Label
var replay_economy: Label
var replay_chips: Array = []
var smoke_failures = 0

func _ready() -> void:
	theme = U.theme()
	_build_shell()
	Game.changed.connect(_refresh_header)
	_refresh_header()
	navigate(0)
	if not Game.data.pending_pack.is_empty():
		_show_pack(true)
	if not Game.last_error.is_empty():
		notify(Game.last_error)
	if "--live-match-smoke" in OS.get_cmdline_user_args():
		call_deferred("_launch_live_smoke")
	elif "--spatial-smoke" in OS.get_cmdline_user_args():
		call_deferred("_launch_spatial_smoke")
	elif "--ui-smoke" in OS.get_cmdline_user_args():
		call_deferred("_ui_smoke")

func _launch_spatial_smoke() -> void:
	# Official release templates disable CLI scene-path overrides. Exercise the
	# same menu transition a player uses instead of depending on --scene.
	if Game.save_enabled:
		printerr("Spatial smoke requires --ephemeral; refusing to change a real save.")
		get_tree().quit(1)
		return
	navigate(4)
	_smoke_press("Open 3D map lab   ↗")

func _launch_live_smoke() -> void:
	if Game.save_enabled:
		printerr("Live smoke requires --ephemeral; refusing to change a real save.")
		get_tree().quit(1)
		return
	Game.rng.seed = 77
	navigate(4)
	_smoke_press("Play match   →")
	_smoke_expect(Game.data.matches == 0 and not Game.has_active_match(), "choice does not start a match")
	_smoke_press("Play out match")

func _build_shell() -> void:
	var background = ColorRect.new()
	background.color = U.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shell = U.hbox(0)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	var side = U.vbox(12)
	side.size_flags_horizontal = Control.SIZE_FILL
	side.custom_minimum_size.x = 166
	var brand = U.hbox(10)
	var monogram = U.label("C / C", 22, U.BG, true)
	var brand_tile = U.panel(monogram, U.ORANGE, 9)
	brand_tile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	brand_tile.add_theme_stylebox_override("panel", U.box(U.ORANGE, 3, U.ORANGE, 9))
	brand.add_child(brand_tile)
	var brand_name = U.vbox(0)
	brand_name.add_child(U.label("CLUB", 15, U.TEXT, true))
	brand_name.add_child(U.label("CIRCUIT", 15, U.TEXT, true))
	brand.add_child(brand_name)
	side.add_child(brand)
	side.add_child(_gap(24))
	side.add_child(U.label("YOUR CLUB", 10, U.MUTED, true))
	for i in range(PAGES.size()):
		var index = i
		var b = U.button("%02d    %s" % [i + 1, PAGES[i]], func(): navigate(index))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 47
		b.add_theme_font_size_override("font_size", 13)
		side.add_child(b)
		nav_buttons.append(b)
	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(fill)
	var club = U.vbox(6)
	club.add_child(U.badge("NORTHLINE CLUB", U.LIME))
	club.add_child(U.label("Every legend starts somewhere.", 10, U.MUTED))
	side.add_child(club)
	side.add_child(U.divider())
	side.add_child(U.button("?   How to play", _show_help))
	var motion = CheckButton.new()
	motion.text = "Reduce motion"
	motion.add_theme_font_size_override("font_size", 11)
	motion.toggled.connect(func(on): reduced_motion = on)
	side.add_child(motion)
	side.add_child(U.label("OFFLINE ALPHA  /  v0.2", 9, U.MUTED))
	var sidebar = U.panel(side, Color("11151a"), 18)
	sidebar.size_flags_horizontal = Control.SIZE_FILL
	sidebar.add_theme_stylebox_override("panel", U.box(Color("11151a"), 0, U.BORDER, 18))
	shell.add_child(sidebar)
	var workspace = U.vbox(0)
	shell.add_child(workspace)
	var header = U.hbox(14)
	breadcrumb = U.label("CLUB / OVERVIEW", 11, U.MUTED, true)
	header.add_child(breadcrumb)
	header.add_child(U.spacer())
	header.add_child(U.badge("SEASON 01 · PRESEASON"))
	credit_label = U.label("", 14, U.TEXT, true)
	header.add_child(credit_label)
	header.add_child(U.label("|", 18, U.BORDER))
	level_label = U.label("", 12, U.MUTED)
	header.add_child(level_label)
	var top = U.panel(header, U.BG, 23)
	top.add_theme_stylebox_override("panel", U.box(U.BG, 0, U.BORDER, 23))
	workspace.add_child(top)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace.add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 30)
	scroll.add_child(margin)
	body = U.vbox(24)
	margin.add_child(body)

func _refresh_header() -> void:
	credit_label.text = "◈  %s CR" % _number(int(Game.data.credits))
	level_label.text = "NORTHLINE  /  LV. %02d" % Game.club_level()
	if not Game.last_error.is_empty():
		level_label.text += "  /  UNSAVED"
		level_label.tooltip_text = Game.last_error
	if nav_buttons.size() > 2:
		nav_buttons[2].text = "03    Pack room" + ("  [%d]" % Game.total_packs() if Game.total_packs() > 0 else "")

func _number(value: int) -> String:
	var text = str(value)
	var output = ""
	for i in range(text.length()):
		if i > 0 and (text.length() - i) % 3 == 0:
			output += ","
		output += text[i]
	return output

func _gap(height: float) -> Control:
	var gap = Control.new()
	gap.custom_minimum_size.y = height
	return gap

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func navigate(index: int) -> void:
	page = index
	_clear(body)
	scroll.scroll_vertical = 0
	breadcrumb.text = "CLUB  /  " + PAGES[index].to_upper()
	for i in range(nav_buttons.size()):
		var active = i == index
		nav_buttons[i].add_theme_stylebox_override("normal", U.box(Color("30251f") if active else Color(0, 0, 0, 0), 5, Color("6b4430") if active else Color(0, 0, 0, 0), 12))
		nav_buttons[i].add_theme_color_override("font_color", U.ORANGE if active else U.MUTED)
	if Game.has_active_match():
		var resume_row = U.hbox(14)
		resume_row.add_child(U.paragraph("DUST II MATCH IN PROGRESS\nYour lineup, collection and tactic are locked until this fixture finishes. Resume at the start of the current round.", 12, U.LIME))
		resume_row.add_child(U.button("Resume match   →", _launch_played_match, true))
		body.add_child(U.panel(resume_row))
	match index:
		0: _overview()
		1: _squad()
		2: _packs()
		3: _collection()
		4: _match_room()
		5: _trades()

func _heading(eyebrow: String, title: String, subtitle: String) -> void:
	var h = U.vbox(5)
	h.add_child(U.label(eyebrow, 10, U.ORANGE, true))
	h.add_child(U.label(title, 32, U.TEXT, true))
	h.add_child(U.paragraph(subtitle, 13))
	body.add_child(h)

func _overview() -> void:
	_heading("THE CLUBHOUSE", "Small beginnings. Big ambitions.", "Your roster, your decisions, your next breakthrough. Welcome back to Northline.")
	var hero = PanelContainer.new()
	hero.custom_minimum_size.y = 245
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", U.box(U.SURFACE, 8, U.BORDER, 0))
	var arena = Arena.new()
	hero.add_child(arena)
	var hero_margin = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		hero_margin.add_theme_constant_override("margin_" + edge, 27)
	hero.add_child(hero_margin)
	var hero_col = U.vbox(10)
	hero_margin.add_child(hero_col)
	hero_col.add_child(U.label("THE OPEN CIRCUIT  /  YOUR JOURNEY STARTS HERE", 10, U.ORANGE, true))
	hero_col.add_child(U.label("BUILD YOUR FIVE.\nOWN THE MOMENT.", 39, U.TEXT, true))
	hero_col.add_child(U.label("Collect the talent. Make the calls. Leave your mark.", 13, U.MUTED))
	var hero_buttons = U.hbox(10)
	hero_buttons.add_child(U.button("Enter match room   ↗", func(): navigate(4), true))
	hero_buttons.add_child(U.button("Open your first packs", func(): navigate(2)))
	hero_buttons.add_child(U.spacer())
	hero_col.add_child(hero_buttons)
	body.add_child(hero)
	var stats = U.hbox(12)
	_stat(stats, "SQUAD RATING", str(Game.team_rating()), "5 / 5 roles filled", U.ORANGE)
	_stat(stats, "CARD COLLECTION", "%02d / 30" % Game.unique_cards(), "%d total cards" % Game.total_cards(), U.TEXT)
	_stat(stats, "MATCH RECORD", "%d W  /  %d L" % [Game.data.wins, Game.data.matches - Game.data.wins], "Open circuit · best of one", U.TEXT)
	_stat(stats, "UNOPENED PACKS", "%02d" % Game.total_packs(), "Your next signing is waiting", U.LIME)
	body.add_child(stats)
	var lower = U.hbox(20)
	var squad = U.vbox(12)
	squad.size_flags_stretch_ratio = 2.2
	var title = U.section("YOUR STARTING FIVE", C.TACTICS[int(Game.data.tactic)])
	squad.add_child(title)
	var lineup = U.hbox(9)
	for id in Game.data.squad:
		var tile = U.vbox(6)
		var c = C.card(id)
		tile.add_child(U.label(c.role, 9, U.MUTED, true))
		var art = Card.new()
		art.card = c
		art.compact = true
		lineup.add_child(tile)
		tile.add_child(art)
	squad.add_child(lineup)
	var edit = U.button("Manage starting five   →", func(): navigate(1))
	edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	squad.add_child(edit)
	lower.add_child(squad)
	var next = U.vbox(13)
	next.size_flags_stretch_ratio = 1
	next.add_child(U.section("NEXT ON THE CIRCUIT"))
	var fixture = U.vbox(12)
	fixture.add_child(U.badge("MATCH %02d  /  BO1" % (Game.data.matches + 1)))
	fixture.add_child(U.label("NORTHLINE", 24, U.TEXT, true))
	fixture.add_child(U.label("vs. " + Game.opponent().name, 17, U.MUTED, true))
	fixture.add_child(U.divider())
	fixture.add_child(U.label(C.MAPS[int(Game.data.map)], 11, U.TEXT, true))
	fixture.add_child(U.paragraph("Play out: 160 / 85 CR\nSkip: 80 / 43 CR (win / loss)\nEvery fourth match earns a pack.", 12))
	fixture.add_child(U.button("Prepare your tactics   →", func(): navigate(4)))
	next.add_child(U.panel(fixture))
	lower.add_child(next)
	body.add_child(lower)
	var journey = U.vbox(12)
	journey.add_child(U.section("PLAY. COLLECT. BUILD.", "NO PAID CURRENCY"))
	var track = U.hbox(16)
	var steps = [["01", "Play the circuit", "Every match earns credits and club XP."], ["02", "Find your next star", "Open five-card packs with visible odds."], ["03", "Build a better five", "Trade spare cards and balance your roles."]]
	for step in steps:
		var item = U.hbox(12)
		item.add_child(U.label(step[0], 25, U.ORANGE, true))
		var text = U.vbox(3)
		text.add_child(U.label(step[1], 13, U.TEXT, true))
		text.add_child(U.paragraph(step[2], 11))
		item.add_child(text)
		track.add_child(item)
	journey.add_child(track)
	body.add_child(U.panel(journey))

func _stat(row: HBoxContainer, title: String, value: String, caption: String, color: Color) -> void:
	var content = U.vbox(6)
	content.add_child(U.label(title, 9, U.MUTED, true))
	content.add_child(U.label(value, 26, color, true))
	content.add_child(U.label(caption, 10, U.MUTED))
	row.add_child(U.panel(content, U.SURFACE, 17))

func _card_tile(id: String, actions: bool = false, show_count: bool = true) -> VBoxContainer:
	var c = C.card(id)
	var tile = U.vbox(8)
	var art = Card.new()
	art.card = c
	art.selected = id in Game.data.squad
	if Game.copies(id) == 0:
		art.modulate = Color(0.48, 0.48, 0.48, 1)
	tile.add_child(art)
	if show_count:
		var row = U.hbox(5)
		row.add_child(U.label("×%d OWNED" % Game.copies(id) if Game.copies(id) else "NOT COLLECTED", 10, U.MUTED, true))
		row.add_child(U.spacer())
		if id in Game.data.squad:
			row.add_child(U.label("IN FIVE", 9, U.ORANGE, true))
		tile.add_child(row)
	if actions and Game.copies(id) > 0:
		var equip_button = U.button("In starting five" if id in Game.data.squad else "Add to lineup  ↑", func():
			if Game.equip(id):
				notify(c.handle + " is in your starting five.")
				navigate(page)
			else:
				_action_failed())
		equip_button.disabled = id in Game.data.squad or Game.has_active_match()
		tile.add_child(equip_button)
	return tile

func _squad() -> void:
	_heading("ROSTER MANAGEMENT", "Five roles. One identity.", "Build a balanced lineup from real player identities. Alpha ratings and assigned roles are custom game values; collection series are not real teams.")
	var summary = U.hbox(12)
	_stat(summary, "EFFECTIVE RATING", str(Game.team_rating()), "Includes role and chemistry bonuses", U.ORANGE)
	_stat(summary, "ROLE COVERAGE", "5 / 5", "Entry · AWPer · IGL · Support · Lurker", U.LIME)
	_stat(summary, "ACTIVE TACTIC", C.TACTICS[int(Game.data.tactic)], "Change your approach in the match room", U.TEXT)
	body.add_child(summary)
	body.add_child(U.section("THE STARTING FIVE", "CARDS ARE NEVER CONSUMED BY PLAY"))
	var lineup = U.hbox(14)
	for i in range(5):
		var tile = U.vbox(10)
		tile.add_child(U.label("0%d / %s" % [i + 1, C.ROLES[i]], 11, U.ORANGE, true))
		tile.add_child(_card_tile(Game.data.squad[i], false, false))
		lineup.add_child(tile)
	body.add_child(lineup)
	body.add_child(U.section("AVAILABLE TO CALL UP", "SELECT A PLAYER TO REPLACE THE SAME ROLE"))
	var bench: Array = C.cards().filter(func(c): return Game.copies(c.id) > 0 and c.id not in Game.data.squad)
	bench.sort_custom(func(a, b): return a.overall > b.overall)
	if bench.is_empty():
		var empty = U.vbox(10)
		empty.add_child(U.label("The next name is still in the pack.", 20, U.TEXT, true))
		empty.add_child(U.paragraph("Your starter lineup is ready to play. Open a pack or use the trade desk to find your first substitute."))
		empty.add_child(U.button("Visit the pack room   →", func(): navigate(2), true))
		body.add_child(U.panel(empty))
	else:
		var grid = GridContainer.new()
		grid.columns = 5
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 22)
		for c in bench:
			grid.add_child(_card_tile(c.id, true))
		body.add_child(grid)

func _packs() -> void:
	_heading("PLAYER SERIES / 01", "Good clubs are built. Great cards are found.", "Five player cards in every pack. Earn credits on the circuit, collect your favorites, and upgrade your five.")
	var intro = U.hbox(10)
	intro.add_child(U.badge("%d PACKS IN YOUR LOCKER" % Game.total_packs(), U.LIME))
	intro.add_child(U.badge("EARNED CURRENCY ONLY", U.MUTED))
	intro.add_child(U.spacer())
	intro.add_child(U.label("30 PLAYERS  ·  4 RARITIES  ·  5 ROLES", 10, U.MUTED, true))
	body.add_child(intro)
	var row = U.hbox(20)
	for id in ["contender", "elite"]:
		var pack_id = id
		var pack = C.PACKS[id]
		var col = U.vbox(12)
		var top = U.hbox()
		top.add_child(U.label("SERIES 01 / PLAYER PACK", 10, U.MUTED, true))
		top.add_child(U.spacer())
		top.add_child(U.badge("×%d OWNED" % Game.data.packs[id], pack.color))
		col.add_child(top)
		var art = Pack.new()
		art.pack_id = id
		art.animate = not reduced_motion
		art.custom_minimum_size.y = 260
		col.add_child(art)
		col.add_child(U.label(pack.name, 27, U.TEXT, true))
		col.add_child(U.paragraph(pack.short, 13))
		col.add_child(U.badge("5 CARDS  /  " + pack.guarantee, pack.color))
		col.add_child(U.divider())
		var buttons = U.hbox(10)
		var open = U.button("Open pack   ↗" if Game.data.packs[id] > 0 else "No packs owned", func(): _open_pack(pack_id), true)
		open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		open.disabled = Game.data.packs[id] <= 0 or Game.has_active_match()
		buttons.add_child(open)
		var buy = U.button("Get pack · %d CR" % pack.price, func():
			if Game.purchase_pack(pack_id):
				notify(pack.name + " added to your locker.")
				navigate(2)
			else:
				_action_failed())
		buy.disabled = Game.data.credits < pack.price or Game.has_active_match()
		buttons.add_child(buy)
		col.add_child(buttons)
		row.add_child(U.panel(col, U.SURFACE, 22))
	body.add_child(row)
	var odds = U.vbox(12)
	odds.add_child(U.section("KNOW YOUR ODDS", "NO HIDDEN MODIFIERS. NO PITY COUNTER."))
	var table = GridContainer.new()
	table.columns = 5
	table.add_theme_constant_override("h_separation", 26)
	table.add_theme_constant_override("v_separation", 10)
	for heading in ["PACK / SLOT", "COMMON", "RARE", "EPIC", "LEGENDARY"]:
		var label = U.label(heading, 10, U.MUTED, true)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		table.add_child(label)
	for id in ["contender", "elite"]:
		for slot in ["base_weights", "last_weights"]:
			table.add_child(U.label(C.PACKS[id].name + (" · Cards 1–4" if slot == "base_weights" else " · Card 5"), 11))
			for i in range(4):
				table.add_child(U.label("%d%%" % C.PACKS[id][slot][i], 12, C.COLORS[i], true))
	odds.add_child(table)
	odds.add_child(U.paragraph("A player is selected uniformly within the rolled rarity. Duplicates are possible, including within one pack. The fifth card uses its own guaranteed-rarity odds.", 11))
	body.add_child(U.panel(odds))

func _collection() -> void:
	_heading("THE BINDER", "Every card has a place.", "Explore the complete Series 01 set. Keep a favorite, make a substitution, or turn a spare into your next pack.")
	var filters = U.hbox(10)
	var rarity = OptionButton.new()
	rarity.custom_minimum_size = Vector2(170, 44)
	rarity.add_item("All rarities")
	for r in C.RARITIES:
		rarity.add_item(r.capitalize())
	rarity.selected = rarity_filter + 1
	rarity.item_selected.connect(func(i):
		rarity_filter = i - 1
		navigate(3))
	filters.add_child(rarity)
	var role = OptionButton.new()
	role.custom_minimum_size = Vector2(160, 44)
	role.add_item("All roles")
	for r in C.ROLES:
		role.add_item(r)
	role.selected = role_filter + 1
	role.item_selected.connect(func(i):
		role_filter = i - 1
		navigate(3))
	filters.add_child(role)
	var owned = CheckButton.new()
	owned.text = "Owned only"
	owned.button_pressed = owned_only
	owned.toggled.connect(func(value):
		owned_only = value
		navigate(3))
	filters.add_child(owned)
	filters.add_child(U.spacer())
	filters.add_child(U.label("%d / 30 COLLECTED" % Game.unique_cards(), 12, U.LIME, true))
	body.add_child(filters)
	var cards = C.cards().filter(func(c): return (not owned_only or Game.copies(c.id) > 0) and (rarity_filter == -1 or c.rarity == rarity_filter) and (role_filter == -1 or c.role == C.ROLES[role_filter]))
	cards.sort_custom(func(a, b): return a.overall > b.overall)
	if cards.is_empty():
		body.add_child(U.panel(U.paragraph("No cards match these filters. Try another role or rarity, or turn off 'Owned only' to explore the full set.")))
		return
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 24)
	for c in cards:
		var id = c.id
		var tile = _card_tile(id, true)
		if Game.copies(id) > 0:
			var sell = U.button("Release 1 · +%d CR" % C.QUICK_SELL[c.rarity], func(): _confirm_release(id))
			sell.disabled = not Game.can_release(id)
			sell.tooltip_text = "One copy of every active player is protected."
			tile.add_child(sell)
		grid.add_child(tile)
	body.add_child(grid)

func _match_room() -> void:
	_heading("THE OPEN CIRCUIT", "Your five. Your call.", "Choose your approach, then watch your players compete on Dust II or skip to a quick result for fewer rewards.")
	var fixture = U.hbox(30)
	var own = U.vbox(4)
	own.add_child(U.label("YOUR CLUB", 10, U.MUTED, true))
	own.add_child(U.label("NORTHLINE", 30, U.TEXT, true))
	own.add_child(U.label("%d EFFECTIVE RATING" % Game.team_rating(), 12, U.ORANGE, true))
	fixture.add_child(own)
	fixture.add_child(U.spacer())
	fixture.add_child(U.label("VS", 22, U.MUTED, true))
	fixture.add_child(U.spacer())
	var away = U.vbox(4)
	away.add_child(U.label("MATCH %02d / OPPONENT" % (Game.data.matches + 1), 10, U.MUTED, true))
	away.add_child(U.label(Game.opponent().name, 30, U.TEXT, true))
	away.add_child(U.label("%d RATING  ·  %s" % [Game.opponent().rating, C.TACTICS[Game.opponent().tactic]], 11, U.MUTED, true))
	fixture.add_child(away)
	body.add_child(U.panel(fixture, U.SURFACE, 26))
	var row = U.hbox(22)
	var preparation = U.vbox(14)
	preparation.size_flags_stretch_ratio = 1.4
	preparation.add_child(U.section("01 / PICK THE BATTLEGROUND"))
	var map_buttons = U.hbox(7)
	for i in range(C.MAPS.size()):
		var index = i
		var b = U.button(C.MAPS[i].replace("DE / ", ""), func():
			if Game.set_strategy(index, int(Game.data.tactic)):
				navigate(4)
			else:
				_action_failed(), i == Game.data.map)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = Game.has_active_match()
		b.add_theme_font_size_override("font_size", 11)
		map_buttons.add_child(b)
	preparation.add_child(map_buttons)
	var map_panel = PanelContainer.new()
	map_panel.custom_minimum_size.y = 260
	map_panel.clip_contents = true
	var map_art = Arena.new()
	map_art.map_mode = true
	map_panel.add_child(map_art)
	preparation.add_child(map_panel)
	preparation.add_child(U.paragraph("DUST II · THE ALPHA BATTLEGROUND\nPlay out on the uploaded 3D map. More maps will arrive in future builds. Diagram shown here is decorative.", 11))
	row.add_child(preparation)
	var strategy = U.vbox(14)
	strategy.add_child(U.section("02 / SET YOUR APPROACH"))
	for i in range(3):
		var tactic = i
		var block = U.vbox(5)
		var b = U.button(("●  " if Game.data.tactic == i else "○  ") + C.TACTICS[i], func():
			if Game.set_strategy(int(Game.data.map), tactic):
				navigate(4)
			else:
				_action_failed())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = Game.has_active_match()
		if Game.data.tactic == i:
			b.add_theme_color_override("font_color", U.ORANGE)
		block.add_child(b)
		block.add_child(U.paragraph(["A measured site attack and balanced stat weights.", "Faster pressure; favors B-site executes and aim.", "Slower setup with a mid player; favors game sense and utility."][i], 11))
		strategy.add_child(block)
	strategy.add_child(U.divider())
	strategy.add_child(U.paragraph("MR12 regulation · first to 13\n12–12 triggers MR3 overtime\nEquipment economy + CT/T side advantage", 12))
	row.add_child(U.panel(strategy))
	body.add_child(row)
	var launch = U.hbox(16)
	var reward = U.vbox(4)
	reward.add_child(U.label("EVERY MATCH MOVES YOU FORWARD", 11, U.LIME, true))
	reward.add_child(U.paragraph("Play out: 160 / 85 CR · 100 / 60 XP (win / loss)    |    Skip: 50% credits & XP", 12, U.MUTED))
	reward.add_child(U.label("%d / 4 matches toward your next Contender pack" % (int(Game.data.matches) % 4), 11, U.MUTED))
	launch.add_child(reward)
	launch.add_child(U.spacer())
	launch.add_child(U.button("Resume match   →" if Game.has_active_match() else "Play match   →", _play_match, true))
	body.add_child(U.panel(launch))
	var map_preview = U.hbox(14)
	map_preview.add_child(U.paragraph("Dust II map preview · explore the uploaded 3D geometry, routes, and sightlines.", 12))
	map_preview.add_child(U.button("Open 3D map lab   ↗", func(): get_tree().change_scene_to_file("res://scenes/spatial_lab.tscn")))
	body.add_child(U.panel(map_preview, U.SURFACE, 14))
	if not Game.data.history.is_empty():
		body.add_child(U.section("RECENT RESULTS", "REWARDS ARE GRANTED ONCE PER MATCH"))
		for i in range(mini(Game.data.history.size(), 4)):
			var result = Game.data.history[i]
			var history_row = U.hbox()
			history_row.add_child(U.badge("WIN" if result.won else "LOSS", U.LIME if result.won else U.ORANGE))
			history_row.add_child(U.label("NORTHLINE  %d : %d  %s" % [result.score[0], result.score[1], result.opponent.name], 13, U.TEXT, true))
			history_row.add_child(U.spacer())
			history_row.add_child(U.label("+%d CR" % result.reward, 12, U.MUTED))
			history_row.add_child(U.button("View result", func(): _show_match(result, false)))
			body.add_child(U.panel(history_row, U.SURFACE, 10))

func _trades() -> void:
	_heading("THE TRADE DESK", "Your spare. Someone else's missing piece.", "Exchange cards with local AI managers. Every offer is one-for-one, with no fees and no real-money market.")
	var note = U.hbox(14)
	note.add_child(U.badge("LOCAL AI OFFERS"))
	note.add_child(U.paragraph("Offers refresh after every four matches. One copy of each active player stays protected. Trades are final.", 12))
	body.add_child(U.panel(note))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	for offer in Game.offers():
		var key = offer.key
		var col = U.vbox(13)
		col.add_child(U.section(offer.manager, "COMPLETED" if offer.used else "OPEN OFFER"))
		var cards = U.hbox(14)
		var give = U.vbox(6)
		give.add_child(U.label("YOU GIVE / ×1", 10, U.MUTED, true))
		var give_art = Card.new()
		give_art.card = C.card(offer.give)
		give_art.compact = true
		give.add_child(give_art)
		cards.add_child(give)
		cards.add_child(U.label("⇄", 28, U.ORANGE, true))
		var receive = U.vbox(6)
		receive.add_child(U.label("YOU RECEIVE / ×1", 10, U.LIME, true))
		var receive_art = Card.new()
		receive_art.card = C.card(offer.receive)
		receive_art.compact = true
		receive.add_child(receive_art)
		cards.add_child(receive)
		col.add_child(cards)
		var available = Game.can_release(offer.give)
		col.add_child(U.paragraph("You own %d × %s%s" % [Game.copies(offer.give), C.card(offer.give).handle, " · 1 reserved in your lineup" if offer.give in Game.data.squad else ""], 11))
		var accept = U.button("Trade completed" if offer.used else ("Accept trade   ⇄" if available else "Spare " + C.card(offer.give).handle + " required"), func(): _confirm_trade(key), available and not offer.used)
		accept.disabled = offer.used or not available
		col.add_child(accept)
		grid.add_child(U.panel(col))
	body.add_child(grid)

func _modal_base() -> VBoxContainer:
	_close_modal()
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_theme_stylebox_override("panel", U.box(Color("0c1018"), 0, U.BORDER, 36))
	add_child(modal)
	var modal_scroll = ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(modal_scroll)
	var content = U.vbox(22)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.add_child(content)
	return content

func _close_modal() -> void:
	if is_instance_valid(replay_timer):
		replay_timer.stop()
		replay_timer.queue_free()
		replay_timer = null
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null

func _open_pack(id: String) -> void:
	if Game.open_pack(id):
		_show_pack(true)
	else:
		_action_failed()

func _show_pack(sealed: bool = false) -> void:
	var pending = Game.data.pending_pack
	if pending.is_empty():
		return
	var pack = C.PACKS[pending.pack_id]
	var content = _modal_base()
	content.add_child(U.section("PACK ROOM / " + pack.name, "PLAYER SERIES 01"))
	var title = U.label("Your next five possibilities.", 39, U.TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var subtitle = U.label(pack.guarantee + "  /  5 PLAYER CARDS", 11, pack.color, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)
	if sealed and pending.revealed == 0:
		var art = Pack.new()
		art.pack_id = pending.pack_id
		art.large = true
		art.animate = not reduced_motion
		art.custom_minimum_size.y = 380
		content.add_child(art)
		var tear = U.button("Tear open   →", func(): _tear_pack(art), true)
		tear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tear.custom_minimum_size.x = 240
		content.add_child(tear)
		var tip = U.label("Your cards are already secured. Closing the game will preserve this pack.", 12, U.MUTED)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(tip)
		return
	content.add_child(_gap(15))
	var row = U.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(5):
		var tile = U.vbox(10)
		var art = Card.new()
		art.card = C.card(pending.cards[i])
		art.face_down = i >= pending.revealed
		art.fresh = pending.new_flags[i]
		art.custom_minimum_size.y = 350
		tile.add_child(art)
		var info = U.label("%02d / UNREVEALED" % (i + 1) if art.face_down else ("NEW SIGNING" if pending.new_flags[i] else "DUPLICATE · KEEP OR TRADE"), 10, U.MUTED if art.face_down else C.COLORS[art.card.rarity], true)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(info)
		if i == 4:
			var guarantee = U.label("GUARANTEED SLOT", 9, pack.color)
			guarantee.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(guarantee)
		row.add_child(tile)
	content.add_child(row)
	content.add_child(_gap(20))
	var buttons = U.hbox(12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	if pending.revealed < 5:
		buttons.add_child(U.button("Reveal card %d / 5   →" % (pending.revealed + 1), func(): _reveal(false), true))
		buttons.add_child(U.button("Reveal all", func(): _reveal(true)))
	else:
		buttons.add_child(U.button("Build your five   →", func(): _finish_pack(1), true))
		buttons.add_child(U.button("Back to pack room", func(): _finish_pack(2)))
	content.add_child(buttons)
	var footer = U.label("Cards are in your collection. Duplicates can be traded or released for credits.", 12, U.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(footer)

func _tear_pack(art: Control) -> void:
	if art.has_meta("tearing"):
		return
	art.set_meta("tearing", true)
	if reduced_motion:
		_show_pack()
		return
	art.pivot_offset = art.size * 0.5
	var tween = create_tween().set_parallel(true)
	tween.tween_property(art, "scale", Vector2(1.08, 1.08), 0.18)
	tween.tween_property(art, "modulate:a", 0.0, 0.25).set_delay(0.1)
	tween.chain().tween_callback(func(): _show_pack())

func _reveal(all_cards: bool) -> void:
	if Game.reveal_cards(all_cards):
		_show_pack()
	else:
		_action_failed()

func _finish_pack(destination: int) -> void:
	if Game.finish_pack():
		_close_modal()
		navigate(destination)
		notify("Five cards added. Make your next move.")
	else:
		_action_failed()

func _play_match() -> void:
	if Game.has_active_match():
		_launch_played_match()
		return
	if not Game.data.pending_pack.is_empty():
		_action_failed()
		return
	var content = _modal_base()
	content.add_child(_gap(70))
	content.add_child(U.section("MATCH %02d / DUST II" % (Game.data.matches + 1), "NORTHLINE VS " + Game.opponent().name))
	content.add_child(U.label("How do you want to play?", 38, U.TEXT, true))
	content.add_child(U.paragraph("Your lineup and tactic are ready. Both modes count toward your next pack reward.", 15))
	var choices = U.hbox(22)
	var played = U.vbox(16)
	played.add_child(U.badge("FULL REWARDS", U.LIME))
	played.add_child(U.label("Watch your five compete.", 25, U.TEXT, true))
	played.add_child(U.paragraph("A 3D automatic match on Dust II. Follow players, change cameras, pause, and control playback speed. Movement, fights, and the bomb determine the result.", 14))
	played.add_child(U.label("WIN   +160 CR / +100 XP\nLOSS   +85 CR / +60 XP", 14, U.LIME, true))
	played.add_child(U.paragraph("About 3 minutes at 8×. Completed rounds save automatically.", 12))
	played.add_child(U.button("Play out match", _begin_played_match, true))
	choices.add_child(U.panel(played, U.SURFACE, 26))
	var skipped = U.vbox(16)
	skipped.add_child(U.badge("50% CREDITS & XP", U.ORANGE))
	skipped.add_child(U.label("Go straight to the report.", 25, U.TEXT, true))
	skipped.add_child(U.paragraph("The quick round simulation resolves your fixture immediately. Review the score, round feed, and standout player, then get back to building your club.", 14))
	skipped.add_child(U.label("WIN   +80 CR / +50 XP\nLOSS   +43 CR / +30 XP", 14, U.ORANGE, true))
	skipped.add_child(U.paragraph("Instant result. The same pack milestone progress.", 12))
	skipped.add_child(U.button("Skip to result (less rewards)", _skip_match))
	choices.add_child(U.panel(skipped, U.SURFACE, 26))
	content.add_child(choices)
	content.add_child(U.button("Cancel", _close_modal))

func _begin_played_match() -> void:
	if Game.begin_spatial_match():
		_launch_played_match()
	else:
		_action_failed()

func _launch_played_match() -> void:
	get_tree().change_scene_to_file("res://scenes/played_match.tscn")

func _skip_match() -> void:
	var result = Game.skip_match()
	if result.is_empty():
		_action_failed()
	else:
		_show_match(result, false)

func _show_match(result: Dictionary, animate: bool) -> void:
	replay_result = result
	replay_index = 0
	replay_chips = []
	var content = _modal_base()
	content.add_child(U.section("THE OPEN CIRCUIT / MATCH REPORT", C.map_label(result) + " / " + str(result.get("mode", "legacy")).to_upper()))
	var score = U.hbox(30)
	score.alignment = BoxContainer.ALIGNMENT_CENTER
	score.add_child(U.label("NORTHLINE", 32, U.TEXT, true))
	replay_score = U.label("00 : 00", 53, U.ORANGE, true)
	score.add_child(replay_score)
	score.add_child(U.label(result.opponent.name, 32, U.TEXT, true))
	content.add_child(score)
	replay_round = U.label("ROUND 01 / REGULATION", 12, U.MUTED, true)
	replay_round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(replay_round)
	var grid = GridContainer.new()
	grid.columns = mini(result.rounds.size(), 24)
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	for i in range(result.rounds.size()):
		var chip = U.label(str(i + 1), 10, U.MUTED, true)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var panel = U.panel(chip, U.SURFACE, 6)
		panel.custom_minimum_size = Vector2(36, 32)
		grid.add_child(panel)
		replay_chips.append(panel)
	content.add_child(grid)
	var replay_row = U.hbox(20)
	var map_panel = PanelContainer.new()
	map_panel.custom_minimum_size.y = 260
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var arena = Arena.new()
	arena.map_mode = true
	map_panel.add_child(arena)
	replay_row.add_child(map_panel)
	var log_col = U.vbox(10)
	log_col.add_child(U.section("ROUND FEED", "QUICK SIMULATION" if result.get("mode") == "skipped" else "SAVED REPORT"))
	replay_log = RichTextLabel.new()
	replay_log.bbcode_enabled = true
	replay_log.custom_minimum_size = Vector2(420, 235)
	replay_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	replay_log.add_theme_font_size_override("normal_font_size", 13)
	replay_log.scroll_following = true
	log_col.add_child(replay_log)
	replay_row.add_child(U.panel(log_col))
	content.add_child(replay_row)
	replay_economy = U.label("Team equipment budgets: 800 / 800", 12, U.MUTED)
	content.add_child(replay_economy)
	var controls = U.hbox(12)
	controls.name = "ReplayControls"
	content.add_child(controls)
	if animate and not reduced_motion:
		controls.add_child(U.button("Skip to result   →", _complete_replay))
		replay_timer = Timer.new()
		replay_timer.wait_time = 0.18
		replay_timer.timeout.connect(_advance_round)
		add_child(replay_timer)
		replay_timer.start()
	else:
		_complete_replay()

func _advance_round() -> void:
	if replay_index >= replay_result.rounds.size():
		_complete_replay()
		return
	var round_data = replay_result.rounds[replay_index]
	replay_score.text = "%02d : %02d" % [round_data.score[0], round_data.score[1]]
	replay_round.text = "ROUND %02d / %s / NORTHLINE ON %s" % [round_data.number, "OVERTIME" if round_data.number > 24 else "REGULATION", "CT" if round_data.ct else "T"]
	var col = U.LIME if round_data.winner == 0 else U.ORANGE
	replay_chips[replay_index].add_theme_stylebox_override("panel", U.box(Color(col, 0.12), 3, Color(col, 0.4), 6))
	replay_log.append_text("[color=#%s]R%02d  %s[/color]  %s\n\n" % [col.to_html(false), round_data.number, "WIN" if round_data.winner == 0 else "LOSS", round_data.detail])
	replay_economy.text = "Next-round equipment budgets: %d / %d" % [round_data.cash[0], round_data.cash[1]]
	if round_data.chance >= 0:
		replay_economy.text += "  ·  Quick simulation round chance: %d%%" % (round_data.chance * 100)
	replay_index += 1
	if replay_index >= replay_result.rounds.size():
		_complete_replay()

func _complete_replay() -> void:
	if is_instance_valid(replay_timer):
		replay_timer.stop()
	while replay_index < replay_result.rounds.size():
		# Advance without recursion into completion for the final round.
		var r = replay_result.rounds[replay_index]
		var col = U.LIME if r.winner == 0 else U.ORANGE
		replay_chips[replay_index].add_theme_stylebox_override("panel", U.box(Color(col, 0.12), 3, Color(col, 0.4), 6))
		replay_log.append_text("[color=#%s]R%02d  %s[/color]  %s\n\n" % [col.to_html(false), r.number, "WIN" if r.winner == 0 else "LOSS", r.detail])
		replay_index += 1
	replay_score.text = "%02d : %02d" % [replay_result.score[0], replay_result.score[1]]
	replay_round.text = ("VICTORY" if replay_result.won else "DEFEAT") + " / " + str(replay_result.rounds.size()) + " ROUNDS" + (" / DECIDING ROUND AFTER SIX OVERTIMES" if replay_result.sudden_death else "")
	replay_round.add_theme_color_override("font_color", U.LIME if replay_result.won else U.ORANGE)
	replay_economy.text = "Rewards saved: +%d CR  /  +%d XP   ·   Your standout: %s (%d eliminations)" % [replay_result.reward, replay_result.xp, C.card(replay_result.mvp).handle, replay_result.kills[replay_result.mvp]]
	var controls = modal.find_child("ReplayControls", true, false)
	_clear(controls)
	controls.add_child(U.button("Back to the club   →", func():
		_close_modal()
		navigate(0), true))
	controls.add_child(U.button("Find your next signing", func():
		_close_modal()
		navigate(2)))
	if not replay_result.earned_pack.is_empty():
		controls.add_child(U.badge("CIRCUIT REWARD / +1 CONTENDER PACK" + (" +1 ELITE" if replay_result.earned_pack == "both" else "")))

func _confirm_release(id: String) -> void:
	var c = C.card(id)
	_confirm("Release one " + c.handle + "?", "You will receive %d CR. This copy leaves your collection. Any copy in your starting five remains protected." % C.QUICK_SELL[c.rarity], "Release card", func():
		if Game.quick_sell(id):
			_close_modal()
			navigate(3)
			notify("Released one " + c.handle + ". Credits received.")
		else:
			_action_failed())

func _confirm_trade(key: String) -> void:
	for offer in Game.offers():
		if offer.key != key:
			continue
		_confirm("Make the exchange?", "Give one %s and receive one %s. This local AI trade is final. Your active lineup is protected." % [C.card(offer.give).handle, C.card(offer.receive).handle], "Confirm trade", func():
			if Game.trade(key):
				_close_modal()
				navigate(5)
				notify("Trade complete. Your new card is in the binder.")
			else:
				_action_failed())
		return

func _confirm(title: String, detail: String, action: String, callback: Callable) -> void:
	var content = _modal_base()
	content.add_child(_gap(130))
	content.add_child(U.label(title, 34, U.TEXT, true))
	content.add_child(U.paragraph(detail, 16))
	var buttons = U.hbox()
	buttons.add_child(U.button(action, callback, true))
	buttons.add_child(U.button("Cancel", _close_modal))
	buttons.add_child(U.spacer())
	content.add_child(buttons)

func _show_help() -> void:
	var content = _modal_base()
	content.add_child(U.label("Welcome to the circuit.", 38, U.TEXT, true))
	content.add_child(U.paragraph("A single-player Counter-Strike-inspired club manager and card collector with real public player identities. Ratings, roles, and collection series are alpha game tuning. This independent prototype is not affiliated with Valve or the players.", 15))
	var steps = [
		["01 / OPEN YOUR STARTER PACKS", "Two Contender packs are already in your locker. Each contains five cards with a Rare-or-better fifth card. Pack contents are saved before reveal."],
		["02 / BUILD YOUR FIVE", "Use My squad or Collection to add a player. The new card replaces the same role; the old player stays in your collection."],
		["03 / PREPARE AND PLAY", "Set your tactic in Match room. Play out match watches an automatic 3D Dust II match with movement, combat, and the bomb objective. Pause, change cameras, follow players, or speed up to 16×. Return to club resumes from the start of the current round."],
		["04 / EARN YOUR NEXT SIGNING", "Played match: win 160 CR / 100 XP; loss 85 CR / 60 XP. Skip to result: win 80 CR / 50 XP; loss 43 CR / 30 XP. Every fourth completed match earns a Contender pack; every twelfth also earns an Elite pack. Rewards save once at full time."],
		["05 / MAKE THE EXCHANGE", "Trade spare cards with local AI managers or release them for credits. One active copy is always protected. Offers refresh every four matches."],
		["A NOTE ON THIS BUILD", "This is an offline prototype with local JSON saves. Online trading, ranked play, player contracts, licensed rosters, and paid purchases are not implemented. Headless simulation is supported; visual play requires a desktop display."]]
	for step in steps:
		var col = U.vbox(7)
		col.add_child(U.label(step[0], 12, U.ORANGE, true))
		col.add_child(U.paragraph(step[1], 14))
		content.add_child(U.panel(col))
	content.add_child(U.button("Back to my club   →", _close_modal, true))

func _action_failed() -> void:
	notify(Game.last_error if not Game.last_error.is_empty() else "That action is unavailable. Check your credits, cards, or unopened reveal.")

func notify(message: String) -> void:
	if is_instance_valid(toast_panel):
		toast_panel.queue_free()
	if toast_tween:
		toast_tween.kill()
	var text = U.paragraph(message, 13, U.TEXT)
	toast_panel = U.panel(text, U.RAISED, 15)
	toast_panel.custom_minimum_size = Vector2(500, 56)
	toast_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_panel.offset_left = -550
	toast_panel.offset_right = -24
	toast_panel.offset_top = -90
	toast_panel.offset_bottom = -24
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_panel)
	toast_tween = create_tween()
	toast_tween.tween_interval(4.0)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(toast_panel.queue_free)

func _ui_smoke() -> void:
	# Invoked only with --ui-smoke --ephemeral. Exercise actual scene transitions.
	if Game.save_enabled:
		push_error("UI smoke requires --ephemeral; refusing to change a real save.")
		get_tree().quit(1)
		return
	Game.rng.seed = 2026
	reduced_motion = true
	for index in range(6):
		nav_buttons[index].pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		if body.get_child_count() == 0:
			push_error("Empty page: " + PAGES[index])
			get_tree().quit(1)
			return
		await _capture("%02d_%s" % [index, PAGES[index].to_snake_case()])
	navigate(2)
	_smoke_press("Get pack · 200 CR")
	_smoke_expect(Game.data.credits == 600 and Game.data.packs.contender == 3, "pack purchase button updates wallet and locker")
	_smoke_press("Open pack   ↗")
	await get_tree().process_frame
	await _capture("06_sealed_pack")
	_smoke_press("Tear open   →")
	_smoke_expect(Game.data.pending_pack.revealed == 0, "tearing pack does not skip the reveal")
	_smoke_press("Reveal card 1 / 5   →")
	_smoke_expect(Game.data.pending_pack.revealed == 1, "single reveal button")
	_smoke_press("Reveal all")
	_smoke_expect(Game.data.pending_pack.revealed == 5, "reveal all button")
	await get_tree().process_frame
	await _capture("07_pack_reveal")
	_smoke_press("Build your five   →")
	_smoke_expect(Game.data.pending_pack.is_empty() and page == 1, "pack completion returns to roster")
	var bench = C.cards().filter(func(c): return Game.copies(c.id) > 0 and c.id not in Game.data.squad)
	if not bench.is_empty():
		var total_before = Game.total_cards()
		_smoke_press("Add to lineup  ↑")
		_smoke_expect(Game.total_cards() == total_before, "substitution preserves card ownership")
	navigate(5)
	var before_trade = Game.data.duplicate(true)
	_smoke_press("Accept trade   ⇄")
	_smoke_press("Cancel")
	_smoke_expect(Game.data == before_trade, "trade cancellation preserves state")
	_smoke_press("Accept trade   ⇄")
	_smoke_press("Confirm trade")
	_smoke_expect(Game.total_cards() == int(before_trade.cards.values().reduce(func(a, b): return a + b, 0)) and Game.offers()[0].used, "confirmed trade transfers exactly one card each way")
	navigate(4)
	_smoke_press("DUST II")
	_smoke_press("○  FAST EXECUTE")
	_smoke_expect(Game.data.map == 0 and Game.data.tactic == 1, "Dust II and tactic buttons update simulation inputs")
	_smoke_press("Play match   →")
	_smoke_expect(Game.data.matches == 0, "opening chooser grants no result")
	await _capture("08_match_choice")
	_smoke_press("Cancel")
	_smoke_expect(Game.data.matches == 0, "cancelling chooser preserves fixture")
	_smoke_press("Play match   →")
	_smoke_press("Skip to result (less rewards)")
	await get_tree().process_frame
	_smoke_expect(Game.data.matches == 1, "launching match grants one result")
	await get_tree().process_frame
	await _capture("08_match_result")
	_smoke_press("Back to the club   →")
	navigate(4)
	var wallet = Game.data.credits
	_smoke_press("View result")
	_smoke_expect(Game.data.matches == 1 and Game.data.credits == wallet, "viewing history never grants rewards again")
	_smoke_press("Back to the club   →")
	# History playback remains available without repeating settlement.
	reduced_motion = false
	navigate(4)
	_smoke_press("Play match   →")
	_smoke_press("Skip to result (less rewards)")
	_show_match(Game.data.history[0], true)
	if is_instance_valid(replay_timer):
		replay_timer.stop()
		while replay_index < replay_result.rounds.size():
			_advance_round()
	_smoke_expect(Game.data.matches == 2 and replay_index == replay_result.rounds.size(), "animated round advancement reaches the same saved report")
	_smoke_press("Back to the club   →")
	_show_help()
	await get_tree().process_frame
	_smoke_press("Back to my club   →")
	print("CSTCG_UI_SMOKE: 6 pages, purchase, pack reveal, substitution, trade, tactics, match, history, help; %d failures" % smoke_failures)
	get_tree().quit(0 if smoke_failures == 0 else 1)

func _smoke_expect(condition: bool, message: String) -> void:
	if not condition:
		smoke_failures += 1
		printerr("UI FAIL: " + message)

func _smoke_press(text: String) -> void:
	var scope = modal if is_instance_valid(modal) else body
	var b = _find_button(scope, text)
	_smoke_expect(b != null and not b.disabled, "available button: " + text)
	if b != null and not b.disabled:
		b.pressed.emit()

func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_button(child, text)
		if result != null:
			return result
	return null

func _capture(filename: String) -> void:
	var directory = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			directory = arg.trim_prefix("--capture-dir=")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	get_viewport().get_texture().get_image().save_png(directory.path_join(filename + ".png"))
