import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "output"
sys.path.insert(0, str(ROOT.parent / "weapons"))
import build_raggialama_v2 as base

# Reuse the proven weapon bake helpers, but keep every generated monster asset
# inside the enemy pipeline rather than leaking textures into art/weapons.
base.OUTPUT = OUTPUT


def mats(name):
    palettes = {
        "Scheggino": ((0.025, 0.035, 0.060), (0.18, 0.27, 0.34), (0.0, 0.82, 1.0)),
        "Rapido": ((0.015, 0.030, 0.060), (0.16, 0.30, 0.42), (0.04, 0.95, 0.72)),
        "Gonfio": ((0.050, 0.025, 0.065), (0.30, 0.13, 0.34), (1.0, 0.10, 0.48)),
        "Tessitore": ((0.018, 0.048, 0.045), (0.10, 0.30, 0.25), (0.28, 1.0, 0.58)),
        "Guscione": ((0.040, 0.035, 0.060), (0.26, 0.20, 0.38), (0.66, 0.24, 1.0)),
        "Monolite": ((0.012, 0.014, 0.026), (0.19, 0.20, 0.29), (1.0, 0.28, 0.07)),
    }
    dark, plate, glow = palettes[name]
    return {
        "dark": base.material(f"{name} abyss alloy", dark, 0.88, 0.20),
        "plate": base.material(f"{name} carved armour", plate, 0.78, 0.24),
        "edge": base.material(f"{name} blade edge", (0.30, 0.38, 0.46), 0.94, 0.12),
        "bone": base.material(f"{name} crystal bone", (0.42, 0.36, 0.30), 0.22, 0.34),
        "glow": base.material(f"{name} living prism", glow, 0.20, 0.08, glow, 5.8),
        "hot": base.material(f"{name} hot core", (1.0, 0.14, 0.02), 0.18, 0.08, (1.0, 0.08, 0.01), 7.0),
    }


