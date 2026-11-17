class_name ModalDialog
extends Control

signal closed

var body: VBoxContainer


static func open(from: Node, title: String) -> ModalDialog:
	var dialog := ModalDialog.new()
	dialog.top_level = true
	from.add_child(dialog)
	dialog._build(title)
	UIKit.fade_in(dialog)
	return dialog


func add_button(text: String, primary: bool, on_press: Callable = Callable()) -> Button:
	var handler := _on_button.bind(on_press)
	var button := UIKit.primary_button(text, handler) if primary else UIKit.button(text, handler)
	body.add_child(button)
	return button


func close() -> void:
	closed.emit()
	queue_free()


func _on_button(on_press: Callable) -> void:
	close()
	if on_press.is_valid():
		on_press.call()


func _build(title: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.15, 0.13, 0.1, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	body = UIKit.vbox(14)
	panel.add_child(body)
	var heading := UIKit.label(title, "TitleLabel", true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
