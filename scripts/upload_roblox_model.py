"""Upload one FBX as a Roblox Model through the installed Blender add-on.

Run with Blender, for example:
  blender --background --python scripts/upload_roblox_model.py -- model.fbx "Asset name"

The script reuses the OAuth session stored by the official Roblox Blender add-on.
It never prints or stores authentication tokens.
"""

from __future__ import annotations

import asyncio
import importlib
from pathlib import Path
import sys

import bpy


def arguments() -> tuple[Path, str]:
    try:
        separator = sys.argv.index("--")
        values = sys.argv[separator + 1 :]
    except ValueError as exc:
        raise SystemExit("Missing arguments after --") from exc

    if len(values) != 2:
        raise SystemExit("Expected: <fbx path> <asset name>")

    source = Path(values[0]).expanduser().resolve()
    if not source.is_file():
        raise SystemExit(f"FBX not found: {source}")
    return source, values[1]


async def upload(source: Path, asset_name: str) -> int:
    addon = importlib.import_module("roblox-blender-plugin")
    creator_details = importlib.import_module("roblox-blender-plugin.lib.creator_details")
    oauth_module = importlib.import_module("roblox-blender-plugin.lib.oauth2_client")

    rbx = bpy.context.window_manager.rbx
    if not rbx.has_called_load_creator:
        creator_details.load_creator_details(bpy.context.window_manager, bpy.context.preferences)

    oauth_client = oauth_module.RbxOAuth2Client(rbx)
    await oauth_client.refresh_login_if_needed()

    # Prefer the authorized user account. This avoids accidentally uploading to
    # a community selected in an older Blender session.
    creator_data = next((creator for creator in rbx.creators if creator.type == "USER"), None)
    if creator_data is None:
        raise RuntimeError("The Roblox OAuth session has no authorized user creator")

    assets_module = importlib.import_module("assets_upload_client")
    models_module = importlib.import_module("openapi_client.models")
    creator = models_module.RobloxOpenCloudAssetsV1Creator(user_id=int(creator_data.id))
    asset_type = models_module.RobloxOpenCloudAssetsV1AssetType.MODEL

    print(f"PRISMORA_UPLOAD_ACCOUNT {creator_data.name}")
    async with assets_module.AssetsUploadClient(
        creator=creator,
        oauth2_token=oauth_client.token_data["access_token"],
    ) as client:
        operation = await client.upload_asset_and_wait_for_done_async(
            asset_type=asset_type,
            asset_name=asset_name,
            asset_description="PRISMORA Hero Rush capital environment, Blender V3",
            file_path=str(source),
            upload_request_timeout_seconds=60,
            num_poll_status_tries=20,
            poll_status_request_timeout_seconds=10,
        )

    if getattr(operation, "error", None):
        raise RuntimeError(f"Roblox upload failed: {operation.error.message}")
    if not getattr(operation, "done", False) or not getattr(operation, "response", None):
        raise RuntimeError("Roblox upload did not finish before the timeout")

    asset_id = int(operation.response.asset_id)
    print(f"PRISMORA_ASSET_ID {asset_id}")
    return asset_id


if __name__ == "__main__":
    fbx_path, name = arguments()
    asyncio.run(upload(fbx_path, name))
