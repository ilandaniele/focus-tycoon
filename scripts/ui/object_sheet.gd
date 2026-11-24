class_name ObjectSheet
extends PanelContainer

signal dismissed

var _uid: String = ""
var _world: Variant = null


static func open(parent: Control, world: Variant, uid: String) -> ObjectSheet:
	var sheet := ObjectSheet.new()
	sheet._uid = uid
	sheet._world = world
	parent.add_child(sheet)
	return sheet


func _ready() -> void:
	theme_type_variation = "CardPanel"
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 24)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -170.0
	var entry: Dictionary = GameState.park.objects.get(_uid, {})
	var item_id: String = entry.get("item_id", "")
	var column := UIKit.vbox(10)
	add_child(column)
	column.add_child(UIKit.label(UIKit.t("item." + item_id), "HeaderLabel"))
	if Config.item(item_id)["category"] == "enclosure":
		_add_growth(column)
	var row := UIKit.hbox(10)
	column.add_child(row)
	row.add_child(UIKit.secondary_button(UIKit.t("sheet.move"), _move))
	var remove_label := UIKit.fmt("sheet.remove", [ParkService.refund_for(_uid)])
	row.add_child(UIKit.button(remove_label, _remove))
	column.add_child(UIKit.button(UIKit.t("ui.close"), _dismiss))


func _add_growth(column: VBoxContainer) -> void:
	var residents := GameState.park.animals_in(_uid).size()
	column.add_child(UIKit.label(UIKit.fmt("sheet.enclosure_info", [GameState.park.cells_of(_uid).size(), residents, ParkService.capacity_of(_uid)])))
	column.add_child(UIKit.secondary_button(UIKit.t("sheet.shape"), _shape))


func _move() -> void:
	_world.begin_move(_uid)
	_dismiss()


func _shape() -> void:
	_world.begin_shape(_uid)
	_dismiss()


func _remove() -> void:
	var result: Dictionary = ParkService.remove_object(_uid)
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "enclosure_not_empty"))
	_dismiss()


func _dismiss() -> void:
	dismissed.emit()
	queue_free()
