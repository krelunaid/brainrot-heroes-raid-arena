import asyncio
import importlib
import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "output"
REPORT_PATH = OUTPUT / "Prismora_Arsenal_V2_upload.json"
WEAPONS = ("Scintilla", "Pulsar", "Frantuma")
EXISTING_ASSET_IDS = {
    "Scintilla": 112976542024708,
    "Pulsar": 72359682918429,
    "Frantuma": 105007115249197,
}


async def upload_arsenal():
    oauth_module = importlib.import_module("roblox-blender-plugin.lib.oauth2_client")
    creator_module = importlib.import_module("roblox-blender-plugin.lib.creator_details")
    rbx = bpy.context.window_manager.rbx
    creator_module.load_creator_details(bpy.context.window_manager, bpy.context.preferences)
    oauth_client = oauth_module.RbxOAuth2Client(rbx)
    await oauth_client.refresh_login_if_needed()

    user_creator = next((creator for creator in rbx.creators if creator.type == "USER"), None)
    if not user_creator:
        raise RuntimeError("The saved Roblox OAuth session has no user creator")

    from assets_upload_client import AssetsUploadClient
    from openapi_client.models import (
        RobloxOpenCloudAssetsV1AssetType as AssetType,
        RobloxOpenCloudAssetsV1Creator as AssetsCreator,
    )

    creator = AssetsCreator(user_id=int(user_creator.id))
    reports = []
    async with AssetsUploadClient(creator=creator, oauth2_token=oauth_client.token_data["access_token"]) as client:
        for weapon_name in WEAPONS:
            fbx_path = OUTPUT / f"Prismora_{weapon_name}_V2.fbx"
            if not fbx_path.exists():
                raise FileNotFoundError(fbx_path)
            operation = await client.upload_asset_and_wait_for_done_async(
                asset_type=AssetType.MODEL,
                asset_name=f"Prismora {weapon_name} V3",
                asset_description="Original Prismora Hero Rush weapon, modelled in Blender and optimized for mobile",
                file_path=str(fbx_path),
                asset_id=EXISTING_ASSET_IDS[weapon_name],
                upload_request_timeout_seconds=45,
                num_poll_status_tries=16,
                poll_status_request_timeout_seconds=8,
            )
            report = {
                "name": weapon_name,
                "ok": bool(operation.done and operation.response and not operation.error),
            }
            if operation.error:
                report["error"] = operation.error.message
                report["error_code"] = operation.error.code
            elif operation.done and operation.response:
                report["asset_id"] = int(operation.response.asset_id)
                report["revision_id"] = int(operation.response.revision_id)
            else:
                report["error"] = "Upload did not finish before polling timed out"
            reports.append(report)
            print("PRISMORA_ARSENAL_UPLOAD_ITEM", json.dumps(report))

    result = {
        "account": oauth_client.name,
        "creator_user_id": int(user_creator.id),
        "ok": all(report["ok"] for report in reports),
        "weapons": reports,
    }
    REPORT_PATH.write_text(json.dumps(result, indent=2), encoding="utf-8")
    creator_module.save_creator_details(bpy.context.window_manager, bpy.context.preferences)
    bpy.ops.wm.save_userpref()
    return result


try:
    upload_result = asyncio.run(upload_arsenal())
    print("PRISMORA_ARSENAL_UPLOAD", json.dumps(upload_result))
except Exception as exc:
    failure = {"ok": False, "fatal": f"{type(exc).__name__}: {exc}"}
    REPORT_PATH.write_text(json.dumps(failure, indent=2), encoding="utf-8")
    print("PRISMORA_ARSENAL_UPLOAD_FATAL", json.dumps(failure))
    raise
