extends Control

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
const Card = preload("res://scripts/card_art.gd")
const Pack = preload("res://scripts/pack_art.gd")
const Arena = preload("res://scripts/arena_art.gd")
const PAGES = ["Overview", "Squad", "Packs", "Collection", "Matches", "Trades"]
const NAV_WIDTH = 196

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
var modal_panel: PanelContainer
var modal_return_focus: Control
var modal_width = 1040.0
var modal_height = 700.0
var page_margin: MarginContainer
var club_xp: Label
var club_progress: ProgressBar
var motion_control: CheckButton
var page_tween: Tween
var reveal_tween: Tween
var narrow_layout = false
var search_query = ""
var sort_mode = 0
var collection_grid: GridContainer
var collection_count: Label
var resize_queued = false

func _ready() -> void:
	theme = U.theme()
	_load_preferences()
	narrow_layout = size.x < 1280
	_build_shell()
	resized.connect(_queue_resize)
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
	_show_help()
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
	var side = U.vbox(6)
	var brand = U.vbox(0)
	brand.add_child(U.label("CSTCG", 29, U.TEXT, true))
	brand.add_child(U.label("THE CLUB MANAGER", 9, U.ORANGE, true))
	side.add_child(brand)
	side.add_child(_gap(12))
	nav_buttons.resize(PAGES.size())
	for group in [["CLUB", [0, 1, 4]], ["COLLECT", [2, 3, 5]]]:
		side.add_child(U.label(group[0], 10, U.MUTED, true))
		for index in group[1]:
			var destination = int(index)
			var button = U.button(PAGES[index], func(): navigate(destination))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size.y = 40
			button.add_theme_font_size_override("font_size", 13)
			side.add_child(button)
			nav_buttons[index] = button
		side.add_child(_gap(6))
	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(fill)
	side.add_child(U.divider())
	side.add_child(U.label("NORTHLINE CLUB", 11, U.TEXT, true))
	club_xp = U.label("", 11, U.MUTED)
	side.add_child(club_xp)
	club_progress = ProgressBar.new()
	club_progress.custom_minimum_size.y = 4
	club_progress.max_value = 250
	club_progress.show_percentage = false
	club_progress.add_theme_stylebox_override("background", U.box(U.RAISED, 2, U.RAISED, 0))
	club_progress.add_theme_stylebox_override("fill", U.box(U.ORANGE, 2, U.ORANGE, 0))
	side.add_child(club_progress)
	side.add_child(_gap(8))
	side.add_child(U.button("Help & settings", _show_help))
	motion_control = CheckButton.new()
	motion_control.text = "Reduce motion"
	motion_control.button_pressed = reduced_motion
	motion_control.tooltip_text = "Use still pack art and immediate reveals. Match playback controls remain available."
	motion_control.add_theme_font_size_override("font_size", 11)
	motion_control.toggled.connect(_set_reduced_motion)
	side.add_child(motion_control)
	side.add_child(U.label("OFFLINE ALPHA / v0.3", 9, U.MUTED))
	var sidebar = U.panel(side, Color("0f1722"), 16)
	sidebar.custom_minimum_size.x = NAV_WIDTH
	sidebar.size_flags_horizontal = Control.SIZE_FILL
	sidebar.add_theme_stylebox_override("panel", U.box(Color("0f1722"), 0, U.BORDER, 16))
	shell.add_child(sidebar)
	var workspace = U.vbox(0)
	shell.add_child(workspace)
	var header = U.hbox(14)
	breadcrumb = U.label("CLUB / OVERVIEW", 11, U.MUTED, true)
	header.add_child(breadcrumb)
	header.add_child(U.spacer())
	header.add_child(U.badge("OPEN CIRCUIT", U.BLUE))
	credit_label = U.label("", 14, U.GOLD, true)
	var wallet = U.panel(credit_label, Color(U.GOLD, 0.05), 8)
	wallet.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(wallet)
	level_label = U.label("", 11, U.MUTED)
	header.add_child(level_label)
	var top = U.panel(header, U.BG, 16)
	top.add_theme_stylebox_override("panel", U.box(U.BG, 0, U.BORDER, 16))
	workspace.add_child(top)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace.add_child(scroll)
	page_margin = MarginContainer.new()
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right", "top", "bottom"]:
		page_margin.add_theme_constant_override("margin_" + edge, 24)
	scroll.add_child(page_margin)
	body = U.vbox(20)
	page_margin.add_child(body)

