class_name ProgressRing
extends Control

var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var color: Color = ThemeFactory.CORAL:
	set(value):
		color = value
		queue_redraw()
var thickness: float = 22.0


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - thickness
	draw_arc(center, radius, 0.0, TAU, 96, ThemeFactory.SAND_DARK, thickness, true)
	if progress > 0.0:
		draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * progress, 96, color, thickness, true)
