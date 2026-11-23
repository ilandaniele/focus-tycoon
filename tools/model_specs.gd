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

const GROUND := [1.1, 0.04, 1.1]
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