func _refresh_header() -> void:
	credit_label.text = "%s CR" % _number(int(Game.data.credits))
	level_label.text = "LOCAL SAVE" if Game.save_enabled else "TEST SESSION"
	level_label.tooltip_text = "Your club saves automatically after each completed action."
	if not Game.last_error.is_empty():
		level_label.text = "UNSAVED"
		level_label.tooltip_text = Game.last_error
	club_xp.text = "COACH LV. %02d  /  %d of 250 XP" % [Game.club_level(), int(Game.data.xp) % 250]
	club_progress.value = int(Game.data.xp) % 250
	nav_buttons[2].text = "Packs" + ("  ·  %d" % Game.total_packs() if Game.total_packs() > 0 else "")

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
	if is_instance_valid(modal):
		_close_modal(false)
	page = clampi(index, 0, PAGES.size() - 1)
	collection_grid = null
	collection_count = null
	_clear(body)
	scroll.scroll_vertical = 0
	breadcrumb.text = "CLUB / " + PAGES[page].to_upper()
	for i in range(nav_buttons.size()):
		var active = i == page
		var style = U.box(Color("30231f") if active else Color(0, 0, 0, 0), 4, Color("76503b") if active else Color(0, 0, 0, 0), 12)
		if active:
			style.border_width_left = 3
		nav_buttons[i].add_theme_stylebox_override("normal", style)
		nav_buttons[i].add_theme_color_override("font_color", U.ORANGE if active else U.MUTED)
	if Game.has_active_match():
		_status_banner("DUST II MATCH IN PROGRESS", "Your lineup is locked. Resume from the start of the current round.", "Resume match   →", _launch_played_match, U.LIME)
	elif not Game.data.pending_pack.is_empty():
		_status_banner("PACK OPENING IN PROGRESS", "%d of %d cards revealed. Your cards are secured; finish this opening to continue." % [Game.data.pending_pack.revealed, Game.data.pending_pack.cards.size()], "Resume opening", func(): _show_pack(Game.data.pending_pack.revealed == 0), U.GOLD)
	match page:
		0: _overview()
		1: _squad()
		2: _packs()
		3: _collection()
		4: _match_room()
		5: _trades()
	if page_tween:
		page_tween.kill()
	body.modulate.a = 1.0
	if not reduced_motion:
		body.modulate.a = 0.0
		page_tween = create_tween()
		page_tween.tween_property(body, "modulate:a", 1.0, 0.14)

func _heading(eyebrow: String, title: String, subtitle: String) -> void:
	var heading = U.vbox(5)
	heading.add_child(U.label(eyebrow, 10, U.ORANGE, true))
	heading.add_child(U.label(title, 30 if narrow_layout else 34, U.TEXT, true))
	heading.add_child(U.paragraph(subtitle, 13))
	body.add_child(heading)

func _overview() -> void:
	var hero = PanelContainer.new()
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", U.box(U.SURFACE, 8, U.BORDER, 0))
	hero.add_child(Arena.new())
	var margin = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	hero.add_child(margin)
	var row = U.hbox(20)
	margin.add_child(row)
	var lead = U.vbox(9)
	lead.add_child(U.label("NORTHLINE / THE OPEN CIRCUIT", 10, U.ORANGE, true))
	lead.add_child(U.label("BUILD YOUR FIVE.\nPLAY YOUR WAY.", 30 if narrow_layout else 37, U.TEXT, true))
	lead.add_child(U.paragraph("Make the calls. Earn your next signing.", 13))
	var actions = U.hbox(8)
	if Game.has_active_match():
		actions.add_child(U.button("Resume match   →", _launch_played_match, true))
	elif not Game.data.pending_pack.is_empty():
		actions.add_child(U.button("Resume opening", func(): _show_pack(Game.data.pending_pack.revealed == 0), true))
	else:
		actions.add_child(U.button("Prepare match   →", func(): navigate(4), true))
		actions.add_child(U.button("Visit packs", func(): navigate(2)))
	actions.add_child(U.spacer())
	lead.add_child(actions)
	row.add_child(lead)
	var fixture = U.vbox(8)
	fixture.custom_minimum_size.x = 240
	fixture.size_flags_horizontal = Control.SIZE_FILL
	fixture.add_child(U.badge("MATCH %02d / DUST II" % (Game.data.matches + 1), U.BLUE))
	fixture.add_child(U.label("NEXT OPPONENT", 10, U.MUTED, true))
	fixture.add_child(U.label(Game.opponent().name, 20, U.TEXT, true))
	fixture.add_child(U.label("%d RATING · %s" % [Game.opponent().rating, C.TACTICS[Game.opponent().tactic]], 10, U.MUTED))
	fixture.add_child(U.paragraph("Play out for full rewards.\nQuick results earn 50% credits and XP.", 12))
	row.add_child(fixture)
	body.add_child(hero)
	var stats = U.hbox(10)
	_stat(stats, "TEAM RATING", str(Game.team_rating()), "5 of 5 roles filled", U.ORANGE)
	_stat(stats, "COLLECTION", "%d / %d" % [Game.unique_cards(), C.cards().size()], "%d total copies" % Game.total_cards(), U.TEXT)
	_stat(stats, "RECORD", "%d W · %d L" % [Game.data.wins, Game.data.matches - Game.data.wins], "%d matches completed" % Game.data.matches, U.TEXT)
	_stat(stats, "PACK LOCKER", str(Game.total_packs()), "Ready to open", U.GOLD)
	body.add_child(stats)
	var roster = U.vbox(12)
	var roster_title = U.section("STARTING FIVE", C.TACTICS[int(Game.data.tactic)])
	roster_title.add_child(U.button("Manage squad", func(): navigate(1)))
	roster.add_child(roster_title)
	var lineup = U.hbox(9)
	for i in range(5):
		var tile = U.vbox(7)
		tile.add_child(U.label(C.ROLES[i], 10, U.MUTED, true))
		tile.add_child(_card_tile(Game.data.squad[i], false, false, true))
		lineup.add_child(tile)
	roster.add_child(lineup)
	body.add_child(U.panel(roster, U.SURFACE, 16))
	var progress = U.hbox(16)
	var note = U.vbox(4)
	note.add_child(U.label("YOUR NEXT CONTENDER PACK", 11, U.GOLD, true))
	note.add_child(U.paragraph("%d of 4 matches complete. Every fourth match adds a pack to your locker." % (int(Game.data.matches) % 4), 12))
	progress.add_child(note)
	progress.add_child(U.button("See pack odds", func(): navigate(2)))
	body.add_child(U.panel(progress, U.SURFACE, 16))

