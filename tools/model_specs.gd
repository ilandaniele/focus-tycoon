extends RefCounted

const PALETTE := {
	"grass": "5E9E4C",
	"leafsGreen": "6DB35A",
	"leafsDark": "4E9A4F",
	"leafsFall": "F2A65A",
	"stone": "CFC8BC",
	"stoneDark": "A39E94",
	"water": "7EC8E3",
	"dirt": "DDB07F",
	"dirtDark": "BF9065",
	"wood": "D9A06F",
	"woodDark": "B98258",
	"woodBark": "A87452",
	"woodBarkDark": "8E5F42",
	"colorPurple": "B48EE0",
	"colorRed": "E86A6F",
	"colorYellow": "F5C542",
}

const ANIMAL_FACING := 90.0
const ANIMAL_SCALE := 0.42
const ANIMAL_FRAMES := {"idle": 8, "walk": 8}

const ANIMALS := {
	"rabbit": {"model": "bunny"},
	"penguin": {"model": "penguin"},
	"beaver": {"model": "beaver"},
	"panda": {"model": "panda"},
	"elephant": {"model": "elephant", "scale": 0.4},
	"polar_bear": {"model": "polar"},
	"fox": {"model": "fox"},
	"giraffe": {"model": "giraffe", "scale": 0.38},
}

const GROUND := [1.1, 0.04, 1.1]
const BLOSSOM := {"leafsGreen": "F4A7C0", "leafsDark": "E58DAA"}
const SNOW := {"stone": "F2F7FA", "stoneDark": "D3E3EA"}
const DRY_GRASS := {"grass": "C9B46A"}
const OPEN_GRASS := "8DC26F"
const WILD_GRASS := "6F9A63"

const TILES := {
	"terrain/grass": [{"shape": "box", "size": GROUND, "y": -0.02, "color": OPEN_GRASS}],
	"terrain/grass_shade": [{"shape": "box", "size": GROUND, "y": -0.02, "color": "8BC06D"}],
	"terrain/grass_tufts": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": OPEN_GRASS},
		{"m": "nature/grass_leafs", "at": [-0.2, 0.15], "s": 0.55, "tint": {"grass": "77B05C"}},
		{"m": "nature/grass_leafs", "at": [0.25, -0.2], "r": 70.0, "s": 0.45, "tint": {"grass": "77B05C"}},
	],
	"terrain/grass_flowers": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": OPEN_GRASS},
		{"m": "nature/flower_yellowA", "at": [-0.18, 0.1], "s": 0.4},
		{"m": "nature/flower_purpleA", "at": [0.2, -0.12], "s": 0.35},
		{"m": "nature/flower_redA", "at": [0.05, 0.3], "s": 0.3},
	],
	"terrain/locked": [{"shape": "box", "size": GROUND, "y": -0.02, "color": WILD_GRASS}],
	"terrain/locked_tufts": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": WILD_GRASS},
		{"m": "nature/grass_large", "at": [-0.15, 0.1], "s": 0.6, "tint": {"grass": "5E8A55"}},
		{"m": "nature/grass_leafs", "at": [0.25, -0.15], "s": 0.5, "tint": {"grass": "5E8A55"}},
	],
	"paths/path_dirt": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": "DDB07F"},
		{"m": "nature/rock_smallFlatA", "at": [-0.2, 0.15], "y": 0.01, "s": 0.6, "tint": {"grass": "C9A57A"}},
		{"m": "nature/rock_smallFlatB", "at": [0.22, -0.18], "y": 0.01, "s": 0.5, "tint": {"grass": "C9A57A"}},
	],
	"paths/path_stone": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": "9C978C"},
		{"m": "nature/path_stone", "at": [0.0, 0.1], "y": 0.01, "s": [1.0, 1.0, 1.6]},
	],
	"paths/path_wood": [
		{"shape": "box", "size": GROUND, "y": -0.02, "color": "BF9065"},
		{"m": "nature/path_wood", "y": 0.01, "s": [1.0, 1.0, 1.95]},
	],
}

