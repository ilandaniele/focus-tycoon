class_name ChipGroup
extends HFlowContainer

signal selected(id: Variant)

var selected_id: Variant = null
var _buttons: Dictionary = {}
var _group := ButtonGroup.new()


func setup(options: Array, initial: Variant, variation: String = "ChipButton", fill: bool = false) -> ChipGroup:
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option: Dictionary in options:
		var button := Button.new()
		button.text = option["text"]
		button.theme_type_variation = variation
		if fill:
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = _group
		button.custom_minimum_size = Vector2(ThemeFactory.MIN_TOUCH, ThemeFactory.MIN_TOUCH)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.pressed.connect(_on_pressed.bind(option["id"]))
		_buttons[option["id"]] = button
		add_child(button)
	select(initial)
	return self


func select(id: Variant) -> void:
	selected_id = id
	for key: Variant in _buttons:
		(_buttons[key] as Button).set_pressed_no_signal(key == id)


func _on_pressed(id: Variant) -> void:
	selected_id = id
	selected.emit(id)