func _stat(row: HBoxContainer, title: String, value: String, caption: String, color: Color) -> void:
	var content = U.vbox(6)
	content.add_child(U.label(title, 9, U.MUTED, true))
	content.add_child(U.label(value, 26, color, true))
	content.add_child(U.label(caption, 10, U.MUTED))
	row.add_child(U.panel(content, U.SURFACE, 17))

func _card_tile(id: String, actions: bool = false, show_count: bool = true, compact: bool = false) -> VBoxContainer:
	var card = C.card(id)
	var tile = U.vbox(8)
	var inspect = Button.new()
	inspect.text = card.handle
	inspect.tooltip_text = "Inspect %s · %s" % [card.handle, card.role]
	inspect.custom_minimum_size = Vector2(120, 225) if compact else Vector2(175, 284)
	inspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		inspect.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		inspect.add_theme_color_override(state, Color.TRANSPARENT)
	inspect.pressed.connect(func(): _show_card(id))
	var art = Card.new()
	art.card = card
	art.compact = compact
	art.selected = id in Game.data.squad
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 3
	art.offset_top = 3
	art.offset_right = -3
	art.offset_bottom = -3
	if Game.copies(id) == 0:
		art.modulate = Color(0.45, 0.45, 0.45, 1)
	inspect.add_child(art)
	tile.add_child(inspect)
	if show_count:
		var info = U.hbox(5)
		info.add_child(U.label("×%d OWNED" % Game.copies(id) if Game.copies(id) > 0 else "NOT COLLECTED", 10, U.MUTED, true))
		info.add_child(U.spacer())
		if id in Game.data.squad:
			info.add_child(U.label("IN FIVE", 9, U.ORANGE, true))
		tile.add_child(info)
	if actions and Game.copies(id) > 0:
		var equip = U.button("In starting five" if id in Game.data.squad else "Add to lineup  ↑", func():
			if Game.equip(id):
				navigate(page)
				notify(card.handle + " joined your starting five.")
			else:
				_action_failed())
		equip.disabled = id in Game.data.squad or _transactions_locked()
		tile.add_child(equip)
	return tile

func _squad() -> void:
	_heading("SQUAD MANAGEMENT", "Five roles. Your identity.", "Select a card to inspect it. A substitution replaces the same role and keeps both cards in your collection.")
	var summary = U.hbox(12)
	_stat(summary, "TEAM RATING", str(Game.team_rating()), "Role and collection bonuses included", U.ORANGE)
	_stat(summary, "ROLE COVERAGE", "5 / 5", "Entry · AWPer · IGL · Support · Lurker", U.LIME)
	_stat(summary, "APPROACH", C.TACTICS[int(Game.data.tactic)], "Set your approach in Matches", U.TEXT)
	body.add_child(summary)
	body.add_child(U.section("STARTING FIVE", "CARDS STAY IN YOUR CLUB AFTER PLAY"))
	var lineup = U.hbox(12)
	for i in range(5):
		var tile = U.vbox(8)
		tile.add_child(U.label("%02d / %s" % [i + 1, C.ROLES[i]], 10, U.ORANGE, true))
		tile.add_child(_card_tile(Game.data.squad[i], false, false, narrow_layout))
		lineup.add_child(tile)
	body.add_child(lineup)
	body.add_child(U.section("AVAILABLE SUBSTITUTES", "SELECT A ROLE-MATCHING PLAYER"))
	var bench = C.cards().filter(func(c): return Game.copies(c.id) > 0 and c.id not in Game.data.squad)
	bench.sort_custom(func(a, b): return a.overall > b.overall)
	if bench.is_empty():
		var empty = U.vbox(10)
		empty.add_child(U.label("Your next signing is waiting.", 22, U.TEXT, true))
		empty.add_child(U.paragraph("Your starting five is ready. Open a pack or make a trade to add a substitute.", 13))
		empty.add_child(U.button("Visit the pack room   →", func(): navigate(2), true))
		body.add_child(U.panel(empty))
	else:
		var grid = GridContainer.new()
		grid.columns = _columns()
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 20)
		for card in bench:
			grid.add_child(_card_tile(card.id, true))
		body.add_child(grid)

