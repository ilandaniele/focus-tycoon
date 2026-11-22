class_name PerfOverlay
extends CanvasLayer

const REFRESH_S := 1.0
const LOG_EVERY_REFRESHES := 5
const MB := 1048576.0

var _label: Label
var _elapsed: float = 0.0
var _worst_frame_s: float = 0.0
var _refreshes: int = 0


func _ready() -> void:
	layer = 128
	_label = UIKit.label("", "", true)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 8)
	_label.offset_top = 48


func _process(delta: float) -> void:
	_worst_frame_s = maxf(_worst_frame_s, delta)
	_elapsed += delta
	if _elapsed < REFRESH_S:
		return
	var line := _snapshot()
	_label.text = line
	_refreshes += 1
	if _refreshes % LOG_EVERY_REFRESHES == 0:
		print("BENCH ", line)
	_elapsed = 0.0
	_worst_frame_s = 0.0


func _snapshot() -> String:
	return "fps=%d worst_ms=%.1f static_mb=%.1f vram_mb=%.1f draw_calls=%d nodes=%d objects=%d animals=%d" % [
		Performance.get_monitor(Performance.TIME_FPS),
		_worst_frame_s * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		GameState.park.objects.size(),
		GameState.park.animals.size(),
	]
