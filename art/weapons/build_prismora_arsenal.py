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
        "obsidian": base.material("Arsenal black forged steel", (0.006, 0.009, 0.016), 0.96, 0.13),
        "gunmetal": base.material("Arsenal layered gunmetal", (0.025, 0.038, 0.060), 0.92, 0.18),
        "silver": base.material("Arsenal sharpened silver", (0.28, 0.39, 0.48), 0.98, 0.09),
        "gold": base.material("Arsenal antique solar gold", (0.42, 0.18, 0.025), 0.91, 0.14),
        "violet": base.material("Arsenal wrapped black violet", (0.035, 0.008, 0.055), 0.22, 0.34),
        "cyan": base.material("Arsenal cyan plasma", (0.001, 0.18, 0.34), 0.28, 0.10, (0.0, 0.72, 1.0), 4.8),
        "magenta": base.material("Arsenal magenta plasma", (0.28, 0.002, 0.10), 0.24, 0.11, (1.0, 0.0, 0.28), 4.2),
        "emerald": base.material("Arsenal emerald reactor", (0.002, 0.22, 0.08), 0.22, 0.10, (0.0, 1.0, 0.24), 4.6),
    }


def create_scintilla():
    m = common_materials()
    body, energy = [], []
    forearm = [(-0.66, -1.72), (-0.82, -1.28), (-0.72, -0.48), (-0.58, 0.38),
               (0.58, 0.38), (0.72, -0.48), (0.82, -1.28), (0.66, -1.72)]
    body.append(base.extruded_polygon("Scintilla tapered forearm shell", forearm, 0.88, m["gunmetal"], bevel=0.11))
    dorsal = [(-0.48, -1.46), (-0.58, -0.70), (-0.42, 0.22), (0, 0.62),
              (0.42, 0.22), (0.58, -0.70), (0.48, -1.46), (0, -1.66)]
    for z in (-0.50, 0.50):
        body.append(base.extruded_polygon("Scintilla dorsal layered plate", dorsal, 0.10, m["obsidian"], z=z, bevel=0.045))
    cuff = [(-0.88, -1.78), (-1.02, -1.48), (-0.82, -1.20), (0.82, -1.20),
            (1.02, -1.48), (0.88, -1.78)]
    body.append(base.extruded_polygon("Scintilla crown cuff", cuff, 1.02, m["gold"], bevel=0.10))
    palm = [(-0.62, 0.16), (-0.78, 0.58), (-0.62, 1.02), (-0.35, 1.24),
            (0.35, 1.24), (0.62, 1.02), (0.78, 0.58), (0.62, 0.16)]
    body.append(base.extruded_polygon("Scintilla armored palm", palm, 0.80, m["gunmetal"], bevel=0.10))
    for side in (-1, 1):
        fin = [(side * 0.58, -0.90), (side * 1.08, -0.54), (side * 0.92, 0.38), (side * 0.58, 0.66)]
        body.append(base.extruded_polygon("Scintilla swept side fin", fin, 0.52, m["silver"], bevel=0.07))
        edge = [(side * 0.66, -0.66), (side * 0.92, -0.44), (side * 0.82, 0.18), (side * 0.64, 0.36)]
        for z in (-0.31, 0.31):
            energy.append(base.extruded_polygon("Scintilla side pulse", edge, 0.045, m["magenta"] if side < 0 else m["cyan"], z=z, bevel=0.018))
    for index, x in enumerate((-0.49, -0.16, 0.16, 0.49)):
        for segment, y in enumerate((1.18, 1.50)):
            body.append(base.box("Scintilla articulated finger", (x, y, -0.03), (0.25, 0.48, 0.48), m["obsidian"] if segment else m["silver"], 0.065))
        claw = [(x - 0.12, 1.67), (x + 0.12, 1.67), (x, 2.02)]
        body.append(base.extruded_polygon("Scintilla claw tip", claw, 0.42, m["silver"], bevel=0.045))
        energy.append(base.box("Scintilla knuckle reactor", (x, 1.20, -0.31), (0.16, 0.20, 0.10), m["emerald"] if index % 2 == 0 else m["cyan"], 0.03))
    energy.append(base.cylinder("Scintilla emerald core", (0, -0.36, -0.56), 0.36, 0.20, m["emerald"], vertices=24, rotation=(0, 0, 0), bevel=0.045))
    for index, angle in enumerate(range(0, 360, 45)):
        radians = math.radians(angle)
        body.append(base.box("Scintilla reactor tooth", (math.cos(radians) * 0.50, -0.36 + math.sin(radians) * 0.50, -0.54), (0.16, 0.34, 0.14), m["gold"] if index % 2 == 0 else m["silver"], 0.035, (0, 0, radians)))
    for side in (-1, 1):
        channel = [(side * 0.08, -1.28), (side * 0.27, -1.02), (side * 0.28, -0.58), (side * 0.12, -0.42)]
        energy.append(base.extruded_polygon("Scintilla engraved vein", channel, 0.045, m["magenta"] if side < 0 else m["cyan"], z=-0.57, bevel=0.018))
    body_obj = base.join_named(body, "ScintillaV2_Body")
    energy_obj = base.join_named(energy, "ScintillaV2_Energy")
    marker = base.box("WeaponGripMarker", (0, 0.08, 0.0), (0.12, 0.12, 0.12), m["obsidian"], 0)
    marker.hide_render = True
    return body_obj, energy_obj, marker


