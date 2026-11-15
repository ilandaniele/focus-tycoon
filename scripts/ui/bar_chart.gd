class_name BarChart
extends Control

const LABEL_ROOM := 40.0

var days: Array = []:
	set(value):
		days = value
		queue_redraw()


func _draw() -> void:
	if days.is_empty():
		return
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var peak := 1.0
	for entry: Dictionary in days:
		peak = maxf(peak, float(entry["minutes"]))
	var slot := size.x / days.size()
	var plot_height := size.y - LABEL_ROOM * 2.0
	for index in days.size():
		var entry: Dictionary = days[index]
		var minutes: float = entry["minutes"]
		var bar_height := plot_height * minutes / peak
		var left := slot * index
		var top := LABEL_ROOM + plot_height - bar_height
		draw_rect(Rect2(left + slot * 0.2, top, slot * 0.6, maxf(bar_height, 4.0)), ThemeFactory.CORAL)
		draw_string(font, Vector2(left, top - 8.0), str(roundi(minutes)), HORIZONTAL_ALIGNMENT_CENTER, slot, font_size, ThemeFactory.INK)
		draw_string(font, Vector2(left, size.y - 8.0), _weekday(entry["day"]), HORIZONTAL_ALIGNMENT_CENTER, slot, font_size, ThemeFactory.INK)


func _weekday(day: String) -> String:
	var parts := Time.get_datetime_dict_from_datetime_string(day + "T00:00:00", true)
	return tr("stats.wd.%d" % int(parts["weekday"]))
