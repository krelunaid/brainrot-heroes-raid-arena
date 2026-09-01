import asyncio
import importlib
import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
FBX_PATH = ROOT / "output" / "Prismora_Raggialama_V2.fbx"
REPORT_PATH = ROOT / "output" / "Prismora_Raggialama_V2_upload.json"


async def upload_weapon():
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
    async with AssetsUploadClient(creator=creator, oauth2_token=oauth_client.token_data["access_token"]) as client:
        operation = await client.upload_asset_and_wait_for_done_async(
            asset_type=AssetType.MODEL,
            asset_name="Prismora Raggialama V2",
            asset_description="Original Prismora Hero Rush weapon, modelled and optimized for mobile",
            file_path=str(FBX_PATH),
            asset_id=94748150816254,
            upload_request_timeout_seconds=45,
            num_poll_status_tries=16,
            poll_status_request_timeout_seconds=8,
        )

    report = {
        "account": oauth_client.name,
        "creator_user_id": int(user_creator.id),
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

    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    creator_module.save_creator_details(bpy.context.window_manager, bpy.context.preferences)
    bpy.ops.wm.save_userpref()
    return report


try:
    result = asyncio.run(upload_weapon())
    print("PRISMORA_WEAPON_UPLOAD", json.dumps(result))
except Exception as exc:
    failure = {"ok": False, "fatal": f"{type(exc).__name__}: {exc}"}
    REPORT_PATH.write_text(json.dumps(failure, indent=2), encoding="utf-8")
    print("PRISMORA_WEAPON_UPLOAD_FATAL", json.dumps(failure))
    raise
