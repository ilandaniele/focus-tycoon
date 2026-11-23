import math

import bpy
from mathutils import Vector

import parts
import proportions

FACING_DEG = 90.0


def load(path: str, spec: dict, shape: dict) -> bpy.types.Object:
    root = parts.import_model(path)
    _drop_helpers(root)
    root.rotation_euler.z = math.radians(FACING_DEG)
    if rigged():
        proportions.reshape(shape)
        play("idle", 0.0)
        low, high = _bounds()
        scale = spec["height"] / (high.z - low.z)
    else:
        low, high = _bounds()
        scale = spec["size"] / max(high - low)
    center = (low + high) / 2.0
    root.scale = (scale, scale, scale)
    root.location = (-center.x * scale, -center.y * scale, -low.z * scale)
    motion = bpy.data.objects.new("motion", None)
    bpy.context.scene.collection.objects.link(motion)
    root.parent = motion
    return motion


def rigged() -> bool:
    return any(body.type == "ARMATURE" for body in bpy.data.objects)


def sway(motion: bpy.types.Object, action: str, phase: float, style: dict) -> None:
    wave = math.sin(2.0 * math.pi * phase)
    if action == "idle":
        breath = 1.0 + style["breath"] * wave
        motion.scale = (1.0, 1.0, breath)
        motion.location.z = 0.0
        motion.rotation_euler.y = 0.0
    else:
        motion.scale = (1.0, 1.0, 1.0)
        motion.location.z = style["bob"] * abs(wave)
        motion.rotation_euler.y = math.radians(style["rock_deg"]) * wave
    bpy.context.view_layer.update()


def tint(factor: float) -> None:
    if factor == 1.0:
        return
    for material in bpy.data.materials:
        bsdf = parts.principled(material)
        if bsdf is None:
            continue
        color = bsdf.inputs["Base Color"]
        if color.is_linked:
            mix = material.node_tree.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0
            mix.inputs["B"].default_value = (factor, factor, factor, 1.0)
            material.node_tree.links.new(color.links[0].from_socket, mix.inputs["A"])
            material.node_tree.links.new(mix.outputs["Result"], color)
        else:
            value = color.default_value
            color.default_value = (value[0] * factor, value[1] * factor, value[2] * factor, value[3])


def soften(levels: int, sheen: float) -> None:
    for body in [body for body in bpy.data.objects if body.type == "MESH"]:
        body.data.shade_smooth()
        body.modifiers.new("weld", "WELD")
        _crease_open_edges(body.data)
        surface = body.modifiers.new("soften", "SUBSURF")
        surface.levels = levels
        surface.render_levels = levels
    for material in bpy.data.materials:
        bsdf = parts.principled(material)
        if bsdf is not None:
            bsdf.inputs["Sheen Weight"].default_value = sheen


def _crease_open_edges(mesh: bpy.types.Mesh) -> None:
    faces_per_edge = {}
    for polygon in mesh.polygons:
        for key in polygon.edge_keys:
            faces_per_edge[key] = faces_per_edge.get(key, 0) + 1
    crease = mesh.attributes.new("crease_edge", "FLOAT", "EDGE")
    for edge in mesh.edges:
        crease.data[edge.index].value = 1.0 if faces_per_edge.get(edge.key) == 1 else 0.0


def frame_range(name: str) -> tuple:
    start, end = bpy.data.actions[name].frame_range
    return start, end


def play(name: str, frame: float) -> None:
    action = bpy.data.actions[name]
    for armature in [body for body in bpy.data.objects if body.type == "ARMATURE"]:
        data = armature.animation_data or armature.animation_data_create()
        for track in data.nla_tracks:
            track.mute = True
        data.action = action
        if action.slots:
            data.action_slot = action.slots[0]
    whole = math.floor(frame)
    bpy.context.scene.frame_set(int(whole), subframe=frame - whole)


def _drop_helpers(root: bpy.types.Object) -> None:
    for body in list(root.children_recursive):
        if body.type == "MESH" and not body.data.materials:
            bpy.data.objects.remove(body)


def _bounds() -> tuple:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    points = []
    for body in bpy.data.objects:
        if body.type != "MESH":
            continue
        evaluated = body.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        points.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        evaluated.to_mesh_clear()
    low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return low, high
