# Assets

Final art is dropped here. Code never changes: `ArtRegistry` loads `res://assets/<key>.png` when it exists and generates a placeholder otherwise.

## Source art

World art (terrain, paths, objects, animals) is rendered from 3D models of two Kenney CC0 packs vendored in `art/kenney/` ("Nature Kit" and "Cube Pets", see each `License.txt`). `tools/model_specs.gd` composes each key from models, tints and simple shapes; `tools/render_models.gd` shoots them with an orthographic isometric camera (`tools/iso_stage.gd`) and writes the PNGs. It needs a GPU, so it runs without `--headless`:

```bash
godot --path . -s res://tools/render_models.gd              # every key
godot --path . -s res://tools/render_models.gd -- objects/fern animals/panda
godot --path . --headless --import
```

UI icons, placement marks and the contact shadow are hand-written SVGs in `art/ui/` and `art/fx/`, rendered by `godot --path . --headless -s res://tools/render_art.gd`.

`art/` holds a `.gdignore`, so Godot does not import the sources. PNGs are rendered at `ArtRegistry.ASSET_SCALE` (2x) and loaded at their logical size, so the canvas sizes below stay the contract while zoomed-in views stay sharp. Ground tiles are scaled back to 1x for the TileSet atlas. Animal sprites have no ground shadow because `fx/shadow` is drawn under them; objects draw their own. Animal strips have 8 frames each for `idle` and `walk`, taken from the model's own animations.

## Credits

3D models: Kenney (www.kenney.nl), Nature Kit and Cube Pets, CC0.
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
