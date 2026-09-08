# Prismora Capital V2 — Unreal preview

This project is a visual validation scene for the Blender-authored Prismora capital modules. It is not the Roblox game project.

Open `PrismoraPreview.uproject`, then load `/Game/Prismora/Maps/CapitalPreview`. The scene includes the imported modular meshes, sky, sunlight, fog, and a `PrismoraCamera` actor aimed at the complete sector.

To rebuild the scene after exporting a new FBX, import `Content/Prismora/Source/Prismora_Capital_V2.fbx` into `/Game/Prismora/Capital`, then execute `setup_preview.py` with Unreal's Python plugin enabled.

Generated caches (`Binaries`, `DerivedDataCache`, `Intermediate`, and `Saved`) are intentionally excluded from Git.
