import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "output"
BLEND_PATH = OUTPUT / "Prismora_Raggialama_V2.blend"
FBX_PATH = OUTPUT / "Prismora_Raggialama_V2.fbx"
PREVIEW_PATH = OUTPUT / "Prismora_Raggialama_V2.png"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, metallic=0.0, roughness=0.45, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def extruded_polygon(name, points, depth, mat, z=0.0, bevel=0.08):
    count = len(points)
    half = depth * 0.5
    vertices = [(x, y, z - half) for x, y in points] + [(x, y, z + half) for x, y in points]
    faces = []
    faces.append(tuple(range(count - 1, -1, -1)))
    faces.append(tuple(range(count, count * 2)))
    for index in range(count):
        next_index = (index + 1) % count
        faces.append((index, next_index, count + next_index, count + index))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Forged bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
    return obj


def box(name, location, scale, mat, bevel=0.08, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Machined bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def cylinder(name, location, radius, depth, mat, vertices=16, rotation=(math.pi / 2, 0.0, 0.0), bevel=0.06):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Turned bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def torus(name, location, major_radius, minor_radius, mat, rotation=(math.pi / 2, 0.0, 0.0)):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_segments=20,
        minor_segments=8,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def mirror_points(points):
    return points + [(-x, y) for x, y in reversed(points[1:-1])]


def apply_modifiers(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        except RuntimeError:
            pass
    obj.select_set(False)


def join_named(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        apply_modifiers(obj)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    result = objects[0]
    result.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return result


def create_weapon():
    obsidian = material("Obsidian forged metal", (0.018, 0.026, 0.045), 0.92, 0.19)
    gunmetal = material("Layered gunmetal", (0.075, 0.10, 0.14), 0.88, 0.25)
    silver = material("Prismatic edge", (0.48, 0.62, 0.72), 0.95, 0.15)
    gold = material("Solar gold", (0.72, 0.36, 0.055), 0.86, 0.2)
    grip = material("Deep violet grip", (0.10, 0.025, 0.16), 0.18, 0.42)
    cyan = material("Prism cyan", (0.005, 0.24, 0.46), 0.25, 0.17, (0.01, 0.58, 1.0), 3.2)
    magenta = material("Prism magenta", (0.42, 0.008, 0.20), 0.2, 0.2, (1.0, 0.015, 0.34), 2.7)

    body = []
    glow = []

    # Broad, asymmetric fantasy silhouette with a readable tip and guarded base.
    outer_right = [
        (0.0, 0.35),
        (0.84, 0.72),
        (1.18, 1.18),
        (1.12, 1.72),
        (0.92, 2.28),
        (1.08, 3.10),
        (0.88, 4.05),
        (0.64, 4.88),
        (0.34, 5.62),
        (0.0, 6.46),
    ]
    blade = extruded_polygon("Blade outer edge", mirror_points(outer_right), 0.34, silver, z=0.0, bevel=0.07)
    body.append(blade)

    inner_right = [
        (0.0, 0.62),
        (0.62, 0.88),
        (0.88, 1.25),
        (0.80, 1.72),
        (0.63, 2.24),
        (0.78, 3.08),
        (0.61, 3.94),
        (0.43, 4.70),
        (0.21, 5.42),
        (0.0, 6.04),
    ]
    for z in (-0.24, 0.24):
        body.append(extruded_polygon("Obsidian blade plate", mirror_points(inner_right), 0.10, obsidian, z=z, bevel=0.045))

    # Metallic ribs make the blade read as engineered rather than a flat cutout.
    for side in (-1, 1):
        for index, y in enumerate((1.18, 2.08, 3.02, 3.98, 4.82)):
            angle = math.radians(side * (18 + index * 2))
            body.append(box(
                "Blade armour rib",
                (side * (0.28 + index * 0.025), y, side * 0.29),
                (0.16, 0.72, 0.12),
                gunmetal,
                0.045,
                (0.0, 0.0, angle),
            ))

    # Twin energy channels, visible from both sides in third-person view.
    channel_right = [(0.09, 1.0), (0.27, 1.18), (0.33, 4.70), (0.15, 5.15), (0.02, 4.55)]
    channel_left = [(-x, y) for x, y in channel_right]
    for z in (-0.33, 0.33):
        glow.append(extruded_polygon("Cyan blade channel", channel_right, 0.055, cyan, z=z, bevel=0.025))
        glow.append(extruded_polygon("Magenta blade channel", channel_left, 0.055, magenta, z=z, bevel=0.025))

    # Runes punctuate the channel without relying on a noisy texture.
    for index, y in enumerate((1.48, 2.24, 3.02, 3.80, 4.54)):
        rune_points = [(0.0, y + 0.18), (0.18, y), (0.0, y - 0.18), (-0.18, y)]
        rune_mat = cyan if index % 2 == 0 else magenta
        for z in (-0.36, 0.36):
            glow.append(extruded_polygon("Prism blade rune", rune_points, 0.045, rune_mat, z=z, bevel=0.02))

    # Guard: layered swept wings and a protected energy core.
    guard_right = [(0.0, 0.48), (0.72, 0.62), (1.66, 0.48), (2.15, 0.12), (1.68, 0.20), (1.16, -0.12), (0.50, 0.05)]
    guard_left = [(-x, y) for x, y in guard_right]
    body.append(extruded_polygon("Right solar guard", guard_right, 0.64, gunmetal, bevel=0.11))
    body.append(extruded_polygon("Left solar guard", guard_left, 0.64, gunmetal, bevel=0.11))
    guard_edge_right = [(0.58, 0.54), (1.65, 0.38), (2.02, 0.15), (1.62, 0.27), (1.12, 0.02)]
    body.append(extruded_polygon("Right gold guard edge", guard_edge_right, 0.72, gold, bevel=0.06))
    body.append(extruded_polygon("Left gold guard edge", [(-x, y) for x, y in guard_edge_right], 0.72, gold, bevel=0.06))
    glow.append(cylinder("Guard prism core", (0.0, 0.30, 0.0), 0.42, 0.76, cyan, vertices=20, rotation=(0.0, 0.0, 0.0), bevel=0.05))

    # Grip and pommel use enough real geometry to hold up in close screenshots.
    body.append(cylinder("Tang", (0.0, -1.12, 0.0), 0.27, 2.65, obsidian, vertices=16))
    body.append(cylinder("Grip", (0.0, -1.18, 0.0), 0.39, 1.72, grip, vertices=16))
    for index in range(7):
        body.append(torus("Grip wrap", (0.0, -0.55 - index * 0.22, 0.0), 0.40, 0.052, gold if index in (0, 6) else gunmetal))
    body.append(torus("Guard collar", (0.0, -0.22, 0.0), 0.48, 0.10, silver))
    body.append(torus("Pommel collar", (0.0, -2.08, 0.0), 0.46, 0.10, gold))
    pommel = [(0.0, -2.78), (0.48, -2.30), (0.33, -2.06), (0.0, -1.95), (-0.33, -2.06), (-0.48, -2.30)]
    body.append(extruded_polygon("Prism pommel", pommel, 0.62, gunmetal, bevel=0.10))
    for z in (-0.36, 0.36):
        glow.append(extruded_polygon("Pommel heart", [(0.0, -2.58), (0.20, -2.34), (0.0, -2.12), (-0.20, -2.34)], 0.05, magenta, z=z, bevel=0.025))

    # Small back spikes sharpen the silhouette while staying inside mobile budgets.
    for side in (-1, 1):
        for index, y in enumerate((1.52, 2.62, 3.72)):
            x = side * (0.88 - index * 0.10)
            spike = [(x, y - 0.18), (x + side * 0.52, y), (x, y + 0.18)]
            body.append(extruded_polygon("Blade silhouette spike", spike, 0.30, gunmetal, bevel=0.04))

    body_obj = join_named(body, "RaggialamaV2_Body")
    glow_obj = join_named(glow, "RaggialamaV2_Energy")
    return body_obj, glow_obj


def triangle_count(objects):
    total = 0
    for obj in objects:
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def bake_color_texture(obj, name, emissive=False):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.018)
    bpy.ops.object.mode_set(mode="OBJECT")

    image_path = OUTPUT / f"{name}_Color.png"
    image = bpy.data.images.new(f"{name}_Color", width=2048, height=2048, alpha=False)
    image.generated_color = (0.01, 0.015, 0.025, 1.0)
    for mat in list(obj.data.materials):
        if not mat or not mat.use_nodes:
            continue
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.name = f"{name}_BakeTarget"
        node.image = image
        mat.node_tree.nodes.active = node

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True
    scene.render.bake.margin = 16
    scene.render.bake.target = "IMAGE_TEXTURES"
    bpy.ops.object.bake(type="DIFFUSE")
    image.filepath_raw = str(image_path)
    image.file_format = "PNG"
    image.save()

    baked = bpy.data.materials.new(f"{name}_Baked")
    baked.use_nodes = True
    nodes = baked.node_tree.nodes
    links = baked.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.18 if emissive else 0.88
    bsdf.inputs["Roughness"].default_value = 0.2 if emissive else 0.24
    if emissive:
        links.new(texture.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 2.8

    obj.data.materials.clear()
    obj.data.materials.append(baked)
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    return image_path


def setup_render(objects):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.image_settings.color_mode = "RGBA"

    world = scene.world or bpy.data.worlds.new("Prismora preview world")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.004, 0.007, 0.018, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.15

    bpy.ops.object.camera_add(location=(11.2, -3.2, 12.4))
    camera = bpy.context.object
    camera.name = "Raggialama preview camera"
    camera.data.lens = 58
    target = Vector((0.0, 1.75, 0.0))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    for name, location, energy, color, size in (
        ("Cool key", (5.0, 0.5, 7.5), 1250, (0.30, 0.78, 1.0), 4.0),
        ("Warm rim", (-5.5, 3.0, 5.5), 1050, (1.0, 0.12, 0.42), 3.2),
        ("Gold fill", (0.0, -3.5, 3.0), 700, (1.0, 0.55, 0.14), 2.8),
    ):
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = energy
        light_data.color = color
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        bpy.context.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()

    for obj in objects:
        obj.rotation_euler[1] = math.radians(-8)
        obj.rotation_euler[2] = math.radians(-12)

    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)

    for obj in objects:
        obj.rotation_euler = (0.0, 0.0, 0.0)


def export_fbx(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.fbx(
        filepath=str(FBX_PATH),
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


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    clear_scene()
    body, energy = create_weapon()
    objects = (body, energy)
    triangles = triangle_count(objects)
    if triangles > 18000:
        raise RuntimeError(f"Weapon exceeds mobile triangle budget: {triangles}")
    setup_render(objects)
    body_texture = bake_color_texture(body, "Prismora_Raggialama_V2_Body")
    energy_texture = bake_color_texture(energy, "Prismora_Raggialama_V2_Energy", emissive=True)
    export_fbx(objects)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    print(f"PRISMORA_WEAPON_READY triangles={triangles} objects={len(objects)}")
    print(f"PRISMORA_WEAPON_BLEND={BLEND_PATH}")
    print(f"PRISMORA_WEAPON_FBX={FBX_PATH}")
    print(f"PRISMORA_WEAPON_PREVIEW={PREVIEW_PATH}")
    print(f"PRISMORA_WEAPON_TEXTURES={body_texture}|{energy_texture}")


if __name__ == "__main__":
    main()
