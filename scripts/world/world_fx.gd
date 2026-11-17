class_name WorldFx
extends RefCounted

const POP_SECONDS := 0.35
const POP_START_SCALE := Vector2(0.6, 0.6)
const BURST_AMOUNT := 18
const BURST_LIFETIME := 0.8
const BURST_GRAVITY := Vector2(0, 420)
const BURST_COLORS: Array[Color] = [Color("FFF8EC"), Color("7FD1B9"), Color("F6D88A"), Color("F08A6C")]


static func celebrate(parent: Node2D, at: Vector2, target: Node2D = null) -> void:
	AudioService.play_sfx("pop")
	if UIKit.reduce_motion():
		return
	if target != null:
		_pop(target)
	_burst(parent, at)


static func _pop(target: Node2D) -> void:
	target.scale = POP_START_SCALE
	target.create_tween().tween_property(target, "scale", Vector2.ONE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _burst(parent: Node2D, at: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.z_index = 10
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = BURST_AMOUNT
	particles.lifetime = BURST_LIFETIME
	particles.direction = Vector2.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 300.0
	particles.gravity = BURST_GRAVITY
	particles.scale_amount_min = 8.0
	particles.scale_amount_max = 13.0
	particles.color_initial_ramp = _palette_ramp()
	particles.color_ramp = _fade_ramp()
	particles.finished.connect(particles.queue_free)
	parent.add_child(particles)
	particles.emitting = true


static func _palette_ramp() -> Gradient:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	for i in BURST_COLORS.size():
		offsets.append(float(i) / BURST_COLORS.size())
	gradient.offsets = offsets
	gradient.colors = PackedColorArray(BURST_COLORS)
	return gradient


static func _fade_ramp() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	return gradient
