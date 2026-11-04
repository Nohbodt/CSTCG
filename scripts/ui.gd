class_name ClubUI
extends RefCounted

const BG = Color("0b1017")
const SURFACE = Color("131c27")
const RAISED = Color("1b2735")
const BORDER = Color("2c3b4c")
const TEXT = Color("f1f0e8")
const MUTED = Color("a0adbd")
const ORANGE = Color("f37645")
const LIME = Color("c4df86")
const BLUE = Color("72b7e5")
const GOLD = Color("ddb56e")
const FONT = preload("res://assets/fonts/OpenSans-Regular.ttf")
const BOLD = preload("res://assets/fonts/OpenSans-Semibold.ttf")
const DISPLAY = preload("res://assets/fonts/DejaVuSansCondensed-Bold.ttf")

static func box(color: Color = SURFACE, radius: int = 8, border: Color = BORDER, padding: int = 20) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

static func theme() -> Theme:
	var t = Theme.new()
	t.default_font = FONT
	t.default_font_size = 15
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("738092"))
	t.set_stylebox("normal", "Button", box(RAISED, 5, BORDER, 12))
	t.set_stylebox("hover", "Button", box(Color("24354a"), 5, Color("536b83"), 12))
	t.set_stylebox("pressed", "Button", box(Color("30445b"), 5, ORANGE, 12))
	t.set_stylebox("disabled", "Button", box(Color("111923"), 5, Color("253140"), 12))
	var focus = box(Color(0, 0, 0, 0), 5, ORANGE, 0)
	focus.set_border_width_all(2)
	t.set_stylebox("focus", "Button", focus)
	t.set_font("font", "Button", BOLD)
	t.set_font_size("font_size", "Button", 14)
	for control in ["OptionButton", "LineEdit"]:
		t.set_font("font", control, FONT)
		t.set_font_size("font_size", control, 14)
		t.set_color("font_color", control, TEXT)
		t.set_stylebox("normal", control, box(RAISED, 5, BORDER, 12))
		t.set_stylebox("focus", control, focus)
	t.set_stylebox("hover", "OptionButton", box(Color("24354a"), 5, Color("536b83"), 12))
	t.set_stylebox("pressed", "OptionButton", box(RAISED, 5, ORANGE, 12))
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_color("caret_color", "LineEdit", ORANGE)
	t.set_color("selection_color", "LineEdit", Color("46637d"))
	t.set_stylebox("panel", "PopupMenu", box(RAISED, 5, BORDER, 9))
	t.set_stylebox("hover", "PopupMenu", box(Color("2c3e53"), 3, Color("2c3e53"), 7))
	t.set_font("font", "PopupMenu", FONT)
	t.set_font_size("font_size", "PopupMenu", 14)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_constant("v_separation", "PopupMenu", 12)
	t.set_stylebox("panel", "TooltipPanel", box(RAISED, 4, Color("536b83"), 10))
	t.set_font("font", "TooltipLabel", FONT)
	t.set_font_size("font_size", "TooltipLabel", 13)
	t.set_color("font_color", "TooltipLabel", TEXT)
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, box(Color("0d141e"), 4, Color("0d141e"), 3))
		t.set_stylebox("grabber", bar, box(Color("394c62"), 4, Color("394c62"), 3))
		t.set_stylebox("grabber_highlight", bar, box(Color("5f7890"), 4, Color("5f7890"), 3))
		t.set_stylebox("grabber_pressed", bar, box(ORANGE, 4, ORANGE, 3))
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", TEXT)
	t.set_font_size("font_size", "CheckButton", 13)
	t.set_constant("separation", "VBoxContainer", 16)
	t.set_constant("separation", "HBoxContainer", 16)
	t.set_stylebox("panel", "PanelContainer", box())
	return t

static func label(text: String, size: int = 14, color: Color = TEXT, bold: bool = false) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if bold:
		node.add_theme_font_override("font", BOLD if size < 25 else DISPLAY)
	return node

static func paragraph(text: String, size: int = 14, color: Color = MUTED) -> Label:
	var node = label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func vbox(gap: int = 16) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

static func hbox(gap: int = 16) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return h

static func panel(content: Control, color: Color = SURFACE, padding: int = 20) -> PanelContainer:
	var node = PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(color, 8, BORDER, padding))
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_child(content)
	return node

static func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 44
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	if primary:
		node.add_theme_stylebox_override("normal", box(ORANGE, 5, ORANGE, 14))
		node.add_theme_stylebox_override("hover", box(Color("ff986d"), 5, Color("ff986d"), 14))
		node.add_theme_stylebox_override("pressed", box(Color("d96135"), 5, Color("d96135"), 14))
		node.add_theme_color_override("font_color", BG)
		node.add_theme_color_override("font_hover_color", BG)
		node.add_theme_color_override("font_pressed_color", BG)
	return node

static func spacer() -> Control:
	var c = Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func badge(text: String, color: Color = LIME) -> PanelContainer:
	var l = label(text, 11, color, true)
	var p = panel(l, Color(color, 0.06), 7)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_theme_stylebox_override("panel", box(Color(color, 0.07), 3, Color(color, 0.22), 7))
	return p

static func section(title: String, extra: String = "") -> HBoxContainer:
	var row = hbox()
	row.add_child(label(title, 12, TEXT, true))
	row.add_child(spacer())
	if not extra.is_empty():
		row.add_child(label(extra, 11, MUTED))
	return row

static func divider() -> HSeparator:
	var line = HSeparator.new()
	var style = StyleBoxLine.new()
	style.color = BORDER
	style.thickness = 1
	line.add_theme_stylebox_override("separator", style)
	return line