const OBJECTS := {
	"objects/tree_oak": {"size": [1, 1], "parts": [{"m": "nature/tree_oak", "s": 1.05}]},
	"objects/tree_pine": {"size": [1, 1], "parts": [{"m": "nature/tree_pineTallA_detailed", "s": 0.95}]},
	"objects/tree_cherry": {"size": [1, 1], "parts": [{"m": "nature/tree_detailed", "tint": BLOSSOM}]},
	"objects/palm_tree": {"size": [1, 1], "parts": [{"m": "nature/tree_palmDetailedTall", "s": 0.95}]},
	"objects/bush_flower": {"size": [1, 1], "parts": [
		{"m": "nature/plant_bushLarge", "s": 2.0},
		{"m": "nature/flower_redA", "at": [0.25, 0.25], "s": 2.0},
		{"m": "nature/flower_yellowA", "at": [-0.25, 0.3], "s": 2.0},
	]},
	"objects/hedge": {"size": [1, 1], "parts": [{"m": "nature/plant_bushLarge", "s": [2.6, 2.4, 2.6]}]},
	"objects/fern": {"size": [1, 1], "parts": [
		{"m": "nature/grass_leafsLarge", "s": 2.0},
		{"m": "nature/grass_leafsLarge", "at": [0.2, 0.2], "r": 60.0, "s": 1.4},
		{"m": "nature/plant_flatTall", "at": [-0.2, 0.15], "s": 1.6},
	]},
	"objects/flower_tulips": {"size": [1, 1], "parts": [
		{"m": "nature/flower_redB", "at": [-0.2, -0.2], "s": 2.4},
		{"m": "nature/flower_redA", "at": [0.15, -0.1], "s": 2.4},
		{"m": "nature/flower_yellowB", "at": [-0.15, 0.15], "s": 2.4},
		{"m": "nature/flower_redB", "at": [0.2, 0.25], "s": 2.4},
	]},
	"objects/lavender": {"size": [1, 1], "parts": [
		{"m": "nature/flower_purpleA", "at": [-0.22, -0.2], "s": 2.6},
		{"m": "nature/flower_purpleB", "at": [0.18, -0.15], "s": 2.6},
		{"m": "nature/flower_purpleC", "at": [-0.15, 0.2], "s": 2.6},
		{"m": "nature/flower_purpleA", "at": [0.22, 0.22], "s": 2.6},
	]},
	"objects/sunflower": {"size": [1, 1], "parts": [
		{"m": "nature/flower_yellowC", "at": [-0.15, -0.1], "s": [3.0, 5.0, 3.0]},
		{"m": "nature/flower_yellowC", "at": [0.2, 0.15], "s": [3.0, 4.0, 3.0]},
		{"m": "nature/grass_large", "at": [0.0, 0.25], "s": 1.5},
	]},
	"objects/potted_plant": {"size": [1, 1], "parts": [
		{"m": "nature/pot_large", "s": 1.4},
		{"m": "nature/plant_bush", "y": 0.25, "s": 1.8},
	]},
	"objects/cactus": {"size": [1, 1], "parts": [
		{"m": "nature/cactus_tall", "at": [-0.1, -0.05], "s": 1.3},
		{"m": "nature/cactus_short", "at": [0.25, 0.2], "s": 1.3},
	]},
	"objects/bamboo": {"size": [1, 1], "parts": [
		{"m": "nature/crops_bambooStageB", "at": [-0.15, -0.15], "s": 1.2},
		{"m": "nature/crops_bambooStageB", "at": [0.2, 0.0], "r": 40.0, "s": 1.05},
		{"m": "nature/crops_bambooStageA", "at": [-0.05, 0.25], "s": 1.2},
	]},
	"objects/rock_mossy": {"size": [1, 1], "parts": [
		{"m": "nature/rock_largeA", "s": 0.75, "tint": {"stone": "B5B0A4"}},
		{"m": "nature/grass_leafs", "at": [0.3, 0.25], "s": 1.5},
	]},
	"objects/sign_wood": {"size": [1, 1], "parts": [{"m": "nature/sign", "r": 45.0, "s": 1.8}]},
	"objects/statue": {"size": [1, 1], "parts": [
		{"m": "nature/statue_block", "s": [1.6, 0.6, 1.6]},
		{"m": "nature/statue_head", "y": 0.24, "s": 0.85},
	]},
	"objects/bench": {"size": [1, 1], "parts": [
		{"shape": "box", "size": [0.75, 0.06, 0.28], "y": 0.24, "color": "C98B5A"},
		{"shape": "box", "size": [0.75, 0.2, 0.05], "y": 0.42, "at": [0.0, -0.14], "color": "B97B4C"},
		{"shape": "box", "size": [0.06, 0.24, 0.26], "y": 0.12, "at": [-0.3, 0.0], "color": "5B4A3F"},
		{"shape": "box", "size": [0.06, 0.24, 0.26], "y": 0.12, "at": [0.3, 0.0], "color": "5B4A3F"},
	]},
	"objects/lamp": {"size": [1, 1], "parts": [
		{"shape": "cylinder", "size": [0.12, 0.08], "y": 0.04, "color": "3F5A4C"},
		{"shape": "cylinder", "size": [0.035, 0.95], "y": 0.5, "color": "3F5A4C"},
		{"shape": "sphere", "size": [0.13], "y": 1.02, "color": "FFE3A3", "glow": true},
		{"shape": "cylinder", "size": [0.09, 0.05], "y": 1.15, "color": "3F5A4C"},
	]},
	"objects/lantern_premium": {"size": [1, 1], "parts": [
		{"shape": "box", "size": [0.4, 0.12, 0.4], "y": 0.06, "color": "A39E94"},
		{"shape": "box", "size": [0.12, 0.45, 0.12], "y": 0.34, "color": "9C978C"},
		{"shape": "box", "size": [0.3, 0.24, 0.3], "y": 0.68, "color": "FFC86B", "glow": true},
		{"shape": "box", "size": [0.42, 0.06, 0.42], "y": 0.83, "color": "8E5F42"},
	]},
	"objects/fountain": {"size": [2, 2], "parts": [
		{"shape": "cylinder", "size": [0.85, 0.3], "y": 0.15, "color": "CFC8BC"},
		{"shape": "cylinder", "size": [0.74, 0.04], "y": 0.29, "color": "7EC8E3"},
		{"shape": "cylinder", "size": [0.12, 0.7], "y": 0.5, "color": "CFC8BC"},
		{"shape": "cylinder", "size": [0.32, 0.08], "y": 0.82, "color": "CFC8BC"},
		{"shape": "cylinder", "size": [0.26, 0.02], "y": 0.86, "color": "9FD8EC"},
		{"shape": "sphere", "size": [0.07], "y": 0.95, "color": "BFE8F5"},
	]},
	"objects/pond": {"size": [2, 2], "parts": [
		{"shape": "cylinder", "size": [0.86, 0.02], "y": 0.01, "color": "C9A57A"},
		{"shape": "cylinder", "size": [0.78, 0.03], "y": 0.015, "color": "7EC8E3"},
		{"m": "nature/lily_large", "at": [0.2, 0.15], "s": 1.6},
		{"m": "nature/lily_small", "at": [-0.25, 0.3], "s": 1.6},
		{"m": "nature/rock_smallA", "at": [0.75, -0.25], "s": 1.2},
		{"m": "nature/rock_smallC", "at": [-0.6, 0.55], "s": 1.2},
		{"m": "nature/grass_large", "at": [-0.6, -0.5], "s": 1.6},
		{"m": "nature/grass_large", "at": [0.45, 0.65], "s": 1.3},
	]},
	"objects/enclosure_meadow": {"size": [3, 3], "parts": [
		{"shape": "box", "size": [3.0, 0.04, 3.0], "y": 0.02, "color": "A5CF7A"},
		{"fence": "nature/fence_simpleLow", "span": 3},
		{"m": "nature/flower_yellowA", "at": [-1.1, -0.9], "s": 2.4},
		{"m": "nature/flower_redA", "at": [-0.8, -1.15], "s": 2.4},
		{"m": "nature/grass_large", "at": [1.0, -1.0], "s": 1.6},
		{"m": "nature/plant_bushLarge", "at": [-1.05, 0.9], "s": 1.8},
	]},
	"objects/enclosure_forest": {"size": [3, 3], "parts": [
		{"shape": "box", "size": [3.0, 0.04, 3.0], "y": 0.02, "color": "7FAF63"},
		{"fence": "nature/fence_simpleLow", "span": 3},
		{"m": "nature/tree_pineRoundC", "at": [-1.0, -1.0]},
		{"m": "nature/tree_pineRoundA", "at": [1.0, -1.05], "s": 0.8},
		{"m": "nature/stump_round", "at": [-1.0, 0.9], "s": 1.3},
		{"m": "nature/mushroom_redGroup", "at": [0.9, 0.95], "s": 2.0},
	]},
	"objects/enclosure_ice": {"size": [3, 3], "parts": [
		{"shape": "box", "size": [3.0, 0.04, 3.0], "y": 0.02, "color": "E4F1F5"},
		{"shape": "cylinder", "size": [0.6, 0.03], "y": 0.05, "at": [0.6, -0.6], "color": "8FD0E8"},
		{"fence": "nature/fence_simpleLow", "span": 3},
		{"m": "nature/rock_largeB", "at": [-1.0, -0.9], "s": 0.7, "tint": SNOW},
		{"m": "nature/rock_smallB", "at": [-0.9, 1.0], "s": 1.4, "tint": SNOW},
	]},
	"objects/enclosure_savanna": {"size": [4, 4], "parts": [
		{"shape": "box", "size": [4.0, 0.04, 4.0], "y": 0.02, "color": "E2C27A"},
		{"fence": "nature/fence_simpleLow", "span": 4},
		{"m": "nature/tree_plateau", "at": [-1.4, -1.3], "s": 1.3, "tint": {"leafsGreen": "8DB85A", "leafsDark": "79A54C"}},
		{"m": "nature/rock_largeC", "at": [1.3, -1.4], "s": 0.7},
		{"m": "nature/grass_large", "at": [-1.4, 1.3], "s": 1.8, "tint": DRY_GRASS},
		{"m": "nature/grass_large", "at": [1.3, 1.2], "s": 1.5, "tint": DRY_GRASS},
	]},
}
