extends TestCase


func test_insets_scale_from_window_pixels_to_viewport_units() -> void:
	var safe := Rect2i(0, 177, 1206, 2622 - 177 - 102)
	var insets := SafeArea.insets(safe, Vector2i(1206, 2622), Vector2(720, 1565.4))
	assert_eq(insets["left"], 0.0)
	assert_eq(insets["right"], 0.0)
	assert_true(absf(insets["top"] - 105.67) < 0.01)
	assert_true(absf(insets["bottom"] - 60.9) < 0.01)


func test_insets_zero_when_safe_area_covers_window() -> void:
	var insets := SafeArea.insets(Rect2i(0, 0, 720, 1280), Vector2i(720, 1280), Vector2(720, 1280))
	assert_eq(insets, {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0})


func test_insets_zero_for_empty_window() -> void:
	var insets := SafeArea.insets(Rect2i(), Vector2i.ZERO, Vector2(720, 1280))
	assert_eq(insets, {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0})