def create_pulsar():
    m = common_materials()
    body, energy = [], []
    silhouette = [(-0.72, -0.22), (-0.62, 1.78), (-0.48, 2.46), (-0.24, 3.54),
                  (0.24, 3.54), (0.48, 2.74), (0.80, 2.32), (0.72, 0.52),
                  (0.46, -0.22), (0.34, -1.54), (-0.34, -1.54), (-0.52, -0.34)]
    body.append(base.extruded_polygon("Pulsar pistol chassis", silhouette, 0.82, m["gunmetal"], bevel=0.11))
    inner = [(-0.50, 0.16), (-0.40, 2.02), (-0.20, 2.92), (0.26, 2.92), (0.48, 2.12), (0.42, 0.24)]
    for z in (-0.48, 0.48):
        body.append(base.extruded_polygon("Pulsar obsidian shroud", inner, 0.10, m["obsidian"], z=z, bevel=0.05))
    body.append(base.box("Pulsar upper rail", (0, 2.72, 0), (0.58, 1.82, 1.04), m["silver"], 0.08))
    body.append(base.box("Pulsar muzzle cage", (0, 3.55, 0), (0.92, 0.60, 1.14), m["gold"], 0.09))
    body.append(base.box("Pulsar grip insert", (0, -0.85, 0), (0.62, 1.30, 0.72), m["violet"], 0.09, (0, 0, math.radians(-7))))
    body.append(base.box("Pulsar trigger guard", (0, -0.10, -0.02), (0.78, 0.22, 0.92), m["gold"], 0.06))
    energy.append(base.cylinder("Pulsar reactor", (0, 1.18, 0), 0.43, 0.98, m["emerald"], vertices=24, rotation=(0, 0, 0), bevel=0.05))
    for side in (-1, 1):
        energy.append(base.box("Pulsar side capacitor", (side * 0.57, 1.15, 0), (0.20, 1.15, 0.62), m["magenta"] if side < 0 else m["cyan"], 0.05))
    for z in (-0.56, 0.56):
        side_plate = [(-0.52, 0.38), (-0.56, 1.78), (-0.24, 2.48), (0.28, 2.40), (0.50, 1.74), (0.46, 0.48)]
        body.append(base.extruded_polygon("Pulsar engraved side plate", side_plate, 0.08, m["silver"], z=z, bevel=0.035))
        for index, y in enumerate((0.72, 1.12, 1.52, 1.92)):
            energy.append(base.box("Pulsar side rune", (0, y, z * 1.08), (0.34, 0.10, 0.055), m["cyan"] if index % 2 == 0 else m["magenta"], 0.02, (0, 0, math.radians(18 if index % 2 == 0 else -18))))
    for side in (-1, 1):
        body.append(base.box("Pulsar muzzle fang", (side * 0.54, 3.84, 0), (0.22, 0.78, 0.48), m["silver"], 0.05, (0, 0, math.radians(side * -12))))
        body.append(base.box("Pulsar rear stabilizer", (side * 0.62, 0.02, 0), (0.28, 0.82, 0.74), m["gunmetal"], 0.06, (0, 0, math.radians(side * 14))))
    energy.append(base.cylinder("Pulsar muzzle energy", (0, 3.88, 0), 0.28, 1.10, m["magenta"], vertices=24, rotation=(0, 0, 0), bevel=0.04))
    body.append(base.extruded_polygon("Pulsar lower hook", [(-0.28, -0.24), (-0.52, -0.62), (-0.44, -1.38), (-0.12, -1.68), (0.10, -1.32), (0.04, -0.48)], 0.90, m["obsidian"], bevel=0.065))
    body_obj = base.join_named(body, "PulsarV2_Body")
    energy_obj = base.join_named(energy, "PulsarV2_Energy")
    marker = base.box("WeaponGripMarker", (0, -0.88, 0), (0.12, 0.12, 0.12), m["obsidian"], 0)
    marker.hide_render = True
    return body_obj, energy_obj, marker


