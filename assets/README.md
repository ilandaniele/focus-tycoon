# Assets

Final art is dropped here. Code never changes: `ArtRegistry` loads `res://assets/<key>.png` when it exists and generates a placeholder otherwise.

## Source art

Objects and animals are rendered in Blender 4.5 (Cycles) from free CC0 models vendored in `art/`: Quaternius "Stylized Nature MegaKit" (`art/quaternius/`, trees, bushes, flowers, rocks), Gobkit animals (`art/gobkit/`) and Kenney "Nature Kit" (`art/kenney/nature/`, fences, palm, cactus, bamboo and props). `tools/blender/art_specs.json` composes each key from models, tints and simple shapes; `tools/blender/render_iso.py` shoots them with an orthographic isometric camera and a soft sun with a shadow catcher, and writes the PNGs:

```bash
blender -b --python-exit-code 1 -P tools/blender/render_iso.py                          # every object and animal
blender -b --python-exit-code 1 -P tools/blender/render_iso.py -- objects/fern animals/fox
godot --path . --headless --import
```

Ground tiles and paths still come from Kenney models through Godot: `tools/model_specs.gd` composes them and `tools/render_models.gd` renders them (needs a GPU, so no `--headless`): `godot --path . -s res://tools/render_models.gd`.

UI icons, placement marks and the contact shadow are hand-written SVGs in `art/ui/` and `art/fx/`, rendered by `godot --path . --headless -s res://tools/render_art.gd`.

`art/` holds a `.gdignore`, so Godot does not import the sources. PNGs are rendered at `ArtRegistry.ASSET_SCALE` (2x) and loaded at their logical size, so the canvas sizes below stay the contract while zoomed-in views stay sharp. Ground tiles are scaled back to 1x for the TileSet atlas. Animal sprites have no ground shadow because `fx/shadow` is drawn under them; objects draw their own. Animal strips have 8 frames each for `idle` and `walk`, sampled from the model's own animations; static models (`"size"` in `art_specs.json`) get a procedural breath and walk bob from `stage.static_motion`.

## Credits

3D models, CC0: Quaternius (quaternius.com), Stylized Nature MegaKit; Gobkit animals (see `art/gobkit/LICENSE.txt`), now only the puffin; Kenney (www.kenney.nl), Nature Kit.

Animal models, CC-BY 3.0 (attribution required, also shown in the app's Profile > Credits and in the store listings): Poly by Google, Хмара Сергей, jeremy and Anonymous, from poly.pizza. Per-model list in `art/polygoogle/CREDITS.md`.
## Naming

`assets/<category>/<id>[_<variant>][_<anim>].png`, lowercase `snake_case`. `<id>` is identical to the id in `data/catalog.json` or `data/species.json`.

| Key | File | Canvas (px) |
|---|---|---|
| `terrain/grass`, `terrain/locked`, `terrain/grid_ok` | `assets/terrain/<name>.png` | 128x64 diamond |
| `paths/<item_id>` | `assets/paths/<item_id>.png` | 128x64 diamond |
| `objects/<item_id>` | `assets/objects/<item_id>.png` | 1x1: 128x160, 2x2: 256x256, 3x3: 384x320, 4x4: 512x384 |
| `animals/<species_id>` | `assets/animals/<species_id>.png` | 96x96 |
| `ui/mark_ok`, `ui/mark_bad` | `assets/ui/<name>.png` | 40x40 placement marker |
| `ui/icon_<name>` | `assets/ui/icon_<name>.png` | 40x40 UI icon (`UIKit.icon(name)`) |
| `fx/shadow` | `assets/fx/shadow.png` | 64x24 contact shadow |

## Pivot

- Objects: the base diamond sits at the bottom of the canvas; its center is the anchor. For a footprint `n x m` the anchor is `(width / 2, height - (n + m) * 16)`.
- Animals: feet center at `(width / 2, height - 12)`.
- Tiles: full 128x64 diamond, centered.

## Rules

- Palette and style: see `docs/02-GDD.md`, section "Direccion de arte".
- Atlases (`terrain_atlas.png`, ...) are a later optimization; single PNGs per key work today.
- Do not rename files after `data/*.json` ids are published.

## Fonts

`assets/fonts/Nunito.ttf` is the variable Nunito font from google/fonts, under the SIL Open Font License (`assets/fonts/OFL.txt`). `ThemeFactory` uses weight 600 for body text and 800 for titles and buttons.
