class_name Toasts
extends VBoxContainer

const LIFETIME_S := 2.6


func _ready() -> void:
	add_to_group("toasts")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -360.0
	offset_bottom = -250.0
	offset_left = 40.0
	offset_right = -40.0


func push(text: String) -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var message := UIKit.label(text, "", true)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(message)
	add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(LIFETIME_S)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)
