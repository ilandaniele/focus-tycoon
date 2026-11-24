import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np

import animals
import iso_scene
import parts

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART_DIR = os.path.join(PROJECT_DIR, "art")
TARGET_DIR = os.path.join(PROJECT_DIR, "assets")
SPECS_PATH = os.path.join(os.path.dirname(__file__), "art_specs.json")


def main(only: list) -> None:
    with open(SPECS_PATH, encoding="utf-8") as handle:
        specs = json.load(handle)
    stage = specs["stage"]
    rendered = 0
    for key, spec in specs["objects"].items():
        if _wanted(key, only):
            render_object(stage, specs["palette"], key, spec)
            rendered += 1
    for group in ("animals", "visitors"):
        for actor_id, spec in specs[group].items():
            key = "%s/%s" % (group, actor_id)
            if _wanted(key, only):
                render_actor(stage, key, spec)
                rendered += 1
    print("%d keys rendered" % rendered)


def render_object(stage: dict, palette: dict, key: str, spec: dict) -> None:
    width, depth = spec["size"]
    base = spec.get("canvas", stage["object_canvas"]["%dx%d" % (width, depth)])
    canvas = (base[0] * stage["asset_scale"], base[1] * stage["asset_scale"])
    anchor = (canvas[0] / 2.0, canvas[1] - (width + depth) * 16.0 * stage["asset_scale"])
    iso_scene.reset(stage)
    parts.build(spec["parts"], palette, ART_DIR, stage["flat_materials"], stage["glow_materials"])
    parts.add_shadow_catcher(width, depth)
    iso_scene.frame(stage, canvas, anchor)
    iso_scene.save(iso_scene.fade_shadow_floor(iso_scene.capture(), stage["shadow_floor"]), _target(key))


def render_actor(stage: dict, key: str, spec: dict) -> None:
    scale = stage["asset_scale"]
    canvas = (stage["animal_canvas"][0] * scale, stage["animal_canvas"][1] * scale)
    anchor = (canvas[0] / 2.0, canvas[1] - stage["foot_margin"] * scale)
    count = stage["animal_frames"]
    iso_scene.reset({**stage, "ambient": stage["animal_ambient"]})
    shape = {**stage["animal_shape"], **spec.get("shape", {})}
    motion = animals.load(os.path.join(ART_DIR, spec["model"]), spec, shape)
    rigged = animals.rigged()
    if rigged:
        look = stage["animal_look"]
        animals.soften(look["subdivision"], look["sheen"])
    animals.tint(spec.get("tint", 1.0))
    iso_scene.frame(stage, canvas, anchor)
    for action in ("idle", "walk"):
        frames = []
        for index in range(count):
            if rigged:
                clip = animals.clip(spec, action)
                start, end = animals.frame_range(clip)
                animals.play(clip, start + (end - start) * index / count)
            else:
                animals.sway(motion, action, index / count, stage["static_motion"])
            frames.append(iso_scene.capture())
        if action == "idle":
            iso_scene.save(frames[0], _target(key))
        iso_scene.save(np.concatenate(frames, axis=1), _target("%s_%s" % (key, action)))


def _wanted(key: str, only: list) -> bool:
    return not only or key in only


def _target(key: str) -> str:
    return os.path.join(TARGET_DIR, *key.split("/")) + ".png"


if __name__ == "__main__":
    arguments = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    main(arguments)
