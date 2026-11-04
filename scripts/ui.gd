class_name ClubUI
extends RefCounted

const BG = Color("0c0f13")
const SURFACE = Color("151a20")
const RAISED = Color("1c222a")
const BORDER = Color("2c333b")
const TEXT = Color("f2f0e8")
const MUTED = Color("9199a4")
const ORANGE = Color("f0804b")
const LIME = Color("c4df86")
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
	t.default_font_size = 14
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("626c78"))
	t.set_stylebox("normal", "Button", box(RAISED, 5, BORDER, 12))
	t.set_stylebox("hover", "Button", box(Color("2a323d"), 5, MUTED, 12))
	t.set_stylebox("pressed", "Button", box(Color("343f4a"), 5, ORANGE, 12))
	t.set_stylebox("disabled", "Button", box(Color("12161c"), 5, Color("242b33"), 12))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 5, ORANGE, 0))
	t.set_font("font", "Button", BOLD)
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
		node.add_theme_stylebox_override("hover", box(Color("ff9c68"), 5, Color("ff9c68"), 14))
		node.add_theme_stylebox_override("pressed", box(Color("d76c39"), 5, Color("d76c39"), 14))
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