def ico(name, location, scale, mat, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Armour bevel", "BEVEL")
    bevel.width = 0.035
    bevel.segments = 1
    return obj


def cone(name, location, radius1, radius2, depth, mat, rotation=(0, 0, 0), vertices=8):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Forged bevel", "BEVEL")
    bevel.width = 0.045
    bevel.segments = 1
    return obj


def limb(name, start, end, radius, mat, vertices=8):
    start, end = Vector(start), Vector(end)
    delta = end - start
    midpoint = (start + end) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Joint bevel", "BEVEL")
    bevel.width = min(radius * 0.26, 0.08)
    bevel.segments = 1
    return obj


def eye_pair(energy, mat, center, spread=0.34, size=(0.12, 0.08, 0.10)):
    x, y, z = center
    for side in (-1, 1):
        energy.append(ico("Predator eye", (x + side * spread, y, z), size, mat, subdivisions=2))


def marker(mat, z=1.0):
    obj = base.box("EnemyRootMarker", (0, 0, z), (0.12, 0.12, 0.12), mat, 0)
    obj.hide_render = True
    obj.display_type = "WIRE"
    return obj


def scheggino():
    m, body, energy = mats("Scheggino"), [], []
    body += [
        ico("Shardhound rib cage", (0, 0.15, 1.75), (1.18, 1.68, 0.82), m["dark"]),
        ico("Shardhound shoulder armour", (0, -0.72, 1.92), (1.30, 0.80, 0.92), m["plate"]),
        ico("Shardhound head", (0, -1.68, 2.05), (0.82, 0.78, 0.72), m["plate"]),
        ico("Shardhound muzzle", (0, -2.28, 1.87), (0.58, 0.58, 0.38), m["dark"]),
    ]
    for side in (-1, 1):
        body.append(cone("Crown horn", (side * 0.48, -1.69, 2.78), 0.22, 0.02, 0.92, m["edge"], (math.radians(-18), side * math.radians(12), 0)))
        for front, y in ((True, -0.76), (False, 0.92)):
            hip = (side * 0.78, y, 1.62)
            knee = (side * 1.10, y + (-0.26 if front else 0.28), 0.82)
            paw = (side * 1.05, y - (0.40 if front else -0.38), 0.18)
            body += [limb("Armoured upper leg", hip, knee, 0.24, m["plate"]), ico("Leg joint", knee, (0.31, 0.31, 0.31), m["edge"], 1), limb("Blade lower leg", knee, paw, 0.17, m["dark"]), base.box("Clawed paw", paw, (0.52, 0.72, 0.22), m["edge"], 0.06)]
        body.append(cone("Jaw fang", (side * 0.33, -2.60, 1.70), 0.11, 0.01, 0.48, m["bone"], (math.radians(90), 0, 0), 7))
    for index, y in enumerate((-0.30, 0.18, 0.66)):
        body.append(cone("Back crystal", (0, y, 2.62 + index * 0.06), 0.34, 0.02, 1.25, m["edge"], (0, math.radians(index * 8 - 8), 0), 7))
    body += [limb("Segmented tail", (0, 1.30, 1.70), (0, 2.45, 2.10), 0.22, m["dark"]), cone("Tail blade", (0, 2.78, 2.22), 0.34, 0.02, 1.10, m["edge"], (math.radians(72), 0, 0), 7)]
    eye_pair(energy, m["glow"], (0, -2.26, 2.22), 0.30)
    energy.append(ico("Shardhound chest core", (0, -1.02, 1.70), (0.42, 0.25, 0.46), m["hot"], 2))
    return body, energy, marker(m["dark"], 1.0)


def rapido():
    m, body, energy = mats("Rapido"), [], []
    body += [
        ico("Skyreaver body", (0, 0.10, 1.75), (0.72, 1.62, 0.58), m["dark"]),
        ico("Skyreaver head", (0, -1.48, 1.84), (0.58, 0.70, 0.47), m["plate"]),
        cone("Skyreaver beak", (0, -2.12, 1.75), 0.30, 0.01, 0.92, m["edge"], (math.radians(90), 0, 0), 7),
    ]
    for side in (-1, 1):
        wing = [(0.0, 0.20), (side * 1.05, -0.20), (side * 3.45, 0.20), (side * 2.35, 0.92), (side * 3.02, 1.28), (side * 0.88, 1.12)]
        wing_obj = base.extruded_polygon("Swept razor wing", wing, 0.20, m["plate"], z=1.72, bevel=0.07)
        wing_obj.rotation_euler[0] = math.radians(90)
        body.append(wing_obj)
        body += [limb("Wing spar", (side * 0.35, -0.10, 1.78), (side * 2.72, 0.42, 1.78), 0.12, m["edge"], 7), cone("Wingtip blade", (side * 3.34, 0.28, 1.75), 0.22, 0.01, 1.05, m["edge"], (0, side * math.radians(74), 0), 7)]
        body.append(limb("Predator talon", (side * 0.36, 0.52, 1.40), (side * 0.55, 0.02, 0.70), 0.13, m["dark"], 7))
        energy.append(limb("Wing plasma vein", (side * 0.34, -0.04, 1.91), (side * 2.62, 0.42, 1.91), 0.055, m["glow"], 7))
    body += [limb("Skyreaver tail", (0, 1.30, 1.68), (0, 2.62, 1.92), 0.17, m["dark"]), cone("Tail stinger", (0, 3.02, 1.98), 0.25, 0.01, 1.05, m["edge"], (math.radians(90), 0, 0), 7)]
    eye_pair(energy, m["glow"], (0, -1.92, 2.00), 0.25, (0.10, 0.07, 0.10))
    energy.append(ico("Skyreaver reactor", (0, -0.25, 1.76), (0.30, 0.52, 0.22), m["hot"], 2))
    return body, energy, marker(m["dark"], 1.25)


def gonfio():
    m, body, energy = mats("Gonfio"), [], []
    body += [
        ico("Bruteforge torso", (0, 0.05, 2.25), (1.62, 1.08, 1.55), m["dark"]),
        ico("Bruteforge belly armour", (0, -0.62, 1.94), (1.38, 0.48, 1.12), m["plate"]),
        ico("Bruteforge head", (0, -0.34, 3.65), (0.78, 0.64, 0.70), m["plate"]),
    ]
    for side in (-1, 1):
        shoulder = (side * 1.62, 0, 2.82)
        elbow = (side * 2.05, -0.16, 1.78)
        fist = (side * 2.08, -0.72, 0.74)
        body += [ico("Fortress shoulder", shoulder, (0.78, 0.82, 0.76), m["plate"], 2), limb("Brute upper arm", shoulder, elbow, 0.43, m["dark"]), limb("Brute forearm", elbow, fist, 0.53, m["plate"]), ico("Siege fist", fist, (0.72, 0.62, 0.68), m["edge"], 2)]
        hip = (side * 0.78, 0.34, 1.35)
        foot = (side * 0.86, -0.28, 0.18)
        body += [limb("Brute leg", hip, foot, 0.46, m["dark"]), base.box("Brute plated foot", (side * 0.86, -0.50, 0.18), (0.92, 1.20, 0.34), m["plate"], 0.09)]
        body.append(cone("Shoulder breaker", (side * 1.68, 0.02, 3.70), 0.36, 0.02, 1.18, m["edge"], (0, side * math.radians(10), 0), 8))
    for index, z in enumerate((1.54, 2.10, 2.66)):
        body.append(base.torus("Brute armour rib", (0, -0.96, z), 1.12 - index * 0.12, 0.10, m["edge"], rotation=(math.radians(90), 0, 0)))
    eye_pair(energy, m["glow"], (0, -0.91, 3.76), 0.28, (0.12, 0.07, 0.10))
    energy.append(ico("Bruteforge furnace", (0, -1.22, 2.18), (0.62, 0.25, 0.68), m["hot"], 2))
    for side in (-1, 1):
        energy.append(ico("Fist reactor", (side * 2.08, -1.25, 0.78), (0.24, 0.14, 0.24), m["glow"], 1))
    return body, energy, marker(m["dark"], 1.0)


def tessitore():
    m, body, energy = mats("Tessitore"), [], []
    body += [
        ico("Weaver abdomen", (0, 0.72, 1.35), (1.24, 1.42, 0.90), m["dark"]),
        ico("Weaver thorax", (0, -0.55, 1.42), (0.92, 0.86, 0.72), m["plate"]),
        ico("Weaver mask", (0, -1.26, 1.48), (0.64, 0.52, 0.54), m["edge"]),
    ]
    for side in (-1, 1):
        for index, y in enumerate((-0.62, -0.05, 0.55, 1.05)):
            hip = (side * 0.72, y, 1.36)
            knee = (side * (1.48 + index * 0.12), y - 0.18, 1.02 + (index % 2) * 0.18)
            foot = (side * (2.08 + index * 0.14), y - 0.48, 0.14)
            body += [limb("Weaver upper leg", hip, knee, 0.14, m["plate"], 7), ico("Weaver knee blade", knee, (0.23, 0.23, 0.23), m["edge"], 1), limb("Weaver lower leg", knee, foot, 0.105, m["dark"], 7), cone("Weaver foot claw", foot, 0.13, 0.01, 0.52, m["edge"], (math.radians(76), 0, side * math.radians(8)), 6)]
        body.append(cone("Weaver mandible", (side * 0.36, -1.78, 1.27), 0.15, 0.01, 0.74, m["edge"], (math.radians(82), side * math.radians(12), 0), 7))
    for x in (-0.34, -0.12, 0.12, 0.34):
        energy.append(ico("Weaver eye", (x, -1.73, 1.67 + abs(x) * 0.30), (0.075, 0.055, 0.075), m["glow"], 2))
    energy.append(ico("Weaver abdomen core", (0, 0.82, 2.04), (0.48, 0.66, 0.20), m["hot"], 2))
    for side in (-1, 1):
        energy.append(limb("Weaver venom channel", (side * 0.24, -0.42, 1.80), (side * 0.38, 0.76, 1.98), 0.055, m["glow"], 7))
    return body, energy, marker(m["dark"], 0.85)


def guscione():
    m, body, energy = mats("Guscione"), [], []
    body += [
        ico("Shellbreaker body", (0, 0.12, 1.28), (1.55, 2.02, 1.08), m["dark"]),
        ico("Shellbreaker crown shell", (0, 0.30, 1.78), (1.72, 1.82, 0.78), m["plate"]),
        ico("Shellbreaker head", (0, -1.62, 1.18), (0.92, 0.74, 0.65), m["plate"]),
    ]
    for side in (-1, 1):
        for index, y in enumerate((-0.88, 0.12, 1.08)):
            hip = (side * 1.08, y, 1.18)
            knee = (side * 1.72, y - 0.18, 0.72)
            foot = (side * 2.02, y - 0.55, 0.20)
            body += [limb("Beetle armoured leg", hip, knee, 0.26, m["plate"], 8), limb("Beetle hooked leg", knee, foot, 0.17, m["dark"], 7), cone("Beetle ground claw", foot, 0.18, 0.01, 0.62, m["edge"], (math.radians(76), 0, side * math.radians(8)), 7)]
        body.append(cone("Shellbreaker horn", (side * 0.42, -2.20, 1.28), 0.24, 0.02, 1.38, m["edge"], (math.radians(75), side * math.radians(11), 0), 8))
    for index, y in enumerate((-0.65, 0.12, 0.90, 1.55)):
        body.append(base.box("Carapace ridge", (0, y, 2.28 - abs(y) * 0.10), (2.72 - abs(y) * 0.24, 0.18, 0.20), m["edge"], 0.045))
    eye_pair(energy, m["glow"], (0, -2.18, 1.52), 0.34, (0.11, 0.07, 0.10))
    energy.append(ico("Shellbreaker hidden core", (0, -1.98, 1.05), (0.56, 0.22, 0.44), m["hot"], 2))
    for side in (-1, 1):
        energy.append(limb("Shell energy seam", (side * 0.38, -0.65, 2.34), (side * 0.78, 1.28, 2.16), 0.065, m["glow"], 7))
    return body, energy, marker(m["dark"], 0.85)


def monolite():
    m, body, energy = mats("Monolite"), [], []
    body += [
        base.box("Monolite broken torso", (0, 0.10, 4.65), (3.65, 2.25, 5.20), m["dark"], 0.22, (0, 0, math.radians(3))),
        base.box("Monolite chest citadel", (0, -1.08, 4.84), (3.12, 0.62, 3.20), m["plate"], 0.14),
        ico("Monolite crowned head", (0, -0.22, 7.65), (1.20, 1.06, 1.28), m["plate"], 2),
    ]
    for side in (-1, 1):
        shoulder = (side * 2.10, 0, 6.22)
        elbow = (side * 2.72, -0.10, 4.18)
        hand = (side * 2.48, -0.78, 2.18)
        body += [ico("Monolite fortress shoulder", shoulder, (1.25, 1.10, 1.05), m["plate"], 2), limb("Monolite upper arm", shoulder, elbow, 0.70, m["dark"], 8), limb("Monolite carved forearm", elbow, hand, 0.86, m["plate"], 8), ico("Monolite crushing hand", hand, (1.00, 0.82, 0.88), m["edge"], 2)]
        body.append(cone("Monolite shoulder spire", (side * 2.12, 0.06, 7.72), 0.55, 0.03, 2.45, m["edge"], (0, side * math.radians(8), 0), 8))
        hip = (side * 1.05, 0.30, 2.45)
        knee = (side * 1.20, -0.12, 1.18)
        foot = (side * 1.30, -0.82, 0.22)
        body += [limb("Monolite pillar thigh", hip, knee, 0.76, m["dark"], 8), limb("Monolite pillar shin", knee, foot, 0.68, m["plate"], 8), base.box("Monolite ruin foot", foot, (1.72, 1.85, 0.45), m["edge"], 0.12)]
        body.append(cone("Crown antler", (side * 0.68, -0.10, 9.08), 0.32, 0.02, 1.72, m["edge"], (0, side * math.radians(15), 0), 7))
    for index, z in enumerate((3.35, 4.20, 5.05, 5.90)):
        body.append(base.box("Monolite chest rib", (0, -1.46, z), (2.70 - index * 0.16, 0.24, 0.23), m["edge"], 0.045, (0, 0, math.radians(-4 + index * 3))))
    energy.append(ico("Monolite furnace heart", (0, -1.52, 4.74), (0.88, 0.26, 1.12), m["hot"], 2))
    eye_pair(energy, m["glow"], (0, -1.12, 7.88), 0.42, (0.15, 0.09, 0.12))
    for side in (-1, 1):
        energy.append(limb("Monolite arm fissure", (side * 2.08, -0.72, 5.72), (side * 2.58, -0.92, 3.05), 0.08, m["glow"], 7))
    return body, energy, marker(m["dark"], 1.25)


BUILDERS = {
    "Scheggino": scheggino,
    "Rapido": rapido,
    "Gonfio": gonfio,
    "Tessitore": tessitore,
    "Guscione": guscione,
    "Monolite": monolite,
}


def bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return (low + high) * 0.5, high - low


def render_preview(name, body, energy):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.filepath = str(OUTPUT / f"Prismora_{name}_V1.png")
    world = scene.world or bpy.data.worlds.new("Prismora enemy preview")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.003, 0.006, 0.014, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.22
    center, size = bounds((body, energy))
    longest = max(size.x, size.y, size.z)
    bpy.ops.object.camera_add(location=center + Vector((longest * 0.96, -longest * 1.42, longest * 0.66)))
    camera = bpy.context.object
    camera.data.lens = 58
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    for light_name, offset, power, color in (
        ("Enemy neutral key", (0.85, -0.60, 1.00), 1050, (0.78, 0.88, 1.0)),
        ("Enemy cyan rim", (-0.85, 0.35, 0.70), 620, (0.02, 0.85, 1.0)),
        ("Enemy hot fill", (0.10, -0.90, 0.18), 360, (1.0, 0.10, 0.26)),
    ):
        data = bpy.data.lights.new(light_name, "AREA")
        data.energy = power
        data.color = color
        data.shape = "DISK"
        data.size = longest * 0.42
        light = bpy.data.objects.new(light_name, data)
        bpy.context.collection.objects.link(light)
        light.location = center + Vector(offset) * longest
        light.rotation_euler = (center - light.location).to_track_quat("-Z", "Y").to_euler()
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)


def export_asset(name, objects):
    path = OUTPUT / f"Prismora_{name}_V1.fbx"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={"MESH"}, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="FACE", path_mode="COPY",
        embed_textures=True, bake_anim=False,
    )
    return path


def build_one(name, builder):
    base.clear_scene()
    body_parts, energy_parts, root = builder()
    body = base.join_named(body_parts, f"{name}_Body")
    energy = base.join_named(energy_parts, f"{name}_Energy")
    objects = (body, energy, root)
    triangles = base.triangle_count(objects)
    if triangles > 18000:
        raise RuntimeError(f"{name} exceeds mobile triangle budget: {triangles}")
    render_preview(name, body, energy)
    base.bake_color_texture(body, f"Prismora_{name}_V1_Body")
    base.bake_color_texture(energy, f"Prismora_{name}_V1_Energy", emissive=True)
    fbx = export_asset(name, objects)
    blend = OUTPUT / f"Prismora_{name}_V1.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    print(f"PRISMORA_ENEMY_READY name={name} triangles={triangles} fbx={fbx}")


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, builder in BUILDERS.items():
        build_one(name, builder)


if __name__ == "__main__":
    main()
