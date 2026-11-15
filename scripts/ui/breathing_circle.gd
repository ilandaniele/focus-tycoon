class_name BreathingCircle
extends Control

const MIN_SCALE := 0.45
const MIN_ALPHA := 0.35

var amount: float = 0.0:
	set(value):
		amount = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var max_radius := minf(size.x, size.y) / 2.0
	var center := size / 2.0
	var color := ThemeFactory.MINT
	draw_circle(center, max_radius, Color(ThemeFactory.SAND_DARK, 0.6))
	if UIKit.reduce_motion():
		draw_circle(center, max_radius * 0.8, Color(color, lerpf(MIN_ALPHA, 1.0, amount)))
	else:
		draw_circle(center, max_radius * lerpf(MIN_SCALE, 1.0, amount), color)
