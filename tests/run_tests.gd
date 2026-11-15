extends SceneTree

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var total := 0
	var failed := 0
	var filter := OS.get_environment("TEST_FILTER")
	for dir_path in TEST_DIRS:
		for file_name in _test_files(dir_path):
			if filter != "" and not file_name.contains(filter):
				continue
			var script: GDScript = load(dir_path.path_join(file_name))
			if script == null:
				printerr("FAIL load %s" % file_name)
				failed += 1
				continue
			for method in script.get_script_method_list():
				var name: String = method["name"]
				if not name.begins_with("test_"):
					continue
				total += 1
				var test: TestCase = script.new()
				test.before_each()
				await test.call(name)
				test.after_each()
				if test.failures.is_empty():
					print("  ok   %s :: %s" % [file_name, name])
				else:
					failed += 1
					for message in test.failures:
						printerr("  FAIL %s :: %s — %s" % [file_name, name, message])
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)


func _test_files(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			result.append(file_name)
	result.sort()
	return result