func _packs() -> void:
	_heading("ALPHA COLLECTION", "Your next signing starts here.", "Open an owned pack, or use earned credits to add one to your locker. Every pack contains five players.")
	var intro = U.hbox(10)
	intro.add_child(U.badge("%d PACKS IN YOUR LOCKER" % Game.total_packs(), U.LIME))
	intro.add_child(U.badge("EARNED CURRENCY ONLY", U.MUTED))
	intro.add_child(U.spacer())
	intro.add_child(U.label("%d PLAYERS · %d RARITIES · 5 ROLES" % [C.cards().size(), C.RARITIES.size()], 10, U.MUTED, true))
	body.add_child(intro)
	var row = U.hbox(20)
	for id in ["contender", "elite"]:
		var pack_id = id
		var pack = C.PACKS[id]
		var col = U.vbox(12)
		var top = U.hbox()
		top.add_child(U.label("ALPHA COLLECTION / PLAYER PACK", 10, U.MUTED, true))
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
		open.disabled = Game.data.packs[id] <= 0 or _transactions_locked()
		open.tooltip_text = _lock_reason() if _transactions_locked() else "Reveal five players from this owned pack."
		buttons.add_child(open)
		var buy = U.button("Get pack · %d CR" % pack.price, func():
			if Game.purchase_pack(pack_id):
				notify(pack.name + " added to your locker.")
				navigate(2)
			else:
				_action_failed())
		buy.disabled = Game.data.credits < pack.price or _transactions_locked()
		buy.tooltip_text = _lock_reason() if _transactions_locked() else ("Need %d more credits." % (pack.price - Game.data.credits) if Game.data.credits < pack.price else "Adds one sealed pack to your locker.")
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
	_heading("THE CARD BINDER", "Find the right player.", "Inspect your cards, compare roles, and make room for your next signing.")
	var search_row = U.hbox(14)
	var search = LineEdit.new()
	search.name = "CollectionSearch"
	search.placeholder_text = "Search player, name or collection…"
	search.text = search_query
	search.custom_minimum_size.y = 44
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(func(value):
		search_query = value
		_render_collection())
	search_row.add_child(search)
	search_row.add_child(U.badge("%d / %d COLLECTED" % [Game.unique_cards(), C.cards().size()], U.LIME))
	body.add_child(search_row)
	var filters = U.hbox(10)
	var rarity = OptionButton.new()
	rarity.name = "RarityFilter"
	rarity.custom_minimum_size = Vector2(150, 42)
	rarity.add_item("All rarities")
	for value in C.RARITIES:
		rarity.add_item(value.capitalize())
	rarity.selected = rarity_filter + 1
	rarity.item_selected.connect(func(index):
		rarity_filter = index - 1
		_render_collection())
	filters.add_child(rarity)
	var role = OptionButton.new()
	role.name = "RoleFilter"
	role.custom_minimum_size = Vector2(140, 42)
	role.add_item("All roles")
	for value in C.ROLES:
		role.add_item(value)
	role.selected = role_filter + 1
	role.item_selected.connect(func(index):
		role_filter = index - 1
		_render_collection())
	filters.add_child(role)
	var sort = OptionButton.new()
	sort.custom_minimum_size = Vector2(160, 42)
	for value in ["Rating: high to low", "Player: A to Z", "Rarity: high to low"]:
		sort.add_item(value)
	sort.selected = sort_mode
	sort.item_selected.connect(func(index):
		sort_mode = index
		_render_collection())
	filters.add_child(sort)
	var owned = CheckButton.new()
	owned.text = "Owned only"
	owned.button_pressed = owned_only
	owned.toggled.connect(func(value):
		owned_only = value
		_render_collection())
	filters.add_child(owned)
	filters.add_child(U.spacer())
	filters.add_child(U.button("Clear filters", _reset_collection))
	body.add_child(filters)
	collection_count = U.label("", 11, U.MUTED)
	body.add_child(collection_count)
	collection_grid = GridContainer.new()
	collection_grid.columns = _columns()
	collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_grid.add_theme_constant_override("h_separation", 14)
	collection_grid.add_theme_constant_override("v_separation", 20)
	body.add_child(collection_grid)
	_render_collection()

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
		b.disabled = _transactions_locked()
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
	preparation.add_child(U.paragraph("DUST II / THE ALPHA BATTLEGROUND\nPreview rendered from the map used in played matches. More maps will arrive in future builds.", 12))
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
		b.disabled = _transactions_locked()
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
	var match_button = U.button("Resume match   →" if Game.has_active_match() else "Play match   →", _play_match, true)
	match_button.disabled = not Game.data.pending_pack.is_empty()
	match_button.tooltip_text = _lock_reason() if match_button.disabled else "Choose a 3D played match or a quick result."
	launch.add_child(match_button)
	body.add_child(U.panel(launch))
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
	grid.columns = 2 if not narrow_layout else 1
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
		var available = Game.can_release(offer.give) and not _transactions_locked()
		col.add_child(U.paragraph("You own %d × %s%s" % [Game.copies(offer.give), C.card(offer.give).handle, " · 1 reserved in your lineup" if offer.give in Game.data.squad else ""], 11))
		var trade_label = "Accept trade   ⇄" if available else ("Finish current match" if Game.has_active_match() else ("Finish opening first" if not Game.data.pending_pack.is_empty() else "Spare " + C.card(offer.give).handle + " required"))
		var accept = U.button("Trade completed" if offer.used else trade_label, func(): _confirm_trade(key), available and not offer.used)
		accept.disabled = offer.used or not available
		accept.tooltip_text = _lock_reason() if _transactions_locked() else "One copy of an active player remains protected."
		col.add_child(accept)
		grid.add_child(U.panel(col))
	body.add_child(grid)

func _modal_base(width: float = 1040, height: float = 700) -> VBoxContainer:
	var previous_focus = modal_return_focus if is_instance_valid(modal) else get_viewport().gui_get_focus_owner()
	_close_modal(false)
	_dismiss_notification()
	modal_return_focus = previous_focus
	modal_width = width
	modal_height = height
	modal = ColorRect.new()
	modal.color = Color(0.02, 0.03, 0.05, 0.9)
	modal.z_index = 20
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	modal_panel = PanelContainer.new()
	modal_panel.name = "DialogPanel"
	modal_panel.add_theme_stylebox_override("panel", U.box(Color("141e2a"), 10, Color("455b72"), 22))
	modal.add_child(modal_panel)
	_fit_modal()
	var shell = U.vbox(12)
	modal_panel.add_child(shell)
	var titlebar = U.hbox()
	titlebar.add_child(U.label("CSTCG / NORTHLINE CLUB", 10, U.MUTED, true))
	titlebar.add_child(U.spacer())
	var close = U.button("Close  ×", _close_modal)
	close.tooltip_text = "Close this window [Esc]. Unfinished pack openings remain secured."
	close.custom_minimum_size.y = 34
	titlebar.add_child(close)
	shell.add_child(titlebar)
	shell.add_child(U.divider())
	var modal_scroll = ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(modal_scroll)
	var content = U.vbox(16)
	modal_scroll.add_child(content)
	call_deferred("_focus_dialog", weakref(close))
	return content

