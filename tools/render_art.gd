extends SceneTree

const SOURCE_DIR := "res://art/"
const TARGET_DIR := "res://assets/"
const SOURCE_SUBDIRS: Array[String] = ["fx/", "ui/"]


func _initialize() -> void:
	var rendered := 0
	for sub_dir in SOURCE_SUBDIRS:
		for path in _svg_files(SOURCE_DIR + sub_dir):
			var target := TARGET_DIR + path.trim_prefix(SOURCE_DIR).get_basename() + ".png"
			DirAccess.make_dir_recursive_absolute(target.get_base_dir())
			if not _render(FileAccess.get_file_as_string(path), target):
				printerr("FAIL %s" % target)
				quit(1)
				return
			rendered += 1
	print("%d sprites rendered" % rendered)
	quit()


func _render(svg: String, target: String) -> bool:
	var image := Image.new()
	if image.load_svg_from_string(svg, ArtRegistry.ASSET_SCALE) != OK or image.save_png(target) != OK:
		return false
	print("%s (%dx%d)" % [target, image.get_width(), image.get_height()])
	return true


func _svg_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	for sub_dir in DirAccess.get_directories_at(dir_path):
		files.append_array(_svg_files(dir_path.path_join(sub_dir) + "/"))
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".svg"):
			files.append(dir_path + file_name)
	return files
