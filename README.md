# Brainrot Heroes Raid Arena

Original Roblox raid-room prototype generated entirely from native parts and Luau.

## Preview

```sh
rojo build default.project.json -o BrainrotHeroesRaidArena.rbxlx
open BrainrotHeroesRaidArena.rbxlx
```

Press **Play** in Roblox Studio. The experience builds the arena and starts a complete repeating raid:

- Nova Shuttle lands during the 25-second countdown.
- Players receive three original collectible weapons: Nova Pulse, Prism Fang, and Starbreaker X.
- Prisma Rex becomes vulnerable for 100 seconds and launches shockwaves players must jump over.
- The boss health scales with the number of players, while remaining playable in a solo test.
- On victory, one random active participant receives the full Hero and everyone else receives fragments.

## Integration

Copy both `ArenaBuilder.server.luau` and `RaidGameplay.server.luau` into `ServerScriptService`, then copy `ArenaPresentation.client.luau` into `StarterPlayerScripts` of the target experience. Change `ORIGIN` near the top of the builder before moving the room to different coordinates.
