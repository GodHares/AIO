--[[
Copyright (C) 2014-  Rochet2 <https://github.com/Rochet2>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

--[[
ShenLongTable - Server side
===========================

Companion server for the ShenLongTable client UI. Implements a "Mesa de
Invocacion del Dragon" boss summoning system with two phases:

  Phase 1 - Preparation:    The player must hand in 7 required items
                            (the seven dragon balls).
  Phase 2 - Post-Invocation: When the player clicks Invocar after every
                            ball is placed and a reward has been chosen
                            from each of the 5 reward groups, the boss
                            is spawned. When the boss dies the chosen
                            rewards are distributed to the player (and
                            party, if any).

Place this file together with Client.lua inside `lua_scripts/` so Eluna
loads them. The Client.lua file is automatically forwarded to the player
by AIO.

Tweak BOSS_ENTRY, ITEM_ENTRIES, REWARD_GROUPS and SPAWN_COORDS below to
fit your server. The reward group layout (5 groups of up to 4 items
each) matches the visual layout the client renders.
]]

local AIO = AIO or require("AIO")

-- ============================================================
-- CONFIGURATION
-- ============================================================

-- Creature template id of the boss to spawn.
local BOSS_ENTRY = 10000001

-- Gossip menu npc that opens the summoning table. Set to nil to skip
-- the gossip registration if you prefer to open the UI another way.
local GOSSIP_NPC_ENTRY = 5000010
local GOSSIP_MENU_ID   = 1

-- Where the boss is spawned in the world (used by player:SpawnCreature).
local SPAWN_COORDS = {
    x = 85.99674,
    y = 14.1999655,
    z = -144.70805,
    o = 1.4736214,
}

-- The 7 required items the player must own to summon (the seven
-- dragon balls). One of each is consumed on a successful summon.
local ITEM_ENTRIES = {36786, 30809, 34057, 33470, 22573, 22445, 14344}

-- Friendly star labels mirrored on the client when item names are not
-- available locally. The client builds the visual order from this
-- table directly so keep the order matching ITEM_ENTRIES.
local ITEM_NAMES = {
    [36786] = "7 Estrellas",
    [30809] = "6 Estrellas",
    [34057] = "5 Estrellas",
    [33470] = "4 Estrellas",
    [22573] = "3 Estrellas",
    [22445] = "2 Estrellas",
    [14344] = "1 Estrella",
}

-- 5 reward groups with up to 4 items each, matching the layout shown
-- in the client UI mockup.
local REWARD_GROUPS = {
    {
        name = "Armas de los Heroes",
        items = {
            {id = 46017, count = 1, name = "Espada Legendaria"},
            {id = 49623, count = 1, name = "Cetro Sagrado"},
            {id = 47524, count = 1, name = "Hombreras del Heroe"},
            {id = 51999, count = 1, name = "Mandoble Ardiente"},
        },
    },
    {
        name = "Joyas Runicas",
        items = {
            {id = 50734, count = 1, name = "Vara Rune-engraved"},
            {id = 50732, count = 1, name = "Talisman Antiguo"},
            {id = 40719, count = 1, name = "Anillo del Dragon"},
            {id = 50664, count = 1, name = "Sello del Inframundo"},
        },
    },
    {
        name = "Pociones Alquimicas",
        items = {
            {id = 33447, count = 5, name = "Pocion Carmesi"},
            {id = 28101, count = 5, name = "Elixir Azul"},
            {id = 22829, count = 5, name = "Pocion Esmeralda"},
            {id = 33935, count = 5, name = "Filtro Dorado"},
        },
    },
    {
        name = "Materiales Legendarios",
        items = {
            {id = 36918, count = 5, name = "Cristal Arcano"},
            {id = 49908, count = 3, name = "Esquirla Primordial"},
            {id = 36905, count = 5, name = "Cristal Topacio"},
            {id = 36907, count = 5, name = "Cristal Zafiro"},
        },
    },
    {
        name = "Miscelaneos de Poder",
        items = {
            {id = 33820, count = 1, name = "Estandarte de Guerra"},
            {id = 35513, count = 1, name = "Mascota Dragon"},
            {id = 32458, count = 1, name = "Cria Roja"},
            {id = 32841, count = 1, name = "Cria Azul"},
        },
    },
}

-- ============================================================
-- STATE
-- ============================================================

-- Whether a boss is currently alive. While true the UI shows the
-- "boss already summoned" panel instead of the full summoning table.
local bossIsSpawned       = false

-- Selected rewards keyed by groupIndex -> itemIndex for the player who
-- summoned the active boss. Cleared when the boss dies.
local activeRewards       = nil

-- Name of the player who summoned the active boss (for display only).
local activeSummonerName  = nil

-- ============================================================
-- HELPERS
-- ============================================================

local function PlayerHasAllItems(player)
    for i = 1, #ITEM_ENTRIES do
        if player:GetItemCount(ITEM_ENTRIES[i]) < 1 then
            return false
        end
    end
    return true
end

local function ConsumeRequiredItems(player)
    for i = 1, #ITEM_ENTRIES do
        player:RemoveItem(ITEM_ENTRIES[i], 1)
    end
end

local function GiveBackRequiredItems(player)
    for i = 1, #ITEM_ENTRIES do
        player:AddItem(ITEM_ENTRIES[i], 1)
    end
end

-- Build the payload sent to the client. We send only what the UI needs
-- to render: required items (id + name) and reward groups (name + list
-- of {id, count, name}).
local function BuildPayload()
    local required = {}
    for i = 1, #ITEM_ENTRIES do
        local id = ITEM_ENTRIES[i]
        required[i] = {id = id, name = ITEM_NAMES[id] or ("Item " .. id)}
    end

    local groups = {}
    for gi, group in ipairs(REWARD_GROUPS) do
        local items = {}
        for ii, item in ipairs(group.items) do
            items[ii] = {
                id    = item.id,
                count = item.count or 1,
                name  = item.name or ("Item " .. item.id),
            }
        end
        groups[gi] = {name = group.name, items = items}
    end

    return required, groups
end

local function CountSelections(selectedRewards)
    local n = 0
    if type(selectedRewards) == "table" then
        for _ in pairs(selectedRewards) do
            n = n + 1
        end
    end
    return n
end

local function ValidateSelections(selectedRewards)
    if type(selectedRewards) ~= "table" then return false end
    if CountSelections(selectedRewards) < #REWARD_GROUPS then
        return false
    end
    for gi, group in ipairs(REWARD_GROUPS) do
        local pick = selectedRewards[gi]
        if type(pick) ~= "number" then return false end
        if not group.items[pick] then return false end
    end
    return true
end

local function GiveRewards(target, selectedRewards)
    for gi, ii in pairs(selectedRewards) do
        local group = REWARD_GROUPS[gi]
        if group and group.items[ii] then
            local reward = group.items[ii]
            target:AddItem(reward.id, reward.count or 1)
        end
    end
end

-- ============================================================
-- HANDLERS
-- ============================================================

local handlers = AIO.AddHandlers("ShenLongTable", {})

-- Open the summoning table for the player. The client decides which
-- of its two layouts to display based on `bossSummoned`.
function handlers.OpenTable(player)
    local msg = AIO.Msg()

    if bossIsSpawned then
        msg:Add("ShenLongTable", "ShowBossSpawned", activeSummonerName or "Desconocido")
    else
        local required, groups = BuildPayload()
        msg:Add("ShenLongTable", "ShowSummonTable", required, groups)
    end

    msg:Send(player)
end

-- Player clicked Invocar with a full set of items and one reward
-- chosen per group. Validate, consume the required items and spawn
-- the boss.
function handlers.SubmitSummon(player, selectedRewards)
    if bossIsSpawned then
        player:SendBroadcastMessage("Ya hay un jefe activo.")
        return
    end

    if not ValidateSelections(selectedRewards) then
        player:SendBroadcastMessage("Debes seleccionar una recompensa de cada grupo.")
        return
    end

    if not PlayerHasAllItems(player) then
        player:SendBroadcastMessage("Te faltan esferas para invocar al dragon.")
        AIO.Handle(player, "ShenLongTable", "OpenTable")
        return
    end

    ConsumeRequiredItems(player)

    local boss = player:SpawnCreature(
        BOSS_ENTRY,
        SPAWN_COORDS.x, SPAWN_COORDS.y, SPAWN_COORDS.z, SPAWN_COORDS.o
    )

    if not boss then
        GiveBackRequiredItems(player)
        player:SendBroadcastMessage("Error al invocar al jefe. Items devueltos.")
        return
    end

    boss:SetCreatorGUID(player:GetGUID())
    bossIsSpawned      = true
    activeRewards      = selectedRewards
    activeSummonerName = player:GetName()

    player:SendBroadcastMessage("Has invocado al jefe. Matalo para recibir tus recompensas.")

    -- Refresh UI for the rest of the party so they see the
    -- "boss already summoned" panel.
    if player:IsInGroup() then
        local group = player:GetGroup()
        if group then
            local members = group:GetMembers()
            for _, member in ipairs(members) do
                if member and member ~= player then
                    AIO.Handle(member, "ShenLongTable", "OpenTable")
                end
            end
        end
    end
end

-- ============================================================
-- WORLD EVENTS
-- ============================================================

local function OnGossipHello(event, player, object)
    handlers.OpenTable(player)
    player:GossipComplete()
end

local function OnKillCreature(event, player, killed)
    if killed:GetEntry() ~= BOSS_ENTRY then
        return
    end

    if not activeRewards then
        player:SendBroadcastMessage("Error: no se encontraron recompensas seleccionadas.")
        return
    end

    local function distribute(target)
        GiveRewards(target, activeRewards)
        target:SendBroadcastMessage("Has recibido tu recompensa por derrotar al jefe.")
    end

    if player:IsInGroup() then
        local group = player:GetGroup()
        if group then
            local members = group:GetMembers()
            if #members > 10 then
                player:SendBroadcastMessage("El grupo es demasiado grande. Maximo 10 jugadores.")
            else
                for _, member in ipairs(members) do
                    if member and member:IsInMap(player) then
                        distribute(member)
                    end
                end
            end
        else
            distribute(player)
        end
    else
        distribute(player)
    end

    -- Reset state so the next group can summon the boss again.
    killed:DespawnOrUnsummon()
    bossIsSpawned      = false
    activeRewards      = nil
    activeSummonerName = nil
end

if GOSSIP_NPC_ENTRY then
    RegisterCreatureGossipEvent(GOSSIP_NPC_ENTRY, GOSSIP_MENU_ID, OnGossipHello)
end
RegisterPlayerEvent(7, OnKillCreature)
