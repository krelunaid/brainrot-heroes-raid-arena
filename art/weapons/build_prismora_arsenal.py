import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_raggialama_v2 as base


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "output"


def common_materials():
    return {
        "obsidian": base.material("Arsenal obsidian", (0.014, 0.022, 0.04), 0.92, 0.18),
        "gunmetal": base.material("Arsenal gunmetal", (0.07, 0.10, 0.15), 0.88, 0.24),
        "silver": base.material("Arsenal silver", (0.48, 0.62, 0.73), 0.94, 0.14),
        "gold": base.material("Arsenal solar gold", (0.73, 0.37, 0.055), 0.86, 0.20),
        "violet": base.material("Arsenal violet grip", (0.11, 0.025, 0.17), 0.18, 0.42),
        "cyan": base.material("Arsenal cyan energy", (0.005, 0.24, 0.46), 0.22, 0.17, (0.01, 0.58, 1.0), 3.2),
        "magenta": base.material("Arsenal magenta energy", (0.42, 0.008, 0.20), 0.2, 0.20, (1.0, 0.015, 0.34), 2.7),
    }


def create_scintilla():
    m = common_materials()
    body, energy = [], []
    body.append(base.box("Scintilla palm shell", (0, 0.0, 0), (1.25, 1.55, 0.82), m["gunmetal"], 0.13))
    body.append(base.box("Scintilla dorsal armour", (0, 0.12, -0.50), (0.96, 1.22, 0.22), m["obsidian"], 0.08))
    body.append(base.box("Scintilla wrist cuff", (0, -0.92, 0), (1.58, 0.54, 1.02), m["gold"], 0.11))
    body.append(base.box("Scintilla forearm brace", (0, -1.50, 0.04), (1.34, 0.78, 0.92), m["violet"], 0.10))
    for side in (-1, 1):
        body.append(base.box("Scintilla side plate", (side * 0.70, -0.05, 0.02), (0.28, 1.35, 0.90), m["silver"], 0.07, (0, 0, math.radians(side * 10))))
    for index, x in enumerate((-0.48, -0.16, 0.16, 0.48)):
        body.append(base.box("Scintilla finger armour", (x, 0.96, -0.03), (0.24, 0.62, 0.55), m["obsidian"], 0.08))
        energy.append(base.box("Scintilla knuckle emitter", (x, 1.24, -0.32), (0.17, 0.19, 0.14), m["cyan"] if index % 2 == 0 else m["magenta"], 0.04))
    energy.append(base.cylinder("Scintilla prism core", (0, 0.08, -0.62), 0.38, 0.22, m["cyan"], vertices=20, rotation=(0, 0, 0), bevel=0.05))
    for side in (-1, 1):
        channel = [(0.12 * side, -0.62), (0.30 * side, -0.42), (0.27 * side, 0.58), (0.10 * side, 0.82)]
        energy.append(base.extruded_polygon("Scintilla energy vein", channel, 0.05, m["magenta"] if side < 0 else m["cyan"], z=-0.66, bevel=0.02))
    body_obj = base.join_named(body, "ScintillaV2_Body")
    energy_obj = base.join_named(energy, "ScintillaV2_Energy")
    marker = base.box("WeaponGripMarker", (0, 0.08, 0.0), (0.12, 0.12, 0.12), m["obsidian"], 0)
    marker.hide_render = True
    return body_obj, energy_obj, marker


def create_pulsar():
    m = common_materials()
    body, energy = [], []
    silhouette = [
        (-0.68, -0.20), (-0.58, 1.85), (-0.40, 2.45), (-0.28, 3.32),
        (0.28, 3.32), (0.45, 2.52), (0.68, 2.18), (0.63, 0.55),
        (0.46, -0.18), (0.34, -1.42), (-0.28, -1.42), (-0.45, -0.30),
    ]
    body.append(base.extruded_polygon("Pulsar pistol chassis", silhouette, 0.82, m["gunmetal"], bevel=0.11))
    inner = [(-0.46, 0.20), (-0.38, 1.98), (-0.20, 2.76), (0.24, 2.76), (0.42, 2.08), (0.40, 0.28)]
    for z in (-0.48, 0.48):
        body.append(base.extruded_polygon("Pulsar obsidian shroud", inner, 0.10, m["obsidian"], z=z, bevel=0.05))
    body.append(base.box("Pulsar upper rail", (0, 2.70, 0), (0.62, 1.65, 1.05), m["silver"], 0.08))
    body.append(base.box("Pulsar muzzle cage", (0, 3.45, 0), (0.82, 0.54, 1.05), m["gold"], 0.09))
    body.append(base.box("Pulsar grip insert", (0, -0.85, 0), (0.62, 1.30, 0.72), m["violet"], 0.09, (0, 0, math.radians(-7))))
    body.append(base.box("Pulsar trigger guard", (0, -0.10, -0.02), (0.78, 0.22, 0.92), m["gold"], 0.06))
    energy.append(base.cylinder("Pulsar reactor", (0, 1.18, 0), 0.43, 0.98, m["cyan"], vertices=20, rotation=(0, 0, 0), bevel=0.05))
    for side in (-1, 1):
        energy.append(base.box("Pulsar side capacitor", (side * 0.57, 1.15, 0), (0.20, 1.15, 0.62), m["magenta"] if side < 0 else m["cyan"], 0.05))
    energy.append(base.cylinder("Pulsar muzzle energy", (0, 3.78, 0), 0.28, 1.02, m["magenta"], vertices=20, rotation=(0, 0, 0), bevel=0.04))
    body_obj = base.join_named(body, "PulsarV2_Body")
    energy_obj = base.join_named(energy, "PulsarV2_Energy")
    marker = base.box("WeaponGripMarker", (0, -0.88, 0), (0.12, 0.12, 0.12), m["obsidian"], 0)
    marker.hide_render = True
    return body_obj, energy_obj, marker


