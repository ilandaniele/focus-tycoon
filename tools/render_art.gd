extends SceneTree

const SOURCE_DIR := "res://art/"
const TARGET_DIR := "res://assets/"


func _initialize() -> void:
	var rendered := 0
	for path in _svg_files(SOURCE_DIR):
		var target := TARGET_DIR + path.trim_prefix(SOURCE_DIR).get_basename() + ".png"
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var image := Image.new()
		if image.load_svg_from_string(FileAccess.get_file_as_string(path), ArtRegistry.ASSET_SCALE) != OK or image.save_png(target) != OK:
			printerr("FAIL %s" % path)
			quit(1)
			return
		print("%s -> %s (%dx%d)" % [path, target, image.get_width(), image.get_height()])
		rendered += 1
	print("%d sprites rendered" % rendered)
	quit()


func _svg_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	for sub_dir in DirAccess.get_directories_at(dir_path):
		files.append_array(_svg_files(dir_path.path_join(sub_dir) + "/"))
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".svg"):
			files.append(dir_path + file_name)
	return files
