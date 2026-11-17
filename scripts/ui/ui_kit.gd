class_name UIKit
extends RefCounted

const ICON_SIZE := 40.0


static func t(key: String) -> String:
	return TranslationServer.translate(key)


static func fmt(key: String, args: Array) -> String:
	return TranslationServer.translate(key) % args


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func vbox(separation: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func hbox(separation: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func spacer() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func label(text: String, variation: String = "", wrap: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.theme_type_variation = variation
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func section_title(text: String) -> Label:
	return label(text, "HeaderLabel")


static func button(text: String, on_press: Callable, variation: String = "") -> Button:
	var node := Button.new()
	node.text = text
	node.theme_type_variation = variation
	node.custom_minimum_size = Vector2(ThemeFactory.MIN_TOUCH, ThemeFactory.MIN_TOUCH)
	node.pressed.connect(on_press)
	return node


static func primary_button(text: String, on_press: Callable) -> Button:
	return button(text, on_press, "PrimaryButton")


static func secondary_button(text: String, on_press: Callable) -> Button:
	return button(text, on_press, "SecondaryButton")


static func card(parent: Node, variation: String = "CardPanel") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = variation
	parent.add_child(panel)
	var body := vbox(10)
	panel.add_child(body)
	return body


static func chips(options: Array, initial: Variant, on_select: Callable) -> ChipGroup:
	var group := ChipGroup.new().setup(options, initial)
	group.selected.connect(on_select)
	return group


static func screen_header(title: String, on_back: Callable) -> HBoxContainer:
	var row := hbox(12)
	row.add_child(button(t("ui.back"), on_back))
	var title_label := label(title, "TitleLabel")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	return row


static func scroll_body(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return scroll


static func icon(name: String) -> Texture2D:
	return ArtRegistry.get_texture("ui/icon_" + name)


static func icon_rect(name: String, side: float = ICON_SIZE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(name)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(side, side)
	return rect


static func resource_pill(kind: String, value: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.theme_type_variation = "PillPanel"
	var row := hbox(8)
	row.add_child(icon_rect(kind, 32.0))
	var amount := label(str(value))
	amount.name = "Value"
	row.add_child(amount)
	pill.add_child(row)
	return pill


static func set_pill_value(pill: PanelContainer, value: int) -> void:
	(pill.find_child("Value", true, false) as Label).text = str(value)


static func labeled_slider(text: String, value: float, on_change: Callable) -> VBoxContainer:
	var column := vbox(4)
	column.add_child(label(text))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(0, ThemeFactory.MIN_TOUCH)
	slider.value_changed.connect(on_change)
	column.add_child(slider)
	return column


static func switch_row(text: String, value: bool, on_change: Callable) -> HBoxContainer:
	var row := hbox(12)
	row.add_child(label(text, "", true))
	var options := [{"id": true, "text": t("ui.on")}, {"id": false, "text": t("ui.off")}]
	row.add_child(chips(options, value, on_change))
	return row


static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for kind: String in ["coins", "nature"]:
		var amount: int = cost.get(kind, 0)
		if amount > 0:
			parts.append("%d %s" % [amount, t("ui.res." + kind)])
	return " + ".join(parts) if not parts.is_empty() else t("ui.free")


static func mmss(seconds: int) -> String:
	var total := maxi(seconds, 0)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]


static func toast(from: Node, text: String) -> void:
	from.get_tree().call_group("toasts", "push", text)


static func toast_error(from: Node, code: String) -> void:
	toast(from, t("error." + code))


static func reduce_motion() -> bool:
	return GameState.settings.get("reduce_motion", false)
