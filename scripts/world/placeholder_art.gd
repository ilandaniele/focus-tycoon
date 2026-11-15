class_name PlaceholderArt
extends RefCounted

const GRASS := Color("8CC084")
const GRASS_DARK := Color("6FA56A")
const DIRT := Color("C9A27E")
const WATER := Color("7EC8E3")
const ICE := Color("DDEFF6")
const SAND := Color("E6C88A")
const FOREST := Color("4F8A5B")
const WOOD := Color("A9744F")
const WOOD_DARK := Color("7E5538")
const WOOD_LIGHT := Color("C48E63")
const INK := Color("3D3A35")
const CORAL := Color("F08A6C")
const PINK := Color("F4B6C2")
const STONE := Color("C9C6BD")
const STONE_DARK := Color("A9A69D")
const GOLD := Color("F2D16B")
const SHADOW := Color(0.24, 0.23, 0.21, 0.22)
const TILE_HALF := Vector2(64, 32)


static func terrain(name: String) -> Image:
	match name:
		"grass":
			return _grass()
		"locked":
			return _locked()
		"grid_ok":
			return _grid_cell()
	push_error("unknown terrain placeholder: %s" % name)
	return null


static func path(item_id: String) -> Image:
	var canvas := PixelCanvas.new(IsoGrid.TILE)
	var base := DIRT
	match item_id:
		"path_stone":
			base = STONE
		"path_wood":
			base = WOOD
	canvas.stamp_diamond(TILE_HALF, TILE_HALF, base.darkened(0.12))
	canvas.stamp_diamond(TILE_HALF, TILE_HALF - Vector2(6, 3), base)
	match item_id:
		"path_stone":
			canvas.speckle(TILE_HALF, TILE_HALF, STONE.lightened(0.35), 10, 11)
			canvas.speckle(TILE_HALF, TILE_HALF, STONE_DARK, 10, 12)
		"path_wood":
			_diagonal_lines(canvas, [0.25, 0.5, 0.75], 2.0, WOOD_DARK)
		_:
			canvas.speckle(TILE_HALF, TILE_HALF, DIRT.darkened(0.2), 14, 13)
	return canvas.image


static func mark(valid: bool) -> Image:
	var canvas := PixelCanvas.new(Vector2i(40, 40))
	var center := Vector2(20, 20)
	canvas.ellipse(center, Vector2.ONE * 19.0, Color.WHITE)
	canvas.ellipse(center, Vector2.ONE * 16.0, Color("3F9A5E") if valid else Color("D2493D"))
	if valid:
		canvas.line(Vector2(11, 21), Vector2(17, 27), 4.0, Color.WHITE)
		canvas.line(Vector2(17, 27), Vector2(29, 13), 4.0, Color.WHITE)
	else:
		canvas.line(Vector2(13, 13), Vector2(27, 27), 4.0, Color.WHITE)
		canvas.line(Vector2(27, 13), Vector2(13, 27), 4.0, Color.WHITE)
	return canvas.image


static func shadow() -> Image:
	var canvas := PixelCanvas.new(Vector2i(64, 24))
	for fraction in [1.0, 0.8, 0.6]:
		canvas.ellipse(Vector2(32, 12), Vector2(30, 11) * fraction, Color(0.2, 0.19, 0.17, 0.12))
	return canvas.image


static func object(item_id: String, item: Dictionary, size: Vector2i, canvas_size: Vector2i) -> Image:
	var canvas := PixelCanvas.new(canvas_size)
	var base := Vector2(canvas_size.x / 2.0, canvas_size.y - (size.x + size.y) * 16.0)
	if item.get("category", "") == "enclosure":
		_enclosure(canvas, base, size, item.get("biome", "meadow"))
		return canvas.image
	match item_id:
		"tree_oak":
			_tree_oak(canvas, base)
		"tree_pine":
			_tree_pine(canvas, base)
		"tree_cherry":
			_tree_cherry(canvas, base)
		"bush_flower":
			_bush(canvas, base)
		"bench":
			_bench(canvas, base)
		"lamp":
			_lamp(canvas, base)
		"sign_wood":
			_sign(canvas, base)
		"fountain":
			_fountain(canvas, base)
		"statue":
			_statue(canvas, base)
		"lantern_premium":
			_lantern(canvas, base)
		_:
			_generic(canvas, base)
	return canvas.image


static func _grass() -> Image:
	var canvas := PixelCanvas.new(IsoGrid.TILE)
	canvas.stamp_diamond(TILE_HALF, TILE_HALF, GRASS)
	canvas.speckle(TILE_HALF, TILE_HALF, Color(GRASS_DARK, 0.55), 22, 1)
	canvas.speckle(TILE_HALF, TILE_HALF, Color(GRASS.lightened(0.25), 0.5), 14, 2)
	return canvas.image


