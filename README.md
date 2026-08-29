# Brainrot Heroes Raid Arena

Original Roblox social-lobby and raid prototype generated entirely from native parts and Luau.

## Preview

```sh
rojo build default.project.json -o BrainrotHeroesRaidArena.rbxlx
open BrainrotHeroesRaidArena.rbxlx
```

Press **Play** in Roblox Studio. Players now spawn in the bright **Vibe Loft**, a real pre-raid lobby with eight recognizable zones: Spawn Hall, Setup Pro, LED Dance Floor, Snack Wall, Cinema Pit, Pet Pad, Hidden Vault, and Sky Deck. Cyan floor markers and the world objective lead directly to the raid portal.

The portal connects the lobby to the complete repeating raid:

- Nova Shuttle lands during the 25-second countdown.
- Players receive three original collectible weapons: Nova Pulse, Prism Fang, and Starbreaker X.
- Prisma Rex becomes vulnerable for 100 seconds and launches shockwaves players must jump over.
- The boss health scales with the number of players, while remaining playable in a solo test.
- On victory, one random active participant receives the full Hero and everyone else receives fragments.
- On phones, a large pink **ATTACCA** button appears during the active raid; PC click and controller RT continue to work.

## Integration

Copy `ArenaBuilder.server.luau`, `RaidGameplay.server.luau`, and `VibeLoftBuilder.server.luau` into `ServerScriptService`, then copy `ArenaPresentation.client.luau` into `StarterPlayerScripts` of the target experience. Change `ORIGIN` in the arena builder and `LOFT_ORIGIN` in the loft builder before moving either space.
