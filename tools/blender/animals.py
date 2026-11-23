import math

import bpy
from mathutils import Vector

import parts

FACING_DEG = 90.0


def load(path: str, height: float) -> bpy.types.Object:
    root = parts.import_model(path)
    _drop_helpers(root)
    root.rotation_euler.z = math.radians(FACING_DEG)
    play("idle", 0.0)
    low, high = _bounds()
    scale = height / (high.z - low.z)
    center = (low + high) / 2.0
    root.scale = (scale, scale, scale)
    root.location = (-center.x * scale, -center.y * scale, -low.z * scale)
    return root


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
