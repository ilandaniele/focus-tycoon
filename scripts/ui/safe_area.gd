class_name SafeArea
extends RefCounted

const ZERO := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}


static func insets(safe: Rect2i, window: Vector2i, viewport: Vector2) -> Dictionary:
	if window.x <= 0 or window.y <= 0:
		return ZERO.duplicate()
	var scale := Vector2(viewport.x / window.x, viewport.y / window.y)
	return {
		"left": safe.position.x * scale.x,
		"top": safe.position.y * scale.y,
		"right": (window.x - safe.end.x) * scale.x,
		"bottom": (window.y - safe.end.y) * scale.y,
	}


static func current(viewport: Viewport) -> Dictionary:
	if not OS.has_feature("mobile"):
		return ZERO.duplicate()
	return insets(DisplayServer.get_display_safe_area(), DisplayServer.window_get_size(), viewport.get_visible_rect().size)


static func inset_full_rect(control: Control) -> void:
	var area := current(control.get_viewport())
	control.offset_left = area["left"]
	control.offset_top = area["top"]
	control.offset_right = -area["right"]
	control.offset_bottom = -area["bottom"]
