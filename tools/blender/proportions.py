import bpy
from mathutils import Vector

LEGS = ("LeftLegF", "RightLegF", "LeftLegB", "RightLegB")
EYES = ("LeftEye", "RightEye")
EARS = ("LeftEar", "RightEar")
MOUTH = ("Mouth",)
BODY = "Spine"
CORE_WEIGHT = 0.5


def reshape(shape: dict) -> None:
    for body in bpy.data.objects:
        if body.type != "MESH" or not body.vertex_groups:
            continue
        weights = _weights(body)
        down = _down(weights)
        if down is None:
            continue
        for group in EYES:
            _scale(weights.get(group), shape["eyes"])
        for group in EARS:
            _scale(weights.get(group), shape["ears"])
        for group in LEGS:
            _stretch(weights.get(group), down, shape["legs"])
        for group in MOUTH:
            _stretch(weights.get(group), down, shape["mouth"])


def _weights(body: bpy.types.Object) -> dict:
    names = {group.index: group.name for group in body.vertex_groups}
    weights = {}
    for vertex in body.data.vertices:
        for link in vertex.groups:
            if link.weight > 0.0:
                weights.setdefault(names[link.group], []).append((vertex, link.weight))
    return weights


def _centroid(entries: list) -> Vector:
    total = sum(weight for _vertex, weight in entries)
    return sum((vertex.co * weight for vertex, weight in entries), Vector()) / total


def _down(weights: dict) -> Vector | None:
    if BODY not in weights or not all(leg in weights for leg in LEGS):
        return None
    feet = sum((_centroid(weights[leg]) for leg in LEGS), Vector()) / len(LEGS)
    return (feet - _centroid(weights[BODY])).normalized()


def _scale(entries: list | None, factor: float) -> None:
    if not entries or factor == 1.0:
        return
    center = _centroid(entries)
    for vertex, weight in entries:
        vertex.co += (vertex.co - center) * (factor - 1.0) * weight


def _stretch(entries: list | None, down: Vector, factor: float) -> None:
    if not entries or factor == 1.0:
        return
    core = [vertex.co.dot(down) for vertex, weight in entries if weight >= CORE_WEIGHT]
    if not core:
        return
    top = min(core)
    for vertex, weight in entries:
        depth = vertex.co.dot(down) - top
        if depth > 0.0:
            vertex.co += down * depth * (factor - 1.0) * weight
