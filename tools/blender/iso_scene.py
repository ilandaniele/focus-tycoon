import math
import os
import tempfile

import bpy
import numpy as np
from mathutils import Vector

CAMERA_DISTANCE = 20.0
CAMERA_PITCH = math.radians(30.0)
CAMERA_YAW = math.radians(45.0)
TRANSPARENT_BOUNCES = 128


def reset(stage: dict) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = stage["samples"]
    scene.cycles.use_denoising = True
    scene.cycles.transparent_max_bounces = TRANSPARENT_BOUNCES
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _add_world(stage)
    _add_sun(stage)
    _add_camera()


def pixels_per_unit(stage: dict) -> float:
    return stage["tile"][0] * stage["asset_scale"] / math.sqrt(2.0)


def frame(stage: dict, canvas: tuple, anchor: tuple) -> None:
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = canvas
    camera = scene.camera
    ppu = pixels_per_unit(stage)
    camera.data.ortho_scale = canvas[1] / ppu
    direction = Vector((
        math.cos(CAMERA_PITCH) * math.sin(CAMERA_YAW),
        -math.cos(CAMERA_PITCH) * math.cos(CAMERA_YAW),
        math.sin(CAMERA_PITCH),
    ))
    rotation = (-direction).to_track_quat("-Z", "Y")
    right = rotation @ Vector((1.0, 0.0, 0.0))
    up = rotation @ Vector((0.0, 1.0, 0.0))
    offset_x = anchor[0] - canvas[0] / 2.0
    offset_y = anchor[1] - canvas[1] / 2.0
    camera.rotation_mode = "QUATERNION"
    camera.rotation_quaternion = rotation
    camera.location = direction * CAMERA_DISTANCE + (right * -offset_x + up * offset_y) / ppu


def capture() -> np.ndarray:
    scene = bpy.context.scene
    path = os.path.join(tempfile.gettempdir(), "focus_tycoon_iso_frame.png")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(path)
    width, height = image.size
    pixels = np.empty(width * height * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(height, width, 4)


def fade_shadow_floor(pixels: np.ndarray, floor: float) -> np.ndarray:
    shadow = (pixels[..., 3] < 0.5) & (pixels[..., :3].max(axis=2) < 0.1)
    faded = np.clip((pixels[..., 3] - floor) / (1.0 - floor), 0.0, 1.0)
    pixels[..., 3] = np.where(shadow, faded, pixels[..., 3])
    return pixels


def save(pixels: np.ndarray, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    height, width = pixels.shape[:2]
    image = bpy.data.images.new("iso_out", width, height, alpha=True)
    image.pixels.foreach_set(pixels.ravel())
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)
    print("%s (%dx%d)" % (path, width, height))


def _add_world(stage: dict) -> None:
    world = bpy.data.worlds.new("iso_world")
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    background.inputs["Strength"].default_value = stage["ambient"]
    bpy.context.scene.world = world


def _add_sun(stage: dict) -> None:
    sun = bpy.data.lights.new("iso_sun", "SUN")
    sun.energy = stage["sun_energy"]
    sun.angle = math.radians(stage["sun_softness_deg"])
    body = bpy.data.objects.new("iso_sun", sun)
    body.rotation_mode = "QUATERNION"
    body.rotation_quaternion = Vector(stage["sun_direction"]).to_track_quat("-Z", "Y")
    bpy.context.scene.collection.objects.link(body)


def _add_camera() -> None:
    camera = bpy.data.cameras.new("iso_camera")
    camera.type = "ORTHO"
    camera.sensor_fit = "VERTICAL"
    camera.clip_end = CAMERA_DISTANCE * 4.0
    body = bpy.data.objects.new("iso_camera", camera)
    bpy.context.scene.collection.objects.link(body)
    bpy.context.scene.camera = body
