import math
import os

import bpy
from mathutils import Vector

ROUGHNESS = 0.9
GLOW_STRENGTH = 1.2
FOLIAGE_GLOW = 0.45
CYLINDER_SEGMENTS = 24
FENCE_JITTER = 0.004


def build(parts: list, palette: dict, art_dir: str, flat: list, glow: list) -> None:
    for part in _expand(parts):
        root = _model(part, palette, art_dir, flat, glow) if "m" in part else _shape(part)
        at = part.get("at", [0.0, 0.0])
        root.location = (at[0], -at[1], float(part.get("y", 0.0)))
        root.rotation_euler.z = math.radians(float(part.get("r", 0.0)))
        root.scale = _scale(part.get("s", 1.0))


def add_shadow_catcher(width: float, depth: float) -> None:
    bpy.ops.mesh.primitive_plane_add(size=1.0)
    plane = bpy.context.active_object
    plane.scale = (width, depth, 1.0)
    plane.is_shadow_catcher = True


def import_model(path: str) -> bpy.types.Object:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [body for body in bpy.data.objects if body not in before]
    root = bpy.data.objects.new(os.path.basename(path), None)
    bpy.context.scene.collection.objects.link(root)
    for body in imported:
        if body.parent is None:
            body.parent = root
    return root


def srgb_to_linear(hex_color: str) -> tuple:
    channels = [int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return (*linear, 1.0)


def _expand(parts: list) -> list:
    expanded = []
    for part in parts:
        if "fence" in part:
            expanded.extend(_fence(part["fence"], int(part["span"])))
        else:
            expanded.append(part)
    return expanded


def _fence(model: str, span: int) -> list:
    pieces = []
    edge = span / 2.0 - 0.5
    for rotation in (0.0, 90.0, 180.0, -90.0):
        angle = -math.radians(rotation)
        direction = _rotate((0.0, -edge), angle)
        along = _rotate((1.0, 0.0), angle)
        for index in range(span):
            offset = index - edge
            at = [direction[0] + along[0] * offset, direction[1] + along[1] * offset]
            pieces.append({"m": model, "at": at, "r": rotation, "s": 1.0 + FENCE_JITTER * (len(pieces) % 2)})
    return pieces


def _rotate(vector: tuple, angle: float) -> tuple:
    cos, sin = math.cos(angle), math.sin(angle)
    return (vector[0] * cos - vector[1] * sin, vector[0] * sin + vector[1] * cos)


def _model(part: dict, palette: dict, art_dir: str, flat: list, glow: list) -> bpy.types.Object:
    root = import_model(_model_path(art_dir, part["m"]))
    tints = {**palette, **part.get("tint", {})}
    for body in root.children_recursive:
        for slot in getattr(body, "material_slots", []):
            if slot.material is not None:
                _restyle(slot.material, tints, flat, glow)
    return root


def _model_path(art_dir: str, name: str) -> str:
    for extension in (".glb", ".gltf"):
        path = os.path.join(art_dir, name + extension)
        if os.path.exists(path):
            return path
    raise FileNotFoundError(name)


def _restyle(material: bpy.types.Material, tints: dict, flat: list, glow: list) -> None:
    bsdf = _principled(material)
    if bsdf is None:
        return
    bsdf.inputs["Roughness"].default_value = ROUGHNESS
    bsdf.inputs["Metallic"].default_value = 0.0
    name = material.name.split(".")[0]
    tint = tints.get(name)
    base = bsdf.inputs["Base Color"]
    if name in flat:
        for link in list(base.links):
            material.node_tree.links.remove(link)
    if base.is_linked:
        color = _link_texture(material.node_tree, base, tint)
        if bsdf.inputs["Alpha"].is_linked:
            material.node_tree.links.new(color, bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = FOLIAGE_GLOW
    elif tint is not None:
        base.default_value = srgb_to_linear(tint)
        if name in glow:
            bsdf.inputs["Emission Color"].default_value = base.default_value
            bsdf.inputs["Emission Strength"].default_value = FOLIAGE_GLOW


def _link_texture(tree: bpy.types.NodeTree, base: bpy.types.NodeSocket, tint) -> bpy.types.NodeSocket:
    texture = next(node for node in tree.nodes if node.type == "TEX_IMAGE")
    source = texture.outputs["Color"]
    if tint is not None:
        mix = tree.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        gray = tree.nodes.new("ShaderNodeRGBToBW")
        tree.links.new(source, gray.inputs["Color"])
        tree.links.new(gray.outputs["Val"], _socket(mix.inputs, "A_Color"))
        _socket(mix.inputs, "B_Color").default_value = srgb_to_linear(tint)
        source = _socket(mix.outputs, "Result_Color")
    tree.links.new(source, base)
    return source


def _socket(sockets, identifier: str) -> bpy.types.NodeSocket:
    return next(socket for socket in sockets if socket.identifier == identifier)


def _principled(material: bpy.types.Material):
    if not material.use_nodes:
        return None
    return next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)


def _shape(part: dict) -> bpy.types.Object:
    dims = part.get("size", [1.0, 1.0, 1.0])
    kind = part["shape"]
    if kind == "box":
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        bpy.context.active_object.dimensions = (dims[0], dims[2], dims[1])
    elif kind == "cylinder":
        bpy.ops.mesh.primitive_cylinder_add(radius=dims[0], depth=dims[1], vertices=CYLINDER_SEGMENTS)
    else:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=dims[0])
    body = bpy.context.active_object
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if kind != "box":
        bpy.ops.object.shade_smooth()
    body.data.materials.append(_flat_material(part))
    return body


def _flat_material(part: dict) -> bpy.types.Material:
    material = bpy.data.materials.new("shape")
    material.use_nodes = True
    bsdf = _principled(material)
    color = srgb_to_linear(part.get("color", "FFFFFF"))
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = ROUGHNESS
    if part.get("glow", False):
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = GLOW_STRENGTH
    return material


def _scale(value) -> Vector:
    if isinstance(value, list):
        return Vector((value[0], value[2], value[1]))
    return Vector((value, value, value))
