extends SceneTree

const SOURCE_DIR := "res://art/"
const TARGET_DIR := "res://assets/"
const ANIMAL_DIR := SOURCE_DIR + "animals/"
const AnimalStrips := preload("res://tools/animal_strips.gd")


func _initialize() -> void:
	var rendered := 0
	for path in _svg_files(SOURCE_DIR):
		var target_base := TARGET_DIR + path.trim_prefix(SOURCE_DIR).get_basename()
		var svg := FileAccess.get_file_as_string(path)
		DirAccess.make_dir_recursive_absolute(target_base.get_base_dir())
		var outputs := {target_base + ".png": svg}
		if path.begins_with(ANIMAL_DIR):
			for anim: String in AnimalStrips.FRAME_COUNTS:
				outputs["%s_%s.png" % [target_base, anim]] = AnimalStrips.build(svg, anim)
		for target: String in outputs:
			if not _render(outputs[target], target):
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