func _close_modal(restore_focus: bool = true) -> void:
	var was_open = is_instance_valid(modal)
	if reveal_tween:
		reveal_tween.kill()
		reveal_tween = null
	if is_instance_valid(replay_timer):
		replay_timer.stop()
		replay_timer.queue_free()
		replay_timer = null
	if was_open:
		remove_child(modal)
		modal.queue_free()
	modal = null
	modal_panel = null
	if restore_focus and was_open:
		if not Game.data.pending_pack.is_empty():
			navigate(page)
		if is_instance_valid(modal_return_focus) and modal_return_focus.is_inside_tree():
			modal_return_focus.grab_focus()
		else:
			nav_buttons[page].grab_focus()

func _open_pack(id: String) -> void:
	if Game.open_pack(id):
		navigate(page)
		_show_pack(true)
	else:
		_action_failed()

func _show_pack(sealed: bool = false) -> void:
	var pending = Game.data.pending_pack
	if pending.is_empty():
		return
	var pack = C.PACKS[pending.pack_id]
	var content = _modal_base(1180, 780)
	var short_window = size.y < 820
	if short_window:
		content.add_theme_constant_override("separation", 10)
	content.add_child(U.section("PACK ROOM / " + pack.name, "ALPHA COLLECTION"))
	var title = U.label("Reveal your next signing.", 28 if short_window else 32, U.TEXT, true)
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
		art.custom_minimum_size.y = 350 if short_window else 380
		content.add_child(art)
		var tear = U.button("Tear open   →", func(): _tear_pack(art), true)
		tear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tear.custom_minimum_size.x = 240
		content.add_child(tear)
		var tip = U.label("Your cards are already secured. Closing the game will preserve this pack.", 12, U.MUTED)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(tip)
		return
	content.add_child(_gap(4 if short_window else 15))
	var row = U.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(5):
		var tile = U.vbox(10)
		var art = Card.new()
		art.card = C.card(pending.cards[i])
		art.face_down = i >= pending.revealed
		art.fresh = pending.new_flags[i]
		art.custom_minimum_size.y = 284 if short_window else 350
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
	content.add_child(_gap(4 if short_window else 20))
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
	reveal_tween = create_tween().set_parallel(true)
	reveal_tween.tween_property(art, "scale", Vector2(1.08, 1.08), 0.18)
	reveal_tween.tween_property(art, "modulate:a", 0.0, 0.25).set_delay(0.1)
	reveal_tween.chain().tween_callback(func():
		if is_instance_valid(art) and art.is_inside_tree():
			_show_pack())

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
	var content = _modal_base(1040, 700)
	if size.y < 820:
		content.add_theme_constant_override("separation", 12)
	content.add_child(U.section("MATCH %02d / DUST II" % (Game.data.matches + 1), "NORTHLINE VS " + Game.opponent().name))
	content.add_child(U.label("Choose your match experience.", 32, U.TEXT, true))
	content.add_child(U.paragraph("Your lineup and tactic are ready. Both modes count toward your next pack reward.", 15))
	var choices = U.hbox(22)
	var played = U.vbox(16)
	played.add_child(U.badge("FULL REWARDS", U.LIME))
	played.add_child(U.label("Watch your five compete.", 25, U.TEXT, true))
	played.add_child(U.paragraph("A 3D automatic match on Dust II. Follow players, change cameras, pause, and control playback speed. Movement, fights, and the bomb determine the result.", 14))
	played.add_child(U.label("WIN   +160 CR / +100 XP\nLOSS   +85 CR / +60 XP", 14, U.LIME, true))
	played.add_child(U.paragraph("About 3 minutes at 8×. Completed rounds save automatically.", 12))
	played.add_child(U.button("Play out match", _begin_played_match, true))
	choices.add_child(U.panel(played, U.SURFACE, 20 if size.y < 820 else 26))
	var skipped = U.vbox(16)
	skipped.add_child(U.badge("50% CREDITS & XP", U.ORANGE))
	skipped.add_child(U.label("Go straight to the report.", 25, U.TEXT, true))
	skipped.add_child(U.paragraph("The quick round simulation resolves your fixture immediately. Review the score, round feed, and standout player, then get back to building your club.", 14))
	skipped.add_child(U.label("WIN   +80 CR / +50 XP\nLOSS   +43 CR / +30 XP", 14, U.ORANGE, true))
	skipped.add_child(U.paragraph("Instant result. The same pack milestone progress.", 12))
	skipped.add_child(U.button("Skip to result (less rewards)", _skip_match))
	choices.add_child(U.panel(skipped, U.SURFACE, 20 if size.y < 820 else 26))
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
	var content = _modal_base(1120, 780)
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
	var standout = U.vbox(6)
	standout.custom_minimum_size.x = 210
	standout.size_flags_horizontal = Control.SIZE_FILL
	standout.add_child(U.label("YOUR STANDOUT", 10, U.GOLD, true))
	var mvp_card = Card.new()
	mvp_card.card = C.card(result.mvp)
	mvp_card.compact = true
	mvp_card.custom_minimum_size = Vector2(170, 240)
	standout.add_child(mvp_card)
	standout.add_child(U.label("%d ELIMINATIONS" % result.kills[result.mvp], 11, U.MUTED, true))
	replay_row.add_child(standout)
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
	replay_economy = U.paragraph("Team equipment budgets: 800 / 800", 12, U.MUTED)
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
	replay_economy.text = "Match rewards: +%d CR / +%d XP · Standout: %s (%d eliminations)" % [replay_result.reward, replay_result.xp, C.card(replay_result.mvp).handle, replay_result.kills[replay_result.mvp]]
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
	var content = _modal_base(730, 340)
	content.add_child(U.label(title, 29, U.TEXT, true))
	content.add_child(U.paragraph(detail, 15))
	var buttons = U.hbox()
	buttons.add_child(U.button(action, callback, true))
	buttons.add_child(U.button("Cancel", _close_modal))
	buttons.add_child(U.spacer())
	content.add_child(buttons)

