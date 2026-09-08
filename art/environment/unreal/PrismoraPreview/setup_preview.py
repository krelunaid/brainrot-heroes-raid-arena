import math
import unreal


ASSET_ROOT = "/Game/Prismora/Capital"
MAP_PATH = "/Game/Prismora/Maps/CapitalPreview"


world = unreal.EditorLoadingAndSavingUtils.new_blank_map(False)

spawned = []
for asset_path in unreal.EditorAssetLibrary.list_assets(ASSET_ROOT, recursive=True, include_folder=False):
    asset = unreal.EditorAssetLibrary.load_asset(asset_path)
    if isinstance(asset, unreal.StaticMesh):
        actor = unreal.EditorLevelLibrary.spawn_actor_from_object(asset, unreal.Vector(0, 0, 0))
        actor.set_actor_label("Prismora_" + asset.get_name())
        spawned.append(actor)

sun = unreal.EditorLevelLibrary.spawn_actor_from_class(
    unreal.DirectionalLight, unreal.Vector(0, 0, 900), unreal.Rotator(-32, -28, 0)
)
sun.set_actor_label("Prismora_Sun")
sun_component = sun.get_component_by_class(unreal.DirectionalLightComponent)
sun_component.set_editor_property("intensity", 7.5)
sun_component.set_editor_property("light_color", unreal.Color(255, 219, 178, 255))

sky = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.SkyAtmosphere, unreal.Vector(0, 0, 0))
sky.set_actor_label("Prismora_Sky")

skylight = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.SkyLight, unreal.Vector(0, 0, 600))
skylight.set_actor_label("Prismora_Skylight")
sky_component = skylight.get_component_by_class(unreal.SkyLightComponent)
sky_component.set_editor_property("intensity", 1.35)

fog = unreal.EditorLevelLibrary.spawn_actor_from_class(
    unreal.ExponentialHeightFog, unreal.Vector(0, 0, -200)
)
fog.set_actor_label("Prismora_Atmosphere")

if spawned:
    bounds = [actor.get_actor_bounds(False) for actor in spawned]
    min_x = min(origin.x - extent.x for origin, extent in bounds)
    min_y = min(origin.y - extent.y for origin, extent in bounds)
    min_z = min(origin.z - extent.z for origin, extent in bounds)
    max_x = max(origin.x + extent.x for origin, extent in bounds)
    max_y = max(origin.y + extent.y for origin, extent in bounds)
    max_z = max(origin.z + extent.z for origin, extent in bounds)
    center = unreal.Vector((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5)
    radius = max(max_x - min_x, max_y - min_y, max_z - min_z)
    camera_location = center + unreal.Vector(radius * 0.72, -radius * 1.35, radius * 0.55)
    dx = center.x - camera_location.x
    dy = center.y - camera_location.y
    dz = center.z - camera_location.z
    camera_rotation = unreal.Rotator(
        math.degrees(math.atan2(dz, math.sqrt(dx * dx + dy * dy))),
        math.degrees(math.atan2(dy, dx)),
        0.0,
    )
    preview_camera = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.CineCameraActor, camera_location, camera_rotation
    )
    preview_camera.set_actor_label("PrismoraCamera")
    camera_component = preview_camera.get_cine_camera_component()
    camera_component.set_editor_property("current_focal_length", 32.0)
    unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).set_level_viewport_camera_info(
        camera_location, camera_rotation
    )
    unreal.log(
        "PRISMORA_BOUNDS center={} radius={} camera={}".format(center, radius, camera_location)
    )

unreal.EditorLoadingAndSavingUtils.save_map(world, MAP_PATH)
unreal.log("PRISMORA_UNREAL_PREVIEW_READY " + MAP_PATH)
