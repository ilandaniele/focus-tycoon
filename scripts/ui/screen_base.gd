class_name ScreenBase
extends Control

signal close_requested

var _bg: ColorRect
var _root: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	_bg.color = ThemeFactory.SAND
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var area := SafeArea.current(get_viewport())
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24 + int(area[side]))
	margin.add_theme_constant_override("margin_top", 48 + int(area["top"]))
	add_child(margin)
	_root = UIKit.vbox(16)
	margin.add_child(_root)
	I18n.locale_changed.connect(_rebuild)
	_rebuild()


func set_tint(color: Color) -> void:
	_bg.color = color


func _build(_container: VBoxContainer) -> void:
	pass


func _rebuild() -> void:
	var scroll_position := _scroll.scroll_vertical if is_instance_valid(_scroll) else 0
	UIKit.clear(_root)
	_scroll = null
	_build(_root)
	if scroll_position > 0 and _scroll != null:
		_restore_scroll.call_deferred(scroll_position)


func _restore_scroll(value: int) -> void:
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = value


func _add_header(title: String) -> void:
	_root.add_child(UIKit.screen_header(title, _request_close))


func _add_scroll_body() -> VBoxContainer:
	_scroll = UIKit.scroll_body(_root)
	var column := UIKit.vbox(16)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(column)
	return column


func _request_close() -> void:
	close_requested.emit()