func _show_help() -> void:
	var content = _modal_base(1000, 730)
	content.add_child(U.label("Welcome to your club.", 32, U.TEXT, true))
	content.add_child(U.paragraph("Build a five-player squad, choose your approach, and turn match rewards into your next signing.", 15))
	var steps = [
		["01 / OPEN PACKS", "Your locker starts with two Contender packs. Each has five players and a guaranteed Rare-or-better final card. Contents are secured before the reveal."],
		["02 / BUILD YOUR FIVE", "Inspect a card, then add it to the matching role. Your previous player stays in the binder. One copy of each active player is protected from trades and release."],
		["03 / MAKE THE CALL", "Set your approach in Matches. Play out a 3D Dust II match for full rewards or skip to a quick result for 50% credits and XP. Completed rounds save automatically."],
		["04 / KEEP BUILDING", "A played win earns 160 CR / 100 XP; a loss earns 85 CR / 60 XP. Every fourth completed match earns a Contender pack; every twelfth also earns an Elite pack."]]
	for step in steps:
		var block = U.vbox(5)
		block.add_child(U.label(step[0], 11, U.ORANGE, true))
		block.add_child(U.paragraph(step[1], 13))
		content.add_child(U.panel(block, U.BG, 14))
	content.add_child(U.section("THIS PLAYABLE ALPHA"))
	content.add_child(U.paragraph("%d real player identities · %d pack products · %d rarities. Roles and ratings are custom game values. Portraits use neutral identity art where no portrait asset is available. Trades use local AI managers." % [C.cards().size(), C.PACKS.size(), C.RARITIES.size()], 12))
	content.add_child(U.paragraph("Reduce motion controls pack effects and menu fades. You can pause or change speed inside a played match. Escape closes a dialog; Tab stays within the open dialog.", 12))
	var tools = U.hbox(14)
	tools.add_child(U.paragraph("Map tools\nExplore the supplied Dust II geometry, navigation, and sightlines in the developer lab.", 12))
	tools.add_child(U.button("Open 3D map lab   ↗", func(): get_tree().change_scene_to_file("res://scenes/spatial_lab.tscn")))
	content.add_child(U.panel(tools, U.BG, 14))
	content.add_child(U.button("Back to my club   →", _close_modal, true))

func _action_failed() -> void:
	notify(Game.last_error if not Game.last_error.is_empty() else "That action is unavailable. Check your credits, cards, or unopened reveal.")

func _dismiss_notification() -> void:
	if toast_tween:
		toast_tween.kill()
		toast_tween = null
	if is_instance_valid(toast_panel):
		remove_child(toast_panel)
		toast_panel.queue_free()
	toast_panel = null

