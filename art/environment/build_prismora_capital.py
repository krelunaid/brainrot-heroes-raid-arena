import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "output"
BLEND_PATH = OUTPUT / "Prismora_Capital_V1.blend"
FBX_PATH = OUTPUT / "Prismora_Capital_V1.fbx"
RENDER_PATH = OUTPUT / "Prismora_Capital_V1.png"


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.curves, bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, metallic=0.0, roughness=0.5, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def apply_material(obj, mat):
    obj.data.materials.append(mat)
    obj["prismora_material"] = mat.name


def bevel(obj, amount=0.35, segments=3):
    modifier = obj.modifiers.new("Architectural bevel", "BEVEL")
    modifier.width = amount
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def cube(name, location, scale, mat, bevel_amount=0.25, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel_amount:
        bevel(obj, bevel_amount, 3)
    apply_material(obj, mat)
    return obj


def cylinder(name, location, radius, depth, mat, vertices=24, bevel_amount=0.2):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    if bevel_amount:
        bevel(obj, bevel_amount, 3)
    apply_material(obj, mat)
    return obj


def cone(name, location, radius1, radius2, depth, mat, vertices=24):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    bevel(obj, 0.18, 3)
    apply_material(obj, mat)
    return obj


def sphere(name, location, radius, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(obj, 0.08, 2)
    apply_material(obj, mat)
    return obj


def curve_tube(name, points, radius, mat, cyclic=False):
    curve_data = bpy.data.curves.new(name, "CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 2
    curve_data.bevel_depth = radius
    curve_data.bevel_resolution = 3
    spline = curve_data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for spline_point, point in zip(spline.points, points):
        spline_point.co = (*point, 1.0)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(obj)
    apply_material(obj, mat)
    return obj


def crystal(name, location, size, mat, rotation=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=size * 0.45, radius2=size * 0.22, depth=size * 1.9, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler.z = rotation
    bevel(obj, size * 0.035, 2)
    apply_material(obj, mat)
    cone(name + "Tip", (location[0], location[1], location[2] + size * 1.18), size * 0.22, 0.0, size * 0.48, mat, 6)


def arch(name, center, width, height, depth, stone_mat, glow_mat):
    x, y, z = center
    pillar_height = height * 0.54
    for side in (-1, 1):
        cube(f"{name}_Pillar", (x + side * width * 0.5, y, z + pillar_height * 0.5), (3.8, depth, pillar_height), stone_mat, 0.45)
        cube(f"{name}_GoldInset", (x + side * width * 0.5, y - depth * 0.52, z + pillar_height * 0.52), (1.0, 0.65, pillar_height * 0.68), GOLD, 0.18)
    arc_points = []
    for i in range(25):
        angle = math.pi - (math.pi * i / 24)
        arc_points.append((x + math.cos(angle) * width * 0.5, y, z + pillar_height + math.sin(angle) * width * 0.5))
    curve_tube(name + "_Arch", arc_points, 2.0, stone_mat)
    glow_points = [(px, y - depth * 0.55, pz) for px, _, pz in arc_points]
    curve_tube(name + "_Glow", glow_points, 0.38, glow_mat)
    cube(name + "_PortalPlane", (x, y + 0.2, z + height * 0.47), (width * 0.72, 0.7, height * 0.66), glow_mat, 0.65)


def tree(name, location, scale=1.0):
    x, y, z = location
    cylinder(name + "_Trunk", (x, y, z + 4.4 * scale), 0.85 * scale, 8.8 * scale, WOOD, 12, 0.14)
    sphere(name + "_CanopyA", (x, y, z + 10.0 * scale), 4.6 * scale, LEAVES, (1.0, 0.85, 0.95))
    sphere(name + "_CanopyB", (x - 2.3 * scale, y, z + 8.8 * scale), 3.2 * scale, LEAVES, (1.0, 0.9, 1.0))
    sphere(name + "_CanopyC", (x + 2.1 * scale, y, z + 9.1 * scale), 3.4 * scale, LEAVES_DARK, (1.0, 0.9, 1.0))


def hero_statue(name, location, accent, yaw=0.0):
    x, y, z = location
    rotation = (0, 0, yaw)
    cylinder(name + "_Plinth", (x, y, z + 1.3), 4.6, 2.6, DARK_STONE, 8, 0.25)
    cube(name + "_Boots", (x, y, z + 4.0), (5.2, 3.0, 3.4), DARK_STONE, 0.4, rotation)
    cone(name + "_Body", (x, y, z + 9.2), 3.8, 2.6, 7.8, HERO_STONE, 8)
    sphere(name + "_Head", (x, y, z + 14.0), 2.2, HERO_STONE, (0.9, 0.9, 1.05))
    for side in (-1, 1):
        cube(name + "_Arm", (x + side * 3.8, y, z + 9.8), (2.1, 2.2, 7.6), HERO_STONE, 0.45, (0, side * 0.18, side * 0.22))
        crystal(name + "_Wing", (x + side * 5.2, y + 0.5, z + 12.0), 4.6, accent, side * 0.25)
    crystal(name + "_Crest", (x, y, z + 18.0), 3.3, accent)


def stairs(name, start, width, tread_depth, tread_height, count, mat):
    x, y, z = start
    for i in range(count):
        cube(f"{name}_{i:02d}", (x, y + i * tread_depth, z + i * tread_height), (width, tread_depth + 0.1, tread_height + 0.5), mat, 0.18)


def build_scene():
    # Main octagonal floating platform and layered rim.
    cylinder("Capital_Platform", (0, 0, -2.2), 70, 4.4, CREAM, 12, 0.45)
    cylinder("Capital_GoldRim", (0, 0, -4.8), 72, 2.1, GOLD, 12, 0.35)
    cone("Capital_Underside", (0, 0, -14.0), 69, 35, 18.0, ROCK, 12)
    cylinder("Capital_InnerTile", (0, 0, 0.25), 58, 0.65, TILE, 12, 0.15)

    # Radial paths are visibly separated from plazas.
    for angle in (0, math.pi * 0.5, math.pi, math.pi * 1.5):
        px, py = math.cos(angle) * 35, math.sin(angle) * 35
        cube("Capital_RadialWalk", (px, py, 1.0), (20, 60, 1.3), TILE, 0.35, (0, 0, angle))
        for side in (-1, 1):
            offset_x = math.cos(angle) * (-side * 10)
            offset_y = math.sin(angle) * (-side * 10)
            cube("Capital_PathRail", (px + offset_x, py + offset_y, 2.0), (1.1, 59, 2.8), GOLD, 0.25, (0, 0, angle))

    # Central awakening dais and the lighthouse/prism tower.
    cylinder("Awakening_DaisLow", (0, 0, 2.0), 22, 3.4, STONE, 16, 0.35)
    cylinder("Awakening_DaisGold", (0, 0, 4.0), 18.7, 0.8, GOLD, 16, 0.18)
    cylinder("Awakening_DaisTop", (0, 0, 5.0), 16.2, 1.5, TILE, 16, 0.22)
    for i in range(8):
        angle = i * math.tau / 8
        crystal("Dais_Crystal", (math.cos(angle) * 13.6, math.sin(angle) * 13.6, 7.5), 2.8, CYAN if i % 2 == 0 else MAGENTA, angle)

    cylinder("Faro_Base", (0, 0, 8.1), 9.0, 5.2, DARK_STONE, 12, 0.4)
    cone("Faro_Tower", (0, 0, 29.5), 7.0, 4.7, 39.0, CREAM, 16)
    for z in (14.5, 27.0, 40.0):
        cylinder("Faro_GoldBand", (0, 0, z), 6.5 - z * 0.035, 1.2, GOLD, 16, 0.15)
    for i in range(4):
        angle = i * math.tau / 4
        cube("Faro_CyanInset", (math.cos(angle) * 5.0, math.sin(angle) * 5.0, 28.0), (1.0, 1.3, 25.0), CYAN, 0.25, (0, 0, angle))
    cylinder("Faro_Crown", (0, 0, 50.0), 8.0, 3.0, GOLD, 12, 0.25)
    cylinder("Faro_Lantern", (0, 0, 54.0), 5.2, 5.0, GLASS, 12, 0.25)
    crystal("Faro_Prism", (0, 0, 61.0), 7.0, CYAN)

    # Hero galleries: architecture first, statues second.
    for side in (-1, 1):
        gx = side * 47
        cylinder("Gallery_Platform", (gx, 0, 11.0), 26, 4.0, STONE, 12, 0.3)
        cylinder("Gallery_GoldRim", (gx, 0, 13.1), 26.4, 0.8, GOLD, 12, 0.15)
        stairs("Gallery_Stairs", (gx, -30, 2.0), 18, 3.5, 1.15, 9, TILE)
        for col in (-18, -9, 0, 9, 18):
            cylinder("Gallery_Column", (gx + col, 8.5, 23.0), 1.25, 20.0, CREAM, 12, 0.2)
            cylinder("Gallery_ColumnGold", (gx + col, 8.5, 32.5), 1.65, 1.0, GOLD, 12, 0.12)
        cube("Gallery_Canopy", (gx, 8.5, 34.0), (49, 7, 3), STONE, 0.55)
        for index, xoff in enumerate((-14, 0, 14)):
            hero_statue(f"Hero_{side}_{index}", (gx + xoff, -2.5, 13.5), (CYAN, MAGENTA, GOLD)[index], side * 0.12)

    # Four portals, but the spawn-facing one is offset so the camera stays clear.
    arch("Portal_Sunreach", (0, 56, 1.5), 20, 27, 5.0, STONE, GOLD_GLOW)
    arch("Portal_MoonGarden", (56, 0, 1.5), 20, 27, 5.0, STONE, MAGENTA)
    arch("Portal_HeroArena", (-56, 0, 1.5), 20, 27, 5.0, STONE, PURPLE)
    arch("Portal_Skyport", (0, -61, 1.5), 20, 27, 5.0, STONE, CYAN)

    # Dense readable props: trees, market pavilions, crystals and shrine circles.
    for i, angle in enumerate((0.35, 0.85, 2.3, 2.8, 3.65, 4.15, 5.4, 5.85)):
        tree(f"Tree_{i}", (math.cos(angle) * 58, math.sin(angle) * 58, 2.0), 0.72 + 0.06 * (i % 3))
    for i, angle in enumerate((0.1, 0.55, 1.1, 1.8, 2.15, 2.65, 3.2, 3.9, 4.55, 5.0, 5.55, 6.0)):
        radius = 47 if i % 2 else 64
        crystal(f"World_Crystal_{i}", (math.cos(angle) * radius, math.sin(angle) * radius, 4.2), 3.3 + (i % 3), (CYAN, MAGENTA, GOLD_GLOW)[i % 3], angle)

    for side in (-1, 1):
        cube("Market_Base", (side * 27, -42, 4.0), (18, 12, 5.0), DARK_STONE, 0.65)
        cone("Market_Roof", (side * 27, -42, 12.0), 12.0, 3.0, 8.0, MAGENTA if side < 0 else CYAN, 8)
        for leg in (-1, 1):
            cylinder("Market_Column", (side * 27 + leg * 7.0, -42, 8.5), 0.65, 8.0, GOLD, 10, 0.1)


def join_by_material():
    # A few merged meshes keep Roblox mobile-friendly while retaining distinct
    # PBR/emissive materials that can be remapped to Roblox materials after upload.
    for mat in list(bpy.data.materials):
        objects = [obj for obj in bpy.context.scene.objects if obj.type in {"MESH", "CURVE"} and obj.data.materials and obj.data.materials[0] == mat]
        if not objects:
            continue
        for obj in objects:
            if obj.type == "CURVE":
                bpy.context.view_layer.objects.active = obj
                obj.select_set(True)
                bpy.ops.object.convert(target="MESH")
                obj.select_set(False)
        objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj.data.materials and obj.data.materials[0] == mat]
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        objects[0].name = "Empire_" + mat.name.replace(" ", "_")


def point_camera(camera, target):
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_scene():
    bpy.ops.object.camera_add(location=(0, -235, 132))
    camera = bpy.context.object
    camera.data.lens = 52
    point_camera(camera, (0, 0, 18))
    bpy.context.scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(-60, -85, 120))
    key = bpy.context.object
    key.data.energy = 1900
    key.data.shape = "DISK"
    key.data.size = 72
    key.data.color = (1.0, 0.84, 0.66)
    point_camera(key, (0, 0, 15))
    bpy.ops.object.light_add(type="AREA", location=(75, -20, 55))
    fill = bpy.context.object
    fill.data.energy = 1150
    fill.data.size = 55
    fill.data.color = (0.45, 0.85, 1.0)
    point_camera(fill, (0, 0, 18))
    bpy.ops.object.light_add(type="SUN", location=(0, -40, 140), rotation=(math.radians(28), math.radians(-18), math.radians(-28)))
    sun = bpy.context.object
    sun.data.energy = 3.2
    sun.data.angle = math.radians(18)
    sun.data.color = (1.0, 0.82, 0.62)
    world = bpy.context.scene.world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.18, 0.48, 0.86, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1440
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(RENDER_PATH)
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 1.15
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(camera, do_unlink=True)
    bpy.data.objects.remove(key, do_unlink=True)
    bpy.data.objects.remove(fill, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)


def export_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.fbx(
        filepath=str(FBX_PATH),
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        object_types={"MESH"},
        bake_space_transform=True,
        add_leaf_bones=False,
        path_mode="AUTO",
    )


OUTPUT.mkdir(parents=True, exist_ok=True)
reset_scene()

CREAM = material("CreamStone", (0.82, 0.75, 0.61), roughness=0.72)
TILE = material("WarmTile", (0.93, 0.82, 0.63), roughness=0.58)
STONE = material("PaleStone", (0.54, 0.59, 0.67), metallic=0.05, roughness=0.6)
DARK_STONE = material("DarkStone", (0.085, 0.12, 0.20), metallic=0.18, roughness=0.42)
ROCK = material("FloatingRock", (0.18, 0.14, 0.16), roughness=0.82)
GOLD = material("ImperialGold", (0.96, 0.56, 0.12), metallic=0.76, roughness=0.24)
HERO_STONE = material("HeroStone", (0.22, 0.27, 0.36), metallic=0.35, roughness=0.38)
WOOD = material("WarmWood", (0.30, 0.13, 0.07), roughness=0.65)
LEAVES = material("EmeraldLeaves", (0.08, 0.38, 0.20), roughness=0.58)
LEAVES_DARK = material("DeepLeaves", (0.025, 0.20, 0.16), roughness=0.62)
CYAN = material("CyanEnergy", (0.025, 0.58, 0.95), metallic=0.1, roughness=0.18, emission=(0.02, 0.7, 1.0), emission_strength=5.0)
MAGENTA = material("MagentaEnergy", (0.96, 0.07, 0.55), metallic=0.08, roughness=0.2, emission=(1.0, 0.02, 0.4), emission_strength=4.5)
PURPLE = material("PurpleEnergy", (0.48, 0.12, 0.95), metallic=0.08, roughness=0.2, emission=(0.46, 0.05, 1.0), emission_strength=4.5)
GOLD_GLOW = material("GoldEnergy", (1.0, 0.58, 0.04), metallic=0.12, roughness=0.18, emission=(1.0, 0.42, 0.02), emission_strength=4.5)
GLASS = material("PrismGlass", (0.06, 0.72, 0.95), metallic=0.05, roughness=0.08, emission=(0.04, 0.55, 1.0), emission_strength=2.8)

build_scene()
render_scene()
join_by_material()
export_scene()
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

triangles = sum(len(obj.data.loop_triangles) for obj in bpy.context.scene.objects if obj.type == "MESH")
print(f"PRISMORA_CAPITAL_READY triangles={triangles} blend={BLEND_PATH} fbx={FBX_PATH} render={RENDER_PATH}")
