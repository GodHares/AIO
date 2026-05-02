# ShenLongTable - Mesa de Invocacion del Dragon

A two-phase boss summoning UI built on top of AIO.

The visual layout matches the reference mockup:

```
+------------------------------------------------------------+
|                Mesa de Invocacion del Dragon          [X]  |
+------------------------------------------------------------+
| Phase 1: Preparation                                       |
|              o   o   o                                     |
|            o  [Shield]  o                                  |
|              o       o                                     |
|            Preparacion: Reune las 7 Esferas                |
+-------------------------[ Invocar ]------------------------+
| Phase 2: Post-Invocation (Dragon Presence)                 |
|  +-------------+                       +-------------+     |
|  | Armas       |                       | Materiales  |     |
|  | [][][][]    |                       | [][][][]    |     |
|  +-------------+                       +-------------+     |
|  +-------------+ +-------------------+ +-------------+     |
|  | Joyas       | | Pociones          | | Miscelaneos |     |
|  | [][][][]    | | [][][][]          | | [][][][]    |     |
|  +-------------+ +-------------------+ +-------------+     |
+------------------------------------------------------------+
```

## Files

| File | Where it runs | Purpose |
|------|---------------|---------|
| `Server.lua` | Eluna server | Defines required items, reward groups, boss spawning, kill reward distribution. |
| `Client.lua` | WoW client (sent by AIO) | Renders the Mesa de Invocacion del Dragon UI. |

## Install

Copy both files into your `lua_scripts/` folder. AIO will automatically
forward `Client.lua` to connecting players.

The example registers a gossip hook for creature entry `5000010`,
gossip menu `1`, so attaching that gossip menu to a NPC opens the
table. Players can also type `/shenlong` once logged in to open it.

## Flow

1. The server sends `ShowSummonTable(required, groups)` with the 7
   required item descriptors and the 5 reward groups.
2. The client builds the two-phase frame:
   - Phase 1: 7 dragon ball slots in a circle around a central shield.
     Drag-and-drop, click, or use the `Posicionar` auto-fill button.
   - Phase 2: 5 reward group panels arranged in a 3x2 grid (top-left
     `Armas`, top-right `Materiales`, bottom-left `Joyas`,
     bottom-center `Pociones`, bottom-right `Miscelaneos`). Each
     panel shows up to 4 reward icons; the player picks one per group.
3. Clicking `Invocar` validates and sends
   `AIO.Handle("ShenLongTable", "SubmitSummon", selectedRewards)`.
4. The server consumes the 7 items, spawns the boss, and broadcasts.
5. When the boss dies the server distributes the picked rewards to
   the player (and in-map party members) and resets state.

## Tweak

Edit `Server.lua` to adjust:

- `BOSS_ENTRY` - creature template id of the boss to spawn.
- `GOSSIP_NPC_ENTRY` / `GOSSIP_MENU_ID` - which NPC opens the table.
- `SPAWN_COORDS` - where the boss appears.
- `ITEM_ENTRIES` / `ITEM_NAMES` - the seven required items.
- `REWARD_GROUPS` - the 5 reward groups (up to 4 items each).
