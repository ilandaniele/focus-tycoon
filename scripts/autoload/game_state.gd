extends Node

signal state_loaded
signal settings_changed(key: String)

const SAVE_DEBOUNCE_S := 0.5
const MAX_SESSIONS := 2000
const DEFAULT_SETTINGS: Dictionary = {
	"locale": "", "vol_master": 1.0, "vol_music": 0.7, "vol_ambient": 0.7, "vol_sfx": 0.8,
	"vibration": true, "reduce_motion": false, "text_scale": 1.0,
	"reminders_enabled": false, "reminder_hour": 9, "ambient_id": "none", "meditation_ambient_id": "none",
	"default_minutes": 25, "default_mode": "study", "break_min": 5, "cycles": 1,
}

var clock: Clock = Clock.new()
var ledger: Ledger
var park: ParkModel
var timer: FocusTimer
var focus_sessions: Array = []
var meditation_sessions: Array = []
var progress: Dictionary = {}
var settings: Dictionary = {}
var player: Dictionary = {}
var debug_offset_s: int = 0
var benchmark_active: bool = false

var _store: SaveStore = SaveStore.new()
var _save_timer: Timer


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE_S
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	load_or_new()


func load_or_new() -> void:
	var loaded := _store.load_latest()
	if loaded["ok"]:
		_apply_data(loaded["data"])
	else:
		_new_game()
	state_loaded.emit()


func reset_for_tests(dir: String, test_clock: Clock) -> void:
	_store = SaveStore.new(dir)
	clock = test_clock
	debug_offset_s = 0
	_new_game()
	state_loaded.emit()


func save_now() -> bool:
	_save_timer.stop()
	if benchmark_active:
		return true
	var saved := _store.save(_to_data(), now())
	if not saved:
		push_error("save failed")
	return saved


func start_benchmark() -> void:
	save_now()
	benchmark_active = true
	park = BenchmarkPark.build(int(Config.economy["park"]["map_size"]), Config.catalog, Config.species)
	state_loaded.emit()


func mark_dirty() -> void:
	if _save_timer.is_stopped():
		_save_timer.start()


func new_uid(prefix: String) -> String:
	player["uid_seq"] = int(player.get("uid_seq", 0)) + 1
	return "%s_%d" % [prefix, player["uid_seq"]]


func now() -> int:
	return clock.now() + debug_offset_s


func today() -> String:
	return DayKey.of(now(), clock.tz_offset_seconds())


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	mark_dirty()
	settings_changed.emit(key)


func add_focus_session(record: Dictionary) -> void:
	_append_capped(focus_sessions, record)


func add_meditation_session(record: Dictionary) -> void:
	_append_capped(meditation_sessions, record)


func has_entitlement(id: String) -> bool:
	return progress["entitlements"].has(id)


func _append_capped(sessions: Array, record: Dictionary) -> void:
	sessions.append(record)
	if sessions.size() > MAX_SESSIONS:
		sessions.pop_front()


func _new_game() -> void:
	var park_config: Dictionary = Config.economy["park"]
	var created_at := now()
	benchmark_active = false
	player = {"id": "p_%d_%d" % [created_at, randi()], "created_at": created_at, "uid_seq": 0}
	ledger = Ledger.new()
	park = ParkModel.new(int(park_config["map_size"]), int(park_config["initial_unlocked"]))
	timer = FocusTimer.new()
	focus_sessions = []
	meditation_sessions = []
	progress = {"tutorial_step": 0, "tutorial_done": false, "achievements": {}, "daily_claimed": {},
		"objects_placed_by_day": {}, "entitlements": []}
	settings = DEFAULT_SETTINGS.duplicate()


func _apply_data(data: Dictionary) -> void:
	_new_game()
	player = data["player"]
	ledger = Ledger.from_dict(data["resources"])
	park = ParkModel.from_dict(data["park"])
	park.grow(int(Config.economy["park"]["map_size"]))
	if data["focus_active"] != null:
		timer = FocusTimer.from_dict(data["focus_active"])
	focus_sessions = data["focus_sessions"]
	meditation_sessions = data["meditation_sessions"]
	progress.merge(data["progress"], true)
	settings.merge(data["settings"], true)


func _to_data() -> Dictionary:
	var active: bool = timer.state != FocusTimer.State.IDLE and timer.state != FocusTimer.State.FINISHED
	return {
		"player": player,
		"resources": ledger.to_dict(),
		"park": park.to_dict(),
		"focus_active": timer.to_dict() if active else null,
		"focus_sessions": focus_sessions,
		"meditation_sessions": meditation_sessions,
		"progress": progress,
		"settings": settings,
	}
