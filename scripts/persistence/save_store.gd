class_name SaveStore
extends RefCounted

const MAIN_FILE := "save.json"
const TMP_FILE := "save.json.tmp"
const BACKUP_FILE := "save.bak"

var _dir: String


func _init(dir: String = "user://") -> void:
	_dir = dir
	DirAccess.make_dir_recursive_absolute(_dir)


func save(data: Dictionary, at: int) -> bool:
	var text := SaveCodec.encode(data, at)
	if not _write(_path(TMP_FILE), text):
		return false
	if not SaveCodec.decode(_read(_path(TMP_FILE)))["ok"]:
		push_error("save verification failed")
		DirAccess.remove_absolute(_path(TMP_FILE))
		return false
	_retire_main()
	return DirAccess.rename_absolute(_path(TMP_FILE), _path(MAIN_FILE)) == OK


func load_latest() -> Dictionary:
	for source in [["main", MAIN_FILE], ["backup", BACKUP_FILE]]:
		var path := _path(source[1])
		if not FileAccess.file_exists(path):
			continue
		var decoded := SaveCodec.decode(_read(path))
		if decoded["ok"]:
			return {"ok": true, "data": decoded["data"], "source": source[0]}
		_quarantine(path)
	return {"ok": false, "data": {}, "source": "none"}


func _path(file_name: String) -> String:
	return _dir.path_join(file_name)


func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s" % path)
		return false
	file.store_string(text)
	file.close()
	return true


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _retire_main() -> void:
	var main_path := _path(MAIN_FILE)
	if not FileAccess.file_exists(main_path):
		return
	if SaveCodec.decode(_read(main_path))["ok"]:
		DirAccess.copy_absolute(main_path, _path(BACKUP_FILE))
	else:
		_quarantine(main_path)


func _quarantine(path: String) -> void:
	var unix := int(Time.get_unix_time_from_system())
	var target := _path("save.corrupt.%d.json" % unix)
	var suffix := 1
	while FileAccess.file_exists(target):
		target = _path("save.corrupt.%d.%d.json" % [unix, suffix])
		suffix += 1
	push_warning("corrupt save moved to %s" % target)
	DirAccess.rename_absolute(path, target)