static func _locked() -> Image:
	var canvas := PixelCanvas.new(IsoGrid.TILE)
	canvas.stamp_diamond(TILE_HALF, TILE_HALF, Color("587A5B"))
	_diagonal_lines(canvas, [0.2, 0.4, 0.6, 0.8], 1.5, Color("4B6B4E"))
	return canvas.image


static func _grid_cell() -> Image:
	var canvas := PixelCanvas.new(IsoGrid.TILE)
	canvas.stamp_diamond(TILE_HALF, TILE_HALF, Color(1, 1, 1, 0.75))
	canvas.stamp_diamond(TILE_HALF, TILE_HALF - Vector2(4, 2), Color(1, 1, 1, 0.22))
	return canvas.image


static func _diagonal_lines(canvas: PixelCanvas, offsets: Array, width: float, color: Color) -> void:
	for t: float in offsets:
		canvas.line(Vector2(64.0 * t, 32.0 - 32.0 * t), Vector2(64.0 + 64.0 * t, 64.0 - 32.0 * t), width, color)


static func _shadow(canvas: PixelCanvas, base: Vector2, radii: Vector2) -> void:
	canvas.ellipse(base, radii, SHADOW)


static func _trunk(canvas: PixelCanvas, base: Vector2, height: float) -> void:
	canvas.polygon(PackedVector2Array([
		base + Vector2(-7, 0), base + Vector2(7, 0), base + Vector2(4, -height), base + Vector2(-4, -height)]), WOOD)


static func _tree_oak(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(30, 11))
	_trunk(canvas, base, 44.0)
	canvas.ellipse(base + Vector2(0, -62), Vector2(40, 34), FOREST)
	canvas.ellipse(base + Vector2(-10, -72), Vector2(27, 24), GRASS_DARK)
	canvas.ellipse(base + Vector2(14, -80), Vector2(21, 19), GRASS)


static func _tree_pine(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(26, 10))
	_trunk(canvas, base, 30.0)
	var tiers := [[-26.0, -72.0, 34.0, FOREST.darkened(0.12)], [-50.0, -96.0, 28.0, FOREST], [-74.0, -118.0, 22.0, GRASS_DARK]]
	for tier: Array in tiers:
		var half_width: float = tier[2]
		canvas.polygon(PackedVector2Array([
			base + Vector2(0, tier[1]), base + Vector2(-half_width, tier[0]), base + Vector2(half_width, tier[0])]), tier[3])


static func _tree_cherry(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(30, 11))
	_trunk(canvas, base, 44.0)
	canvas.ellipse(base + Vector2(0, -64), Vector2(42, 34), PINK)
	canvas.ellipse(base + Vector2(-12, -74), Vector2(26, 22), PINK.lightened(0.25))
	canvas.ellipse(base + Vector2(16, -60), Vector2(20, 18), PINK.darkened(0.08))
	for petal in [Vector2(-20, -52), Vector2(8, -86), Vector2(24, -70), Vector2(-4, -60)]:
		canvas.ellipse(base + petal, Vector2(3, 2.4), Color.WHITE)


static func _bush(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(30, 10))
	canvas.ellipse(base + Vector2(0, -18), Vector2(34, 22), GRASS_DARK)
	canvas.ellipse(base + Vector2(-16, -26), Vector2(18, 14), FOREST)
	canvas.ellipse(base + Vector2(14, -28), Vector2(18, 14), GRASS)
	var flowers := [[Vector2(-18, -30), CORAL], [Vector2(6, -34), Color.WHITE], [Vector2(20, -24), GOLD], [Vector2(-4, -20), CORAL]]
	for flower: Array in flowers:
		var offset: Vector2 = flower[0]
		canvas.ellipse(base + offset, Vector2(3.5, 3.5), flower[1])


static func _bench(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(40, 11))
	for leg_x in [-30.0, 24.0]:
		canvas.rect(base + Vector2(leg_x, -18), Vector2(6, 18), WOOD_DARK)
	canvas.rect(base + Vector2(-36, -48), Vector2(72, 14), WOOD_DARK)
	canvas.rect(base + Vector2(-36, -30), Vector2(72, 12), WOOD)
	canvas.rect(base + Vector2(-36, -22), Vector2(72, 3), WOOD_LIGHT)


static func _lamp(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(18, 7))
	canvas.rect(base + Vector2(-3, -88), Vector2(6, 88), INK)
	canvas.ellipse(base + Vector2(0, -2), Vector2(9, 4), INK)
	canvas.ellipse(base + Vector2(0, -88), Vector2(28, 28), Color(1.0, 0.93, 0.6, 0.22))
	canvas.ellipse(base + Vector2(0, -88), Vector2(11, 13), Color("FFE9A0"))
	canvas.polygon(PackedVector2Array([base + Vector2(-14, -98), base + Vector2(14, -98), base + Vector2(0, -114)]), INK)