func notify(message: String) -> void:
	_dismiss_notification()
	var text = U.paragraph(message, 13, U.TEXT)
	toast_panel = U.panel(text, U.RAISED, 15)
	toast_panel.custom_minimum_size = Vector2(minf(460, size.x - 48), 56)
	toast_panel.z_index = 100
	toast_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_panel.offset_left = -24 - minf(460, size.x - 48)
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
	if DisplayServer.get_name() == "headless":
		get_window().size = Vector2i(1440, 960)
		await get_tree().process_frame
		await get_tree().process_frame
	motion_control.button_pressed = true
	for index in range(6):
		nav_buttons[index].pressed.emit()
		await get_tree().process_frame
		_smoke_layout(PAGES[index])
		await get_tree().process_frame
		if body.get_child_count() == 0:
			push_error("Empty page: " + PAGES[index])
			get_tree().quit(1)
			return
		await _capture("%02d_%s" % [index, PAGES[index].to_snake_case()])
	# Filtering preserves typing focus; inspection is read-only and traps focus.
	navigate(3)
	var search = body.find_child("CollectionSearch", true, false)
	search.grab_focus()
	search.text = "no-such-player"
	search.text_changed.emit(search.text)
	_smoke_expect(collection_count.text.begins_with("0 players"), "empty search is explained")
	_smoke_expect(get_viewport().gui_get_focus_owner() == search, "typing focus survives filtering")
	_smoke_press("Clear filters")
	_smoke_expect(collection_grid.get_child_count() == C.cards().size(), "reset explores the full actual catalogue")
	var inspect_button = _find_button(body, C.card(Game.data.squad[0]).handle)
	inspect_button.grab_focus()
	inspect_button.pressed.emit()
	await get_tree().process_frame
	_smoke_dialog_layout("player profile")
	nav_buttons[0].grab_focus()
	var tab = InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	_input(tab)
	_smoke_expect(modal.is_ancestor_of(get_viewport().gui_get_focus_owner()), "modal keyboard focus stays inside")
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	_input(escape)
	_smoke_expect(not is_instance_valid(modal) and get_viewport().gui_get_focus_owner() == inspect_button, "Escape closes and restores card focus")
	navigate(2)
	_smoke_press("Get pack · 200 CR")
	_smoke_expect(Game.data.credits == 600 and Game.data.packs.contender == 3, "pack purchase button updates wallet and locker")
	_smoke_press("Open pack   ↗")
	await get_tree().process_frame
	await get_tree().process_frame
	_smoke_action_visible("Tear open   →")
	await _capture("06_sealed_pack")
	# Closing a moving wrapper cannot reopen the dialog from a delayed callback.
	motion_control.button_pressed = false
	var secured_pack = Game.data.duplicate(true)
	_smoke_press("Tear open   →")
	_input(escape)
	await get_tree().create_timer(0.45).timeout
	_smoke_expect(not is_instance_valid(modal) and Game.data == secured_pack, "closing during tear cancels presentation without rerolling")
	_smoke_press("Resume opening")
	motion_control.button_pressed = true
	_smoke_press("Tear open   →")
	_smoke_expect(Game.data.pending_pack.revealed == 0, "tearing pack does not skip the reveal")
	_smoke_press("Reveal card 1 / 5   →")
	_smoke_expect(Game.data.pending_pack.revealed == 1, "single reveal button")
	secured_pack = Game.data.duplicate(true)
	_input(escape)
	_smoke_expect(_find_button(body, "Get pack · 200 CR").disabled, "purchases are visibly locked during an opening")
	_smoke_press("Resume opening")
	_smoke_expect(Game.data == secured_pack, "resuming the opening preserves cards and reveal position")
	_smoke_press("Reveal all")
	_smoke_expect(Game.data.pending_pack.revealed == 5, "reveal all button")
	await get_tree().process_frame
	await get_tree().process_frame
	_smoke_action_visible("Build your five   →")
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
	# Exercise native resizing, including dialogs, without scaling small text.
	var original_size = get_window().size
	for extent in [Vector2i(1100, 740), Vector2i(1440, 960)]:
		get_window().size = extent
		await get_tree().process_frame
		await get_tree().process_frame
		for index in range(6):
			navigate(index)
			await get_tree().process_frame
			await get_tree().process_frame
			_smoke_layout("%s at %s" % [PAGES[index], extent])
		_show_card(Game.data.squad[0])
		await get_tree().process_frame
		await get_tree().process_frame
		_smoke_dialog_layout("profile at %s" % extent)
		await _capture("%d_profile" % extent.x)
		_close_modal()
		navigate(4)
		_play_match()
		await get_tree().process_frame
		await get_tree().process_frame
		_smoke_dialog_layout("match choice at %s" % extent)
		_smoke_action_visible("Play out match")
		_smoke_action_visible("Skip to result (less rewards)")
		_smoke_action_visible("Cancel")
		await _capture("%d_match_choice" % extent.x)
		_close_modal()
	get_window().size = original_size
	print("CSTCG_UI_SMOKE: 6 pages, two window sizes, filters, inspection, focus, secured pack resume, trade, match, history, help; %d failures" % smoke_failures)
	get_tree().quit(0 if smoke_failures == 0 else 1)

func _smoke_layout(context: String) -> void:
	_smoke_expect(scroll.get_global_rect().end.x <= size.x + 1, context + ": workspace fits window")
	_smoke_expect(body.get_combined_minimum_size().x <= size.x - scroll.global_position.x - 48 + 1, context + ": content has no horizontal overflow")

func _smoke_dialog_layout(context: String) -> void:
	var rect = modal_panel.get_global_rect()
	_smoke_expect(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= size.x + 1 and rect.end.y <= size.y + 1, context + ": dialog fits window")

func _smoke_action_visible(text: String) -> void:
	var button = _find_button(modal, text)
	_smoke_expect(button != null, "dialog action exists: " + text)
	if button == null:
		return
	var ancestor = button.get_parent()
	while ancestor != modal:
		if ancestor is ScrollContainer:
			_smoke_expect(ancestor.get_global_rect().grow(1).encloses(button.get_global_rect()), "dialog action visible without scrolling: " + text)
		ancestor = ancestor.get_parent()

func _smoke_expect(condition: bool, message: String) -> void:
	if not condition:
		smoke_failures += 1
		printerr("UI FAIL: " + message)

func _smoke_press(text: String) -> void:
	var scope = modal if is_instance_valid(modal) else body
	var b = _find_button(scope, text)
	_smoke_expect(b != null and not b.disabled, "available button: " + text)
	if b != null and not b.disabled:
		b.grab_focus()
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

func _columns(card_width: float = 175, gap: float = 14) -> int:
	return clampi(int((size.x - NAV_WIDTH - 48 + gap) / (card_width + gap)), 2, 6)

func _transactions_locked() -> bool:
	return Game.has_active_match() or not Game.data.pending_pack.is_empty()

func _lock_reason() -> String:
	return "Finish the current match before changing your collection." if Game.has_active_match() else "Finish revealing your current pack first."

func _status_banner(title: String, detail: String, action: String, callback: Callable, color: Color) -> void:
	var row = U.hbox(16)
	var copy = U.vbox(3)
	copy.add_child(U.label(title, 10, color, true))
	copy.add_child(U.paragraph(detail, 12))
	row.add_child(copy)
	row.add_child(U.button(action, callback))
	body.add_child(U.panel(row, Color(color, 0.035), 14))

