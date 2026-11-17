extends RefCounted

const IsoStage := preload("res://tools/iso_stage.gd")
const ModelSpecs := preload("res://tools/model_specs.gd")


static func build(stage: IsoStage, parts: Array) -> void:
	for part: Dictionary in _expand(parts):
		var node := _model(part) if part.has("m") else _shape(part)
		var at: Array = part.get("at", [0.0, 0.0])
		node.position = Vector3(at[0], float(part.get("y", 0.0)), at[1])
		node.rotation_degrees.y = float(part.get("r", 0.0))
		node.scale *= _scale(part.get("s", 1.0))
		stage.add(node)


static func _expand(parts: Array) -> Array:
	var expanded := []
	for part: Dictionary in parts:
		if part.has("fence"):
			expanded.append_array(_fence(part["fence"], int(part["span"])))
		else:
			expanded.append(part)
	return expanded


static func _fence(model: String, span: int) -> Array:
	var pieces := []
	var edge := span / 2.0 - 0.5
	for rotation in [0.0, 90.0, 180.0, -90.0]:
		var direction := Vector2(0.0, -edge).rotated(-deg_to_rad(rotation))
		var along := Vector2(1.0, 0.0).rotated(-deg_to_rad(rotation))
		for index in span:
			var at := direction + along * (index - edge)
			pieces.append({"m": model, "at": [at.x, at.y], "r": rotation})
	return pieces


static func _model(part: Dictionary) -> Node3D:
	var model := IsoStage.load_model(part["m"])
	var tints: Dictionary = ModelSpecs.PALETTE.duplicate()
	tints.merge(part.get("tint", {}), true)
	_tint(model, tints)
	return model


static func _tint(model: Node3D, tints: Dictionary) -> void:
	for mesh_node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh_node as MeshInstance3D
		for surface in instance.mesh.get_surface_count():
			var material := instance.mesh.surface_get_material(surface) as BaseMaterial3D
			if material == null:
				continue
			var copy := material.duplicate() as BaseMaterial3D
			copy.metallic = 0.0
			copy.roughness = 0.9
			if tints.has(material.resource_name):
				copy.albedo_color = Color(tints[material.resource_name])
			instance.set_surface_override_material(surface, copy)


static func _shape(part: Dictionary) -> MeshInstance3D:
	var dims: Array = part.get("size", [1.0, 1.0, 1.0])
	var mesh: PrimitiveMesh
	match part["shape"]:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3(dims[0], dims[1], dims[2])
			mesh = box
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = dims[0]
			cylinder.bottom_radius = dims[0]
			cylinder.height = dims[1]
			cylinder.radial_segments = 24
			mesh = cylinder
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = dims[0]
			sphere.height = dims[0] * 2.0
			mesh = sphere
	mesh.material = _material(part)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance


static func _material(part: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(part.get("color", "FFFFFF"))
	material.roughness = 0.9
	if part.get("glow", false):
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.2
	return material


static func _scale(value: Variant) -> Vector3:
	if value is Array:
		return Vector3(value[0], value[1], value[2])
	return Vector3.ONE * float(value)
