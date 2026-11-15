class_name ThemeFactory
extends RefCounted

const CREAM := Color("FFF8EC")
const SAND := Color("EFE2C8")
const SAND_DARK := Color("E2D2B3")
const INK := Color("3D3A35")
const CORAL := Color("F08A6C")
const MINT := Color("7FD1B9")
const COIN := Color("E8B64C")
const LEAF := Color("5FAF7A")
const BASE_FONT := 26
const MIN_TOUCH := 56
const RADIUS := 20


static func text_scale() -> float:
	return clampf(float(GameState.settings.get("text_scale", 1.0)), 1.0, 1.5)


static func build() -> Theme:
	var scale := text_scale()
	var theme := Theme.new()
	theme.default_font_size = roundi(BASE_FONT * scale)
	_style_labels(theme, scale)
	_style_buttons(theme, scale)
	_style_panels(theme)
	_style_progress(theme)
	_style_slider(theme)
	return theme


static func _box(color: Color, radius: int, pad_h: int, pad_v: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = pad_h
	box.content_margin_right = pad_h
	box.content_margin_top = pad_v
	box.content_margin_bottom = pad_v
	return box


static func _style_labels(theme: Theme, scale: float) -> void:
	theme.set_color("font_color", "Label", INK)
	var variations := {"TitleLabel": 1.4, "HeaderLabel": 1.15, "MutedLabel": 0.85, "BigLabel": 2.6}
	for type_name: String in variations:
		theme.set_type_variation(type_name, "Label")
		theme.set_font_size("font_size", type_name, roundi(BASE_FONT * float(variations[type_name]) * scale))
	theme.set_color("font_color", "MutedLabel", Color(INK, 0.7))


static func _style_buttons(theme: Theme, scale: float) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(INK, 0.5))
	_button_variant(theme, "Button", SAND_DARK, SAND_DARK, RADIUS)
	_button_variant(theme, "NavButton", CREAM, CREAM, RADIUS)
	_button_variant(theme, "PrimaryButton", CORAL, CORAL, RADIUS)
	_button_variant(theme, "SecondaryButton", MINT, MINT, RADIUS)
	_button_variant(theme, "ChipButton", SAND_DARK, MINT, RADIUS)
	_button_variant(theme, "FocusButton", CORAL, CORAL, 90)
	_compact_nav_button(theme, scale)


static func _compact_nav_button(theme: Theme, scale: float) -> void:
	theme.set_font_size("font_size", "NavButton", roundi(BASE_FONT * 0.8 * scale))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box: StyleBoxFlat = theme.get_stylebox(state, "NavButton")
		box.content_margin_left = 4
		box.content_margin_right = 4


static func _button_variant(theme: Theme, type_name: String, color: Color, pressed_color: Color, radius: int) -> void:
	if type_name != "Button":
		theme.set_type_variation(type_name, "Button")
	theme.set_stylebox("normal", type_name, _button_box(color, radius, 0.0))
	theme.set_stylebox("hover", type_name, _button_box(color, radius, 0.05))
	theme.set_stylebox("pressed", type_name, _button_box(pressed_color, radius, 0.0 if pressed_color != color else -0.08))
	theme.set_stylebox("hover_pressed", type_name, _button_box(pressed_color, radius, 0.0 if pressed_color != color else -0.08))
	theme.set_stylebox("disabled", type_name, _button_box(color.lerp(SAND, 0.65), radius, 0.0))
	theme.set_stylebox("focus", type_name, StyleBoxEmpty.new())


static func _button_box(color: Color, radius: int, shade: float) -> StyleBoxFlat:
	var shaded := color.lightened(shade) if shade >= 0.0 else color.darkened(-shade)
	var box := _box(shaded, radius, 20, 12)
	box.shadow_color = Color(0, 0, 0, 0.1)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box


static func _style_panels(theme: Theme) -> void:
	var card := _box(CREAM, RADIUS, 18, 16)
	card.shadow_color = Color(0, 0, 0, 0.12)
	card.shadow_size = 8
	card.shadow_offset = Vector2(0, 3)
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", card)
	theme.set_type_variation("PillPanel", "PanelContainer")
	theme.set_stylebox("panel", "PillPanel", _box(CREAM, RADIUS, 14, 8))
	theme.set_type_variation("MintCard", "PanelContainer")
	theme.set_stylebox("panel", "MintCard", _box(MINT.lightened(0.5), RADIUS, 18, 16))


static func _style_progress(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", _box(SAND_DARK, 8, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(CORAL, 8, 0, 0))


static func _style_slider(theme: Theme) -> void:
	theme.set_stylebox("slider", "HSlider", _box(SAND_DARK, 6, 0, 5))
	theme.set_stylebox("grabber_area", "HSlider", _box(CORAL, 6, 0, 5))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(CORAL, 6, 0, 5))
	var grabber := _circle_texture(44, CORAL)
	for name in ["grabber", "grabber_highlight", "grabber_disabled"]:
		theme.set_icon(name, "HSlider", grabber)


static func _circle_texture(size: int, color: Color) -> ImageTexture:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var radius := size / 2.0 - 2.0
	for y in size:
		for x in size:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			image.set_pixel(x, y, Color(color, clampf(radius - distance + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