static func _sign(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(18, 7))
	canvas.rect(base + Vector2(-4, -64), Vector2(8, 64), WOOD_DARK)
	canvas.rect(base + Vector2(-32, -78), Vector2(64, 32), WOOD_LIGHT)
	canvas.rect(base + Vector2(-22, -68), Vector2(44, 4), WOOD_DARK)
	canvas.rect(base + Vector2(-22, -58), Vector2(26, 4), WOOD_DARK)


static func _fountain(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(104, 38))
	canvas.ellipse(base + Vector2(0, -14), Vector2(98, 49), STONE_DARK)
	canvas.ellipse(base + Vector2(0, -24), Vector2(98, 49), STONE)
	canvas.ellipse(base + Vector2(0, -26), Vector2(82, 40), WATER)
	canvas.ellipse(base + Vector2(-14, -30), Vector2(44, 18), WATER.lightened(0.25))
	canvas.rect(base + Vector2(-9, -92), Vector2(18, 70), STONE)
	canvas.ellipse(base + Vector2(0, -92), Vector2(30, 11), STONE_DARK)
	canvas.ellipse(base + Vector2(0, -95), Vector2(26, 9), WATER)
	for drop in [Vector2(-22, -80), Vector2(22, -80), Vector2(-34, -58), Vector2(34, -58), Vector2(0, -108)]:
		canvas.ellipse(base + drop, Vector2(3.5, 4.5), Color(1, 1, 1, 0.85))


static func _statue(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(30, 10))
	canvas.rect(base + Vector2(-24, -24), Vector2(48, 24), STONE_DARK)
	canvas.rect(base + Vector2(-28, -34), Vector2(56, 12), STONE)
	canvas.ellipse(base + Vector2(0, -66), Vector2(15, 28), STONE.lightened(0.2))
	canvas.ellipse(base + Vector2(0, -100), Vector2(12, 12), STONE.lightened(0.2))
	canvas.ellipse(base + Vector2(-16, -70), Vector2(5, 17), STONE)


static func _lantern(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(18, 7))
	canvas.rect(base + Vector2(-3, -34), Vector2(6, 34), INK)
	canvas.ellipse(base + Vector2(0, -60), Vector2(34, 34), Color(1.0, 0.8, 0.5, 0.2))
	canvas.ellipse(base + Vector2(0, -58), Vector2(22, 28), CORAL)
	canvas.ellipse(base + Vector2(-6, -64), Vector2(8, 12), CORAL.lightened(0.3))
	canvas.rect(base + Vector2(-22, -60), Vector2(44, 4), GOLD)
	canvas.rect(base + Vector2(-10, -90), Vector2(20, 7), GOLD)
	canvas.rect(base + Vector2(-8, -34), Vector2(16, 5), GOLD)


static func _generic(canvas: PixelCanvas, base: Vector2) -> void:
	_shadow(canvas, base, Vector2(30, 11))
	canvas.ellipse(base + Vector2(0, -30), Vector2(26, 28), CORAL)
	canvas.ellipse(base + Vector2(-8, -38), Vector2(10, 12), CORAL.lightened(0.3))


static func _biome_floor(biome: String) -> Color:
	match biome:
		"ice":
			return ICE
		"forest":
			return FOREST
		"savanna":
			return SAND
	return GRASS.lightened(0.18)


static func _enclosure(canvas: PixelCanvas, base: Vector2, size: Vector2i, biome: String) -> void:
	var floor_color := _biome_floor(biome)
	var half := Vector2(size.x + size.y, (size.x + size.y) / 2.0) * 32.0
	canvas.stamp_diamond(base, half, floor_color.darkened(0.18))
	canvas.stamp_diamond(base, half - Vector2(8, 4), floor_color)
	canvas.speckle(base, half, floor_color.darkened(0.12), 40, 21)
	canvas.speckle(base, half, floor_color.lightened(0.3), 24, 22)
	var inner := half - Vector2(18, 9)
	var corners := [base + Vector2(-inner.x, 0), base + Vector2(0, -inner.y), base + Vector2(inner.x, 0), base + Vector2(0, inner.y)]
	for edge in [0, 1, 3, 2]:
		_fence(canvas, corners[edge], corners[(edge + 1) % 4], size.x if edge % 2 == 0 else size.y)


static func _fence(canvas: PixelCanvas, from: Vector2, to: Vector2, segments: int) -> void:
	canvas.line(from + Vector2(0, -12), to + Vector2(0, -12), 3.0, WOOD_LIGHT)
	canvas.line(from + Vector2(0, -5), to + Vector2(0, -5), 3.0, WOOD)
	for i in segments + 1:
		var post := from.lerp(to, float(i) / segments)
		canvas.line(post, post + Vector2(0, -16), 5.0, WOOD_DARK)
