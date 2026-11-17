extends RefCounted

const FRAME_COUNTS := {"idle": 4, "walk": 6}
const PARTS: Array[String] = ["body", "head", "legs_a", "legs_b"]
const BASE_HEIGHT := 96.0
const STRIDE := 3.5
const LIFT := 3.0
const WALK_BOB := 1.2
const BREATH := 1.2
const HEAD_LAG := 1.4


static func build(svg: String, anim: String) -> String:
	var size := Vector2(_attribute(svg, "width"), _attribute(svg, "height"))
	var count: int = FRAME_COUNTS[anim]
	var inner := svg.substr(svg.find(">") + 1)
	inner = inner.substr(0, inner.rfind("</svg>"))
	var frames := PackedStringArray()
	for index in count:
		var offsets := _pose(anim, TAU * index / count, size.y / BASE_HEIGHT)
		frames.append('<g transform="translate(%s 0)">%s</g>' % [size.x * index, _posed(inner, offsets)])
	var width := size.x * count
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">%s</svg>' % [width, size.y, width, size.y, "".join(frames)]


static func _pose(anim: String, phase: float, amplitude: float) -> Dictionary:
	if anim == "idle":
		var rise := -BREATH * (1.0 - cos(phase)) / 2.0
		return _scaled({"body": Vector2(0, rise), "head": Vector2(0, rise * HEAD_LAG), "legs_a": Vector2.ZERO, "legs_b": Vector2.ZERO}, amplitude)
	var bob := Vector2(0, -WALK_BOB * absf(sin(phase)))
	return _scaled({
		"body": bob,
		"head": bob * HEAD_LAG,
		"legs_a": Vector2(STRIDE * cos(phase), -LIFT * maxf(0.0, sin(phase))),
		"legs_b": Vector2(-STRIDE * cos(phase), -LIFT * maxf(0.0, -sin(phase))),
	}, amplitude)


static func _scaled(offsets: Dictionary, amplitude: float) -> Dictionary:
	for part: String in offsets:
		offsets[part] *= amplitude
	return offsets


static func _posed(inner: String, offsets: Dictionary) -> String:
	for part in PARTS:
		var offset: Vector2 = offsets[part]
		inner = inner.replace('<g class="%s">' % part, '<g class="%s" transform="translate(%.2f %.2f)">' % [part, offset.x, offset.y])
	return inner


static func _attribute(svg: String, name: String) -> float:
	var start := svg.find(name + '="') + name.length() + 2
	return svg.substr(start, svg.find('"', start) - start).to_float()
