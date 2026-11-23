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


def add_outline(width: float, color: str) -> None:
    bpy.context.view_layer.update()
    material = _outline_material(color)
    for body in [body for body in bpy.data.objects if body.type == "MESH"]:
        body.data.materials.append(material)
        scale = sum(body.matrix_world.to_scale()) / 3.0
        hull = body.modifiers.new("outline", "SOLIDIFY")
        hull.thickness = width / scale
        hull.offset = 1.0
        hull.use_flip_normals = True
        hull.use_rim = False
        hull.material_offset = len(body.data.materials) - 1


def _outline_material(color: str) -> bpy.types.Material:
    material = bpy.data.materials.new("outline")
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    emission = tree.nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = parts.srgb_to_linear(color)
    hidden = tree.nodes.new("ShaderNodeBsdfTransparent")
    facing = tree.nodes.new("ShaderNodeNewGeometry")
    mix = tree.nodes.new("ShaderNodeMixShader")
    tree.links.new(facing.outputs["Backfacing"], mix.inputs["Fac"])
    tree.links.new(emission.outputs["Emission"], mix.inputs[1])
    tree.links.new(hidden.outputs["BSDF"], mix.inputs[2])
    path = tree.nodes.new("ShaderNodeLightPath")
    camera_only = tree.nodes.new("ShaderNodeMixShader")
    tree.links.new(path.outputs["Is Camera Ray"], camera_only.inputs["Fac"])
    tree.links.new(hidden.outputs["BSDF"], camera_only.inputs[1])
    tree.links.new(mix.outputs["Shader"], camera_only.inputs[2])
    tree.links.new(camera_only.outputs["Shader"], output.inputs["Surface"])
    return material


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