func _render_collection() -> void:
	if not is_instance_valid(collection_grid):
		return
	_clear(collection_grid)
	var cards = C.cards().filter(func(card):
		return (not owned_only or Game.copies(card.id) > 0) and (rarity_filter < 0 or card.rarity == rarity_filter) and (role_filter < 0 or card.role == C.ROLES[role_filter]) and (search_query.strip_edges().is_empty() or (card.handle + " " + card.name + " " + card.club).to_lower().contains(search_query.strip_edges().to_lower())))
	cards.sort_custom(func(a, b):
		if sort_mode == 1:
			return a.handle.to_lower() < b.handle.to_lower()
		if sort_mode == 2 and a.rarity != b.rarity:
			return a.rarity > b.rarity
		return a.overall > b.overall if a.overall != b.overall else a.handle < b.handle)
	collection_count.text = "%d players shown · select a card to inspect its profile" % cards.size()
	if cards.is_empty():
		var empty = U.vbox(10)
		empty.add_child(U.label("No players match this search.", 20, U.TEXT, true))
		empty.add_child(U.paragraph("Try another name, role or rarity, or clear the filters to explore the collection.", 13))
		empty.add_child(U.button("Reset collection filters", _reset_collection))
		collection_grid.add_child(U.panel(empty))
		return
	for card in cards:
		var id = card.id
		var tile = _card_tile(id, true)
		if Game.copies(id) > 0:
			var release = U.button("Release 1 · +%d CR" % C.QUICK_SELL[card.rarity], func(): _confirm_release(id))
			release.disabled = not Game.can_release(id) or _transactions_locked()
			release.tooltip_text = "One copy in your starting five is always protected. Finish any active opening or match first."
			tile.add_child(release)
		collection_grid.add_child(tile)

func _reset_collection() -> void:
	search_query = ""
	role_filter = -1
	rarity_filter = -1
	owned_only = false
	sort_mode = 0
	navigate(3)

func _show_card(id: String) -> void:
	var card = C.card(id)
	var content = _modal_base(920, 650)
	content.add_child(U.section("PLAYER PROFILE", C.RARITIES[card.rarity] + " / ALPHA COLLECTION"))
	var row = U.hbox(26)
	var art = Card.new()
	art.card = card
	art.custom_minimum_size = Vector2(230, 355)
	art.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(art)
	var profile = U.vbox(13)
	profile.add_child(U.label(card.handle, 36, U.TEXT, true))
	profile.add_child(U.label(card.name, 15, U.MUTED))
	profile.add_child(U.badge(card.country + " / " + card.role, C.COLORS[card.rarity]))
	var values = U.hbox(10)
	for i in range(3):
		var block = U.vbox(3)
		block.add_child(U.label(str([card.aim, card.sense, card.utility][i]), 30, U.TEXT, true))
		block.add_child(U.label(["AIM", "GAME SENSE", "UTILITY"][i], 10, U.MUTED, true))
		values.add_child(block)
	profile.add_child(U.panel(values, U.BG, 15))
	profile.add_child(U.paragraph("%d overall · %s collection\n%d copies owned%s" % [card.overall, card.club.capitalize(), Game.copies(id), " · in your starting five" if id in Game.data.squad else ""], 13))
	profile.add_child(U.paragraph("Alpha roles and ratings are authored game values. Collection labels are not current player organizations.", 12))
	if Game.copies(id) > 0 and id not in Game.data.squad:
		var equip = U.button("Add to lineup  ↑", func():
			if Game.equip(id):
				_close_modal()
				navigate(page)
				notify(card.handle + " joined your starting five.")
			else:
				_action_failed(), true)
		equip.disabled = _transactions_locked()
		profile.add_child(equip)
	elif Game.copies(id) == 0:
		profile.add_child(U.badge("NOT YET COLLECTED", U.MUTED))
	row.add_child(profile)
	content.add_child(row)

func _fit_modal() -> void:
	if not is_instance_valid(modal_panel):
		return
	var extent = Vector2(minf(modal_width, size.x - 48), minf(modal_height, size.y - 48))
	modal_panel.position = (size - extent) * 0.5
	modal_panel.size = extent

func _focus_dialog(reference: WeakRef) -> void:
	var target = reference.get_ref()
	if is_instance_valid(target) and target.is_inside_tree() and is_instance_valid(modal) and modal.is_ancestor_of(target):
		target.grab_focus()

func _queue_resize() -> void:
	if resize_queued or not is_instance_valid(body):
		return
	resize_queued = true
	call_deferred("_apply_resize")

func _apply_resize() -> void:
	resize_queued = false
	narrow_layout = size.x < 1280
	if is_instance_valid(modal):
		_fit_modal()
	else:
		var position_before = scroll.scroll_vertical
		navigate(page)
		scroll.set_deferred("scroll_vertical", position_before)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(modal) or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_close_modal()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB:
		var focusables: Array[Control] = []
		_collect_focusables(modal, focusables)
		if not focusables.is_empty():
			var index = focusables.find(get_viewport().gui_get_focus_owner())
			if index < 0 and event.shift_pressed:
				index = 0
			focusables[posmod(index + (-1 if event.shift_pressed else 1), focusables.size())].grab_focus()
		get_viewport().set_input_as_handled()

func _collect_focusables(node: Node, output: Array[Control]) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE and node.is_visible_in_tree():
		if not node is BaseButton or not node.disabled:
			output.append(node)
	for child in node.get_children():
		_collect_focusables(child, output)

func _load_preferences() -> void:
	if not Game.save_enabled:
		return
	var settings = ConfigFile.new()
	if settings.load("user://ui_preferences.cfg") == OK:
		reduced_motion = bool(settings.get_value("accessibility", "reduced_motion", false))

func _set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	for pack in get_tree().get_nodes_in_group("pack_art"):
		pack.animate = not value
		pack.queue_redraw()
	if value and page_tween:
		page_tween.kill()
		body.modulate.a = 1
	if Game.save_enabled:
		var settings = ConfigFile.new()
		settings.set_value("accessibility", "reduced_motion", value)
		if settings.save("user://ui_preferences.cfg") != OK:
			notify("Motion preference applies to this session; it could not be saved.")
