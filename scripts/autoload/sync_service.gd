extends Node

const CONFIG_PATH := "res://data/sync.json"
const LOCAL_CONFIG_PATH := "res://data/sync.local.json"
const SESSION_PATH := "user://sync_session.json"

var _client: SyncApiClient
var _sync: LedgerSync
var _busy: bool = false


func _ready() -> void:
	var config := _load_config()
	if str(config["url"]) == "":
		return
	var transport := HttpTransport.new()
	transport.timeout_s = float(config["timeout_s"])
	add_child(transport)
	_client = SyncApiClient.new(config["url"], transport)
	_client.session = _read_session()
	_sync = LedgerSync.new(_client, int(config["batch_size"]))
	var timer := Timer.new()
	timer.wait_time = float(config["interval_s"])
	timer.timeout.connect(sync_now)
	add_child(timer)
	timer.start()
	sync_now()


func enabled() -> bool:
	return _sync != null


func player_id() -> String:
	return str(_client.session.get("player_id", "")) if enabled() else ""


func delete_server_data() -> bool:
	if not enabled():
		return false
	while _busy:
		await get_tree().process_frame
	_busy = true
	var deleted: bool = await _client.delete_player()
	_write_session(_client.session)
	_busy = false
	return deleted


func sync_now() -> void:
	if not enabled() or _busy:
		return
	_busy = true
	var synced: Dictionary = GameState.progress.get_or_add("synced_keys", {})
	var result: Dictionary = await _sync.push(GameState.ledger.entries(), synced, GameState.now())
	if result["sent"] > 0:
		GameState.progress["synced_keys"] = SyncBatch.prune(synced, GameState.ledger.entries())
		GameState.mark_dirty()
	_write_session(_client.session)
	_busy = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		sync_now()


func _load_config() -> Dictionary:
	var config: Dictionary = ConfigLoader.load_json(CONFIG_PATH)
	if FileAccess.file_exists(LOCAL_CONFIG_PATH):
		config.merge(ConfigLoader.load_json(LOCAL_CONFIG_PATH), true)
	return config


func _read_session() -> Dictionary:
	if not FileAccess.file_exists(SESSION_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
	return parsed if parsed is Dictionary else {}


func _write_session(session: Dictionary) -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(session))
