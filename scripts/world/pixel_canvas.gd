class_name PixelCanvas
extends RefCounted

var image: Image


func _init(size: Vector2i) -> void:
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)


func blend(x: int, y: int, color: Color, coverage: float = 1.0) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var alpha := color.a * coverage
	if alpha <= 0.0:
		return
	var below := image.get_pixel(x, y)
	var out_alpha := alpha + below.a * (1.0 - alpha)
	var weight_below := below.a * (1.0 - alpha)
	image.set_pixel(x, y, Color(
		(color.r * alpha + below.r * weight_below) / out_alpha,
		(color.g * alpha + below.g * weight_below) / out_alpha,
		(color.b * alpha + below.b * weight_below) / out_alpha,
		out_alpha))


func ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var edge := minf(radii.x, radii.y)
	for y in range(floori(center.y - radii.y), ceili(center.y + radii.y) + 1):
		for x in range(floori(center.x - radii.x), ceili(center.x + radii.x) + 1):
			var offset := Vector2((x + 0.5 - center.x) / radii.x, (y + 0.5 - center.y) / radii.y)
			blend(x, y, color, clampf((1.0 - offset.length()) * edge + 0.5, 0.0, 1.0))


func polygon(points: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var orientation := 1.0 if _signed_area(points) > 0.0 else -1.0
	for y in range(floori(bounds.position.y), ceili(bounds.end.y) + 1):
		for x in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
			var depth := INF
			for i in points.size():
				var from := points[i]
				var edge := points[(i + 1) % points.size()] - from
				depth = minf(depth, orientation * edge.cross(Vector2(x + 0.5, y + 0.5) - from) / edge.length())
			blend(x, y, color, clampf(depth + 0.5, 0.0, 1.0))


func rect(top_left: Vector2, size: Vector2, color: Color) -> void:
	polygon(PackedVector2Array([
		top_left, top_left + Vector2(size.x, 0.0), top_left + size, top_left + Vector2(0.0, size.y)]), color)


func line(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var steps := maxi(1, ceili(from.distance_to(to) / (width * 0.5)))
	for i in steps + 1:
		ellipse(from.lerp(to, float(i) / steps), Vector2.ONE * width * 0.5, color)


func stamp_diamond(center: Vector2, half: Vector2, color: Color) -> void:
	for y in range(ceili(center.y - half.y - 0.5), floori(center.y + half.y - 0.5) + 1):
		var reach := half.x * (1.0 - absf(y + 0.5 - center.y) / half.y)
		var left := ceili(center.x - reach - 0.5)
		var right := floori(center.x + reach - 0.5)
		if right >= left:
			image.fill_rect(Rect2i(left, y, right - left + 1, 1), color)


func speckle(center: Vector2, half: Vector2, color: Color, count: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var spot := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		if absf(spot.x) + absf(spot.y) <= 0.85:
			ellipse(center + spot * half, Vector2(rng.randf_range(1.5, 3.5), rng.randf_range(0.8, 1.8)), color)


func _signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		area += points[i].cross(points[(i + 1) % points.size()])
	return area
