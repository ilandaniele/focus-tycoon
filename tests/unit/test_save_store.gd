extends TestCase

const DIR := "user://test_save_store/"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for file_name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))


func _corrupt_files() -> Array:
	return Array(DirAccess.get_files_at(DIR)).filter(func(name: String) -> bool: return name.begins_with("save.corrupt."))


func _overwrite(file_name: String, text: String) -> void:
	var file := FileAccess.open(DIR.path_join(file_name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_save_then_load_main() -> void:
	var store := SaveStore.new(DIR)
	assert_true(store.save({"n": 1}, 100))
	var loaded := store.load_latest()
	assert_true(loaded["ok"])
	assert_eq(loaded["source"], "main")
	assert_eq(loaded["data"]["n"], 1)
	assert_false(FileAccess.file_exists(DIR.path_join(SaveStore.TMP_FILE)))


func test_empty_dir_loads_none() -> void:
	var loaded := SaveStore.new(DIR).load_latest()
	assert_false(loaded["ok"])
	assert_eq(loaded["source"], "none")


func test_second_save_keeps_previous_as_backup() -> void:
	var store := SaveStore.new(DIR)
	store.save({"n": 1}, 100)
	store.save({"n": 2}, 200)
	assert_true(FileAccess.file_exists(DIR.path_join(SaveStore.BACKUP_FILE)))
	assert_eq(store.load_latest()["data"]["n"], 2)


func test_corrupt_main_falls_back_to_backup_and_is_preserved() -> void:
	var store := SaveStore.new(DIR)
	store.save({"n": 1}, 100)
	store.save({"n": 2}, 200)
	_overwrite(SaveStore.MAIN_FILE, "{garbage")
	var loaded := store.load_latest()
	assert_true(loaded["ok"])
	assert_eq(loaded["source"], "backup")
	assert_eq(loaded["data"]["n"], 1)
	var corrupt := _corrupt_files()
	assert_eq(corrupt.size(), 1)
	assert_eq(FileAccess.get_file_as_string(DIR.path_join(corrupt[0])), "{garbage")


func test_both_corrupt_returns_none_and_preserves_files() -> void:
	var store := SaveStore.new(DIR)
	store.save({"n": 1}, 100)
	store.save({"n": 2}, 200)
	_overwrite(SaveStore.MAIN_FILE, "bad main")
	_overwrite(SaveStore.BACKUP_FILE, "bad backup")
	var loaded := store.load_latest()
	assert_false(loaded["ok"])
	assert_eq(loaded["source"], "none")
	var contents := _corrupt_files().map(func(name: String) -> String: return FileAccess.get_file_as_string(DIR.path_join(name)))
	contents.sort()
	assert_eq(contents, ["bad backup", "bad main"])


func test_save_does_not_overwrite_good_backup_with_corrupt_main() -> void:
	var store := SaveStore.new(DIR)
	store.save({"n": 1}, 100)
	store.save({"n": 2}, 200)
	_overwrite(SaveStore.MAIN_FILE, "broken")
	assert_true(store.save({"n": 3}, 300))
	var backup := SaveCodec.decode(FileAccess.get_file_as_string(DIR.path_join(SaveStore.BACKUP_FILE)))
	assert_eq(backup["data"]["n"], 1)
	assert_eq(store.load_latest()["data"]["n"], 3)
	assert_eq(_corrupt_files().size(), 1)
