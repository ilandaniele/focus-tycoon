class_name IslandEdge
extends Node2D

const CLIFF_DEPTH := 40.0
const SHALLOWS_MARGIN := 72.0
const LIP_WIDTH := 5.0
const SHALLOWS := Color("A9DCE3")
const LEFT_FACE := Color("B98A5E")
const RIGHT_FACE := Color("9C7350")
const LIP := Color("6E9E55")

var _bounds := Rect2()


func setup(layer: TileMapLayer, map_size: int) -> void:
	_bounds = IsoGrid.map_rect(layer, map_size)
	queue_redraw()


func _draw() -> void:
	var center := _bounds.get_center()
	var top := Vector2(center.x, _bounds.position.y)
	var bottom := Vector2(center.x, _bounds.end.y)
	var left := Vector2(_bounds.position.x, center.y)
	var right := Vector2(_bounds.end.x, center.y)
	var down := Vector2(0, CLIFF_DEPTH)
	var margin := Vector2(SHALLOWS_MARGIN, SHALLOWS_MARGIN / 2.0)
	draw_colored_polygon(PackedVector2Array([
		top - Vector2(0, margin.y),
		right + Vector2(margin.x, 0),
		bottom + down + Vector2(0, margin.y),
		left - Vector2(margin.x, 0),
	]), SHALLOWS)
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + down, left + down]), LEFT_FACE)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + down, bottom + down]), RIGHT_FACE)
	draw_polyline(PackedVector2Array([left, bottom, right]), LIP, LIP_WIDTH)