def create_frantuma():
    m = common_materials()
    body, energy = [], []
    body.append(base.cylinder("Frantuma shaft", (0, 0.62, 0), 0.25, 5.2, m["obsidian"], vertices=20))
    body.append(base.cylinder("Frantuma wrapped grip", (0, -0.92, 0), 0.40, 1.65, m["violet"], vertices=18))
    for index in range(7):
        body.append(base.torus("Frantuma grip ring", (0, -1.55 + index * 0.22, 0), 0.40, 0.052, m["gold"] if index in (0, 6) else m["gunmetal"]))
    body.append(base.box("Frantuma head spine", (0, 3.18, 0), (4.35, 0.58, 0.82), m["gunmetal"], 0.09))
    left_blade = [(-0.08, 2.78), (-0.72, 2.54), (-1.34, 2.24), (-2.10, 2.42),
                  (-2.72, 2.88), (-2.96, 3.48), (-2.56, 3.34), (-2.72, 4.04),
                  (-2.12, 4.52), (-1.28, 4.34), (-0.62, 3.86), (-0.10, 3.58)]
    right_blade = [(-x, y) for x, y in left_blade]
    body.append(base.extruded_polygon("Frantuma left blade", left_blade, 0.52, m["silver"], bevel=0.10))
    body.append(base.extruded_polygon("Frantuma right blade", right_blade, 0.52, m["silver"], bevel=0.10))
    for side in (-1, 1):
        inset = [(side * 0.24, 2.98), (side * 1.18, 2.60), (side * 2.28, 2.94), (side * 2.42, 3.34), (side * 1.76, 4.08), (side * 0.62, 3.58)]
        for z in (-0.32, 0.32):
            body.append(base.extruded_polygon("Frantuma obsidian blade inset", inset, 0.08, m["obsidian"], z=z, bevel=0.04))
    energy.append(base.cylinder("Frantuma core", (0, 3.20, 0), 0.48, 0.90, m["emerald"], vertices=24, rotation=(0, 0, 0), bevel=0.05))
    for side in (-1, 1):
        channel = [(side * 0.42, 3.02), (side * 1.18, 2.72), (side * 2.20, 3.04), (side * 1.76, 3.48), (side * 0.54, 3.40)]
        for z in (-0.37, 0.37):
            energy.append(base.extruded_polygon("Frantuma blade energy", channel, 0.05, m["magenta"] if side < 0 else m["cyan"], z=z, bevel=0.025))
    body.append(base.extruded_polygon("Frantuma crown spike", [(0, 3.48), (0.42, 4.30), (0, 5.12), (-0.42, 4.30)], 0.46, m["gold"], bevel=0.07))
    for side in (-1, 1):
        for index, y in enumerate((2.78, 3.18, 3.58, 3.98)):
            body.append(base.box("Frantuma armored blade rib", (side * (0.74 + index * 0.34), y, side * 0.34), (0.16, 0.72, 0.13), m["gunmetal"], 0.035, (0, 0, math.radians(side * (22 + index * 4)))))
        spike = [(side * 1.90, 2.56), (side * 2.54, 2.26), (side * 2.24, 2.82)]
        body.append(base.extruded_polygon("Frantuma lower fang", spike, 0.44, m["silver"], bevel=0.055))
    for index, y in enumerate((-0.70, 0.18, 1.04, 1.90)):
        energy.append(base.box("Frantuma shaft rune", (0, y, -0.30), (0.16, 0.38, 0.08), m["cyan"] if index % 2 == 0 else m["magenta"], 0.018, (0, 0, math.radians(28 if index % 2 == 0 else -28))))
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
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.28
    center, size = bounds_center_size((body, energy))
    longest = max(size.x, size.y, size.z)
    bpy.ops.object.camera_add(location=center + Vector((longest * 1.35, -longest * 1.05, longest * 1.18)))
    camera = bpy.context.object
    camera.data.lens = 54
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    for light_name, offset, energy_value, color in (
        ("Neutral key", (0.75, -0.2, 1.0), 1120, (0.78, 0.86, 1.0)),
        ("Emerald rim", (-0.85, 0.3, 0.75), 560, (0.05, 1.0, 0.30)),
        ("Magenta fill", (0.0, -0.8, 0.30), 320, (1.0, 0.04, 0.30)),
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
