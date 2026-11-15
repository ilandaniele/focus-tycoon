class_name PlacementBar
extends PanelContainer

signal confirmed
signal cancelled

var _icon: ValidityIcon
var _hint: Label
var _confirm: Button


func _ready() -> void:
	theme_type_variation = "CardPanel"
	var row := UIKit.hbox(10)
	add_child(row)
	_icon = ValidityIcon.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	row.add_child(_icon)
	_hint = UIKit.label("", "", true)
	row.add_child(_hint)
	row.add_child(UIKit.button(UIKit.t("ui.cancel"), _on_cancel))
	_confirm = UIKit.primary_button(UIKit.t("build.confirm"), _on_confirm)
	row.add_child(_confirm)
	set_valid(false)


func set_valid(valid: bool) -> void:
	_icon.valid = valid
	_hint.text = UIKit.t("build.valid" if valid else "build.invalid")
	_confirm.disabled = not valid


func _on_cancel() -> void:
	cancelled.emit()


func _on_confirm() -> void:
	confirmed.emit()


class ValidityIcon extends Control:
	var valid: bool = false:
		set(value):
			valid = value
			queue_redraw()

	func _draw() -> void:
		var ink := ThemeFactory.INK
		draw_circle(size / 2.0, size.x / 2.0, ThemeFactory.MINT if valid else ThemeFactory.SAND_DARK)
		if valid:
			draw_polyline(PackedVector2Array([size * Vector2(0.25, 0.52), size * Vector2(0.43, 0.7), size * Vector2(0.76, 0.32)]), ink, 4.0, true)
		else:
			draw_line(size * 0.3, size * 0.7, ink, 4.0, true)
			draw_line(size * Vector2(0.7, 0.3), size * Vector2(0.3, 0.7), ink, 4.0, true)
