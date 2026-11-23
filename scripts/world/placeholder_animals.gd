class_name PlaceholderAnimals
extends RefCounted

const INK := Color("3D3A35")
const PINK := Color("F4B6C2")
const ORANGE := Color("F0A04B")


static func draw(species_id: String, color: Color, canvas_size: Vector2i, foot_margin: float) -> Image:
	var canvas := PixelCanvas.new(canvas_size)
	var base := Vector2(canvas_size.x / 2.0, canvas_size.y - foot_margin)
	match species_id:
		"rabbit":
			_rabbit(canvas, base, color)
		"penguin":
			_penguin(canvas, base, color)
		"beaver":
			_beaver(canvas, base, color)
		"elephant":
			_elephant(canvas, base, color)
		_:
			_generic(canvas, base, color)
	return canvas.image


static func _eye(canvas: PixelCanvas, at: Vector2, radius: float = 2.4) -> void:
	canvas.ellipse(at, Vector2.ONE * radius, INK)
	canvas.ellipse(at + Vector2(0.8, -0.8), Vector2.ONE * radius * 0.35, Color.WHITE)


static func _shadow(canvas: PixelCanvas, base: Vector2, radii: Vector2) -> void:
	canvas.ellipse(base + Vector2(0, 2), radii, Color(0.24, 0.23, 0.21, 0.2))


static func _rabbit(canvas: PixelCanvas, base: Vector2, color: Color) -> void:
	_shadow(canvas, base, Vector2(26, 7))
	canvas.ellipse(base + Vector2(-22, -20), Vector2(7, 7), Color.WHITE)
	canvas.ellipse(base + Vector2(-2, -18), Vector2(22, 17), color)
	canvas.ellipse(base + Vector2(3, -12), Vector2(14, 9), color.lightened(0.3))
	canvas.ellipse(base + Vector2(-10, -2), Vector2(8, 4), color.darkened(0.08))
	canvas.ellipse(base + Vector2(14, -2), Vector2(8, 4), color.darkened(0.08))
	canvas.ellipse(base + Vector2(10, -62), Vector2(4.5, 16), color)
	canvas.ellipse(base + Vector2(10, -62), Vector2(2, 11), PINK)
	canvas.ellipse(base + Vector2(22, -60), Vector2(4.5, 16), color.darkened(0.05))
	canvas.ellipse(base + Vector2(22, -60), Vector2(2, 11), PINK)
	canvas.ellipse(base + Vector2(16, -34), Vector2(13, 12), color)
	_eye(canvas, base + Vector2(21, -36))
	canvas.ellipse(base + Vector2(28, -32), Vector2(2.4, 1.8), PINK.darkened(0.2))


static func _penguin(canvas: PixelCanvas, base: Vector2, color: Color) -> void:
	_shadow(canvas, base, Vector2(24, 7))
	canvas.ellipse(base + Vector2(-8, -1), Vector2(7, 3.5), ORANGE)
	canvas.ellipse(base + Vector2(10, -1), Vector2(7, 3.5), ORANGE)
	canvas.ellipse(base + Vector2(0, -28), Vector2(20, 28), color)
	canvas.ellipse(base + Vector2(-17, -28), Vector2(5, 15), color.darkened(0.15))
	canvas.ellipse(base + Vector2(5, -24), Vector2(13, 21), Color.WHITE)
	canvas.ellipse(base + Vector2(4, -56), Vector2(14, 13), color)
	canvas.ellipse(base + Vector2(9, -54), Vector2(8, 8), Color.WHITE)
	canvas.polygon(PackedVector2Array([base + Vector2(15, -56), base + Vector2(27, -52), base + Vector2(15, -48)]), ORANGE)
	_eye(canvas, base + Vector2(10, -58))


static func _beaver(canvas: PixelCanvas, base: Vector2, color: Color) -> void:
	_shadow(canvas, base, Vector2(36, 8))
	canvas.ellipse(base + Vector2(-20, -3), Vector2(7, 5), color.darkened(0.25))
	canvas.ellipse(base + Vector2(6, -3), Vector2(7, 5), color.darkened(0.25))
	canvas.ellipse(base + Vector2(-6, -22), Vector2(30, 19), color)
	canvas.ellipse(base + Vector2(-8, -16), Vector2(22, 11), color.lightened(0.15))
	canvas.ellipse(base + Vector2(24, -28), Vector2(15, 13), color)
	canvas.ellipse(base + Vector2(35, -24), Vector2(9, 8), color.darkened(0.2))
	canvas.ellipse(base + Vector2(41, -27), Vector2(2.4, 2), INK)
	canvas.ellipse(base + Vector2(17, -41), Vector2(4, 5), color.darkened(0.25))
	_eye(canvas, base + Vector2(27, -32))


static func _elephant(canvas: PixelCanvas, base: Vector2, color: Color) -> void:
	_shadow(canvas, base, Vector2(52, 10))
	canvas.ellipse(base + Vector2(-30, -9), Vector2(10, 11), color.darkened(0.2))
	canvas.ellipse(base + Vector2(12, -9), Vector2(10, 11), color.darkened(0.2))
	canvas.ellipse(base + Vector2(-8, -38), Vector2(42, 30), color)
	canvas.line(base + Vector2(-48, -44), base + Vector2(-54, -24), 3.0, color.darkened(0.25))
	canvas.ellipse(base + Vector2(38, -52), Vector2(21, 19), color)
	canvas.ellipse(base + Vector2(28, -52), Vector2(13, 18), color.darkened(0.12))
	canvas.ellipse(base + Vector2(28, -52), Vector2(8, 12), PINK.darkened(0.1))
	var trunk := [[Vector2(52, -44), 7.0], [Vector2(56, -35), 6.5], [Vector2(58, -26), 6.0], [Vector2(58, -17), 5.5], [Vector2(55, -9), 5.0]]
	for segment: Array in trunk:
		var at: Vector2 = segment[0]
		var radius: float = segment[1]
		canvas.ellipse(base + at, Vector2.ONE * radius, color)
	canvas.ellipse(base + Vector2(50, -34), Vector2(2.5, 6), Color.WHITE)
	_eye(canvas, base + Vector2(44, -58))


static func _generic(canvas: PixelCanvas, base: Vector2, color: Color) -> void:
	_shadow(canvas, base, Vector2(24, 7))
	canvas.ellipse(base + Vector2(0, -24), Vector2(24, 22), color)
	canvas.ellipse(base + Vector2(-6, -30), Vector2(10, 9), color.lightened(0.25))
	_eye(canvas, base + Vector2(8, -30))