def create_frantuma():
    m = common_materials()
    body, energy = [], []
    body.append(base.cylinder("Frantuma shaft", (0, 0.62, 0), 0.28, 5.2, m["obsidian"], vertices=18))
    body.append(base.cylinder("Frantuma wrapped grip", (0, -0.92, 0), 0.40, 1.65, m["violet"], vertices=18))
    for index in range(7):
        body.append(base.torus("Frantuma grip ring", (0, -1.55 + index * 0.22, 0), 0.40, 0.052, m["gold"] if index in (0, 6) else m["gunmetal"]))
    body.append(base.box("Frantuma head spine", (0, 3.18, 0), (4.15, 0.62, 0.86), m["gunmetal"], 0.10))
    left_blade = [(-0.10, 2.78), (-1.40, 2.42), (-2.20, 2.72), (-2.58, 3.38), (-2.10, 4.18), (-1.30, 4.42), (-0.12, 3.65)]
    right_blade = [(-x, y) for x, y in left_blade]
    body.append(base.extruded_polygon("Frantuma left blade", left_blade, 0.52, m["silver"], bevel=0.10))
    body.append(base.extruded_polygon("Frantuma right blade", right_blade, 0.52, m["silver"], bevel=0.10))
    for side in (-1, 1):
        inset = [(side * 0.25, 3.00), (side * 1.38, 2.72), (side * 2.10, 3.24), (side * 1.72, 3.92), (side * 0.65, 3.62)]
        for z in (-0.32, 0.32):
            body.append(base.extruded_polygon("Frantuma obsidian blade inset", inset, 0.08, m["obsidian"], z=z, bevel=0.04))
    energy.append(base.cylinder("Frantuma core", (0, 3.20, 0), 0.61, 0.96, m["cyan"], vertices=24, rotation=(0, 0, 0), bevel=0.06))
    for side in (-1, 1):
        channel = [(side * 0.40, 3.05), (side * 1.35, 2.88), (side * 1.92, 3.22), (side * 1.35, 3.58), (side * 0.42, 3.42)]
        for z in (-0.37, 0.37):
            energy.append(base.extruded_polygon("Frantuma blade energy", channel, 0.05, m["magenta"] if side < 0 else m["cyan"], z=z, bevel=0.025))
    body.append(base.extruded_polygon("Frantuma crown spike", [(0, 3.52), (0.46, 4.36), (0, 4.92), (-0.46, 4.36)], 0.50, m["gold"], bevel=0.08))
    body_obj = base.join_named(body, "FrantumaV2_Body")
    energy_obj = base.join_named(energy, "FrantumaV2_Energy")
    marker = base.box("WeaponGripMarker", (0, -0.92, 0), (0.12, 0.12, 0.12), m["obsidian"], 0)
    marker.hide_render = True
    return body_obj, energy_obj, marker


BUILDERS = {
    "Scintilla": create_scintilla,
    "Pulsar": create_pulsar,
    "Frantuma": create_frantuma,
}


def bounds_center_size(objects):
    points = []
    for obj in objects:
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return (minimum + maximum) * 0.5, maximum - minimum


def render_preview(name, body, energy):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.filepath = str(OUTPUT / f"Prismora_{name}_V2.png")
    world = scene.world or bpy.data.worlds.new("Arsenal preview world")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.004, 0.007, 0.018, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.15
    center, size = bounds_center_size((body, energy))
    longest = max(size.x, size.y, size.z)
    bpy.ops.object.camera_add(location=center + Vector((longest * 0.78, -longest * 0.55, longest * 1.15)))
    camera = bpy.context.object
    camera.data.lens = 58
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    for light_name, offset, energy_value, color in (
        ("Cool key", (0.75, -0.2, 1.0), 1200, (0.28, 0.78, 1.0)),
        ("Warm rim", (-0.85, 0.3, 0.75), 950, (1.0, 0.10, 0.38)),
        ("Gold fill", (0.0, -0.8, 0.30), 620, (1.0, 0.52, 0.12)),
    ):
        data = bpy.data.lights.new(light_name, "AREA")
        data.energy = energy_value
        data.color = color
        data.shape = "DISK"
        data.size = longest * 0.42
        light = bpy.data.objects.new(light_name, data)
        bpy.context.collection.objects.link(light)
        light.location = center + Vector(offset) * longest
        light.rotation_euler = (center - light.location).to_track_quat("-Z", "Y").to_euler()
    body.rotation_euler[2] = math.radians(-12)
    energy.rotation_euler[2] = math.radians(-12)
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    body.rotation_euler = (0, 0, 0)
    energy.rotation_euler = (0, 0, 0)


def export_asset(name, objects):
    output = OUTPUT / f"Prismora_{name}_V2.fbx"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.fbx(
        filepath=str(output),
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
        bake_anim=False,
    )
    return output


def build_one(name, builder):
    base.clear_scene()
    body, energy, marker = builder()
    objects = (body, energy, marker)
    triangles = base.triangle_count(objects)
    if triangles > 18000:
        raise RuntimeError(f"{name} exceeds mobile triangle budget: {triangles}")
    render_preview(name, body, energy)
    base.bake_color_texture(body, f"Prismora_{name}_V2_Body")
    base.bake_color_texture(energy, f"Prismora_{name}_V2_Energy", emissive=True)
    fbx = export_asset(name, objects)
    blend = OUTPUT / f"Prismora_{name}_V2.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    print(f"PRISMORA_ARSENAL_READY name={name} triangles={triangles} fbx={fbx}")


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, builder in BUILDERS.items():
        build_one(name, builder)


if __name__ == "__main__":
    main()
