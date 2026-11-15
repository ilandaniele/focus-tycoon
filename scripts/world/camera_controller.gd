class_name CameraController
extends Camera2D

signal tapped(world_pos: Vector2)
signal dragged(world_pos: Vector2)

const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.0
const WHEEL_STEP := 1.1
const TAP_MAX_MOVE := 12.0
const TAP_MAX_MS := 300
const PAN_GESTURE_SPEED := 8.0
const FOCUS_SECONDS := 0.45
const MOUSE_POINTER := -1

var bounds := Rect2(-10000, -10000, 20000, 20000)
var drag_filter := Callable()

var _pointers: Dictionary = {}
var _press_position := Vector2.ZERO
var _press_ms := 0
var _tap_possible := false
var _dragging_ghost := false
var _pinch_distance := 0.0
var _pinch_zoom := 1.0
var _tween: Tween


func focus_to(world_pos: Vector2) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", _clamped(world_pos), FOCUS_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_pointer_moved(event.index, event.position, event.relative)
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)
	elif event is InputEventMagnifyGesture:
		_set_zoom(zoom.x * event.factor)
	elif event is InputEventPanGesture:
		position = _clamped(position + event.delta * PAN_GESTURE_SPEED / zoom.x)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_pointer_pressed(event.index, event.position)
	else:
		_pointer_released(event.index, event.position)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_set_zoom(zoom.x * WHEEL_STEP)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_set_zoom(zoom.x / WHEEL_STEP)
	elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			_pointer_pressed(MOUSE_POINTER, event.position)
		else:
			_pointer_released(MOUSE_POINTER, event.position)


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	_on_pointer_moved(MOUSE_POINTER, event.position, event.relative)


func _pointer_pressed(id: int, screen_pos: Vector2) -> void:
	_pointers[id] = screen_pos
	if _pointers.size() == 1:
		_press_position = screen_pos
		_press_ms = Time.get_ticks_msec()
		_tap_possible = true
		_dragging_ghost = drag_filter.is_valid() and drag_filter.call(_to_world(screen_pos))
	else:
		_tap_possible = false
		_dragging_ghost = false
		_pinch_distance = _pointer_distance()
		_pinch_zoom = zoom.x


func _pointer_released(id: int, screen_pos: Vector2) -> void:
	if not _pointers.has(id):
		return
	var was_tap := _tap_possible and _pointers.size() == 1 \
		and Time.get_ticks_msec() - _press_ms < TAP_MAX_MS \
		and screen_pos.distance_to(_press_position) < TAP_MAX_MOVE
	_pointers.erase(id)
	_dragging_ghost = false
	_tap_possible = false
	if was_tap:
		tapped.emit(_to_world(screen_pos))


func _on_pointer_moved(id: int, screen_pos: Vector2, relative: Vector2) -> void:
	if not _pointers.has(id):
		return
	_pointers[id] = screen_pos
	if _pointers.size() >= 2:
		_set_zoom(_pinch_zoom * _pointer_distance() / maxf(_pinch_distance, 1.0))
		position = _clamped(position - relative / _pointers.size() / zoom.x)
		return
	if screen_pos.distance_to(_press_position) >= TAP_MAX_MOVE:
		_tap_possible = false
	if _dragging_ghost:
		dragged.emit(_to_world(screen_pos))
	else:
		position = _clamped(position - relative / zoom.x)


func _pointer_distance() -> float:
	var points: Array = _pointers.values()
	return (points[0] as Vector2).distance_to(points[1])


func _set_zoom(value: float) -> void:
	var clamped := clampf(value, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(clamped, clamped)
	position = _clamped(position)


func _clamped(world_pos: Vector2) -> Vector2:
	return world_pos.clamp(bounds.position, bounds.end)


func _to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos
