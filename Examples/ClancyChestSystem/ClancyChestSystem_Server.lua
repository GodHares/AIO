-- ClancyChestSystem_Server.lua
-- AzerothCore WotLK 3.3.5 + Eluna + Rochet2 AIO
-- Sistema de cofres temporales sin GameEvent.
--
-- Handler:
--   ClancyChestSystem
--
-- GameObjects:
--   910000 = Cofre configurador GM
--   910001 = Cofre activo/evento
--
-- Reglas:
--   - GM configura items, cantidad y chance.
--   - El evento se activa por tiempo.
--   - Cada cofre 910001 puede ser recogido una sola vez por activación.
--   - Si todos los cofres son recogidos, el evento finaliza automáticamente.
--   - Si no todos son recogidos, finaliza por tiempo.
--   - No usa game_event.
--   - No usa gameobject_loot_template.

local AIO = AIO or require("AIO")

local HANDLER = "ClancyChestSystem"
local ClancyChestSystem = AIO.AddHandlers(HANDLER, {})

math.randomseed(os.time())

local PAYLOAD_SEP = "<<CLANCYSEP>>"

local CONFIG = {
    DEBUG = true,

    EVENT_KEY = "main_clancy_chest_event",

    PREP_GO_ENTRY = 910000,
    ACTIVE_GO_ENTRY = 910001,

    MIN_GM_RANK = 3,

    DEFAULT_DURATION_MINUTES = 10,
    MIN_DURATION_SECONDS = 30,
    MAX_DURATION_SECONDS = 24 * 60 * 60,

    CLEAR_STOCK_ON_DEACTIVATE = false,
    ALLOW_EDIT_WHILE_ACTIVE = false,

    ANNOUNCE_TO_WORLD = true,
    ANNOUNCE_FOUND_CHESTS = true,

    -- Si quieres que el cofre desaparezca visualmente al ser recogido,
    -- ponlo en true. Si tu core tiene problemas con Despawn, déjalo false.
    DESPAWN_CHEST_ON_LOOT = false,
}

local GOSSIP_EVENT_ON_HELLO = 1

local State = {
    active = false,
    activationId = 0,
    endsAt = 0,
    items = {}
}

local UsedChests = {}
local stopEventId = nil

local Deactivate
local ScheduleStop
local CheckEventCompletion

local function D(message)
    if CONFIG.DEBUG then
        print("[ClancyChestSystem SERVER] " .. tostring(message))
    end
end

local function PName(player)
    if not player then
        return "nil-player"
    end

    local ok, name = pcall(function()
        return player:GetName()
    end)

    if ok and name then
        return tostring(name)
    end

    return "unknown-player"
end

local function PGuid(player)
    if not player then
        return 0
    end

    local ok, guid = pcall(function()
        return player:GetGUIDLow()
    end)

    if ok and guid then
        return tonumber(guid) or 0
    end

    return 0
end

local function GetGameObjectGuidLow(gameObject)
    if not gameObject then
        D("GetGameObjectGuidLow: gameObject nil.")
        return 0
    end

    local ok, guid = pcall(function()
        return gameObject:GetGUIDLow()
    end)

    if ok and guid then
        return tonumber(guid) or 0
    end

    D("GetGameObjectGuidLow: no se pudo obtener GUIDLow.")
    return 0
end

local function SqlString(value)
    return "'" .. tostring(value):gsub("\\", "\\\\"):gsub("'", "\\'") .. "'"
end

local function EventKeySql()
    return SqlString(CONFIG.EVENT_KEY)
end

local function ToUInt(value, default)
    local n = tonumber(value)

    if not n then
        return default or 0
    end

    n = math.floor(n)

    if n < 0 then
        return default or 0
    end

    return n
end

local function ClampChance(value)
    local chance = ToUInt(value, 100)

    if chance < 1 then
        chance = 1
    end

    if chance > 100 then
        chance = 100
    end

    return chance
end

------------------------------------------------------------
-- Tipos de premio (item / honor / arena / gold).
--
-- El stock se guarda en `custom_clancy_chest_stock` con el campo
-- `item_entry` (UNSIGNED INT). Para no requerir migración de schema,
-- los premios que no son items se almacenan con un id "mágico"
-- reservado fuera del rango de items reales:
--   honor -> 4000000001
--   arena -> 4000000002
--   gold  -> 4000000003
--
-- El campo `amount` significa:
--   item  -> stack del item
--   honor -> puntos de honor a entregar
--   arena -> puntos de arena a entregar
--   gold  -> oro entero (5 = 5g). Internamente se multiplica por
--            10000 para pasar a cobre con ModifyMoney.
------------------------------------------------------------

local REWARD_HONOR_ID = 4000000001
local REWARD_ARENA_ID = 4000000002
local REWARD_GOLD_ID  = 4000000003

local VALID_KINDS = {
    item  = true,
    honor = true,
    arena = true,
    gold  = true,
}

local function NormalizeKind(value)
    local kind = tostring(value or "item"):lower()

    if not VALID_KINDS[kind] then
        return "item"
    end

    return kind
end

local function GetRewardKind(entry)
    if entry == REWARD_HONOR_ID then return "honor" end
    if entry == REWARD_ARENA_ID then return "arena" end
    if entry == REWARD_GOLD_ID  then return "gold"  end
    return "item"
end

local function GetKindMagicId(kind)
    if kind == "honor" then return REWARD_HONOR_ID end
    if kind == "arena" then return REWARD_ARENA_ID end
    if kind == "gold"  then return REWARD_GOLD_ID  end
    return nil
end

local function SafeWorldMessage(message)
    D("WorldMessage: " .. tostring(message))

    if CONFIG.ANNOUNCE_TO_WORLD then
        SendWorldMessage(message)
    end
end

local function IsAdmin(player)
    if not player then
        return false
    end

    local okIsGM, isGM = pcall(function()
        return player:IsGM()
    end)

    D(
        "IsAdmin check player=" ..
        PName(player) ..
        " IsGM ok=" ..
        tostring(okIsGM) ..
        " value=" ..
        tostring(isGM)
    )

    if okIsGM and isGM then
        return true
    end

    local okRank, rank = pcall(function()
        return player:GetGMRank()
    end)

    D(
        "IsAdmin rank player=" ..
        PName(player) ..
        " ok=" ..
        tostring(okRank) ..
        " rank=" ..
        tostring(rank) ..
        " required=" ..
        tostring(CONFIG.MIN_GM_RANK)
    )

    return okRank and tonumber(rank) and tonumber(rank) >= CONFIG.MIN_GM_RANK
end

local function RequireAdmin(player)
    if IsAdmin(player) then
        return true
    end

    if player then
        player:SendBroadcastMessage("No tienes permisos para configurar este sistema.")
    end

    return false
end

local function SaveState()
    D(
        "SaveState active=" ..
        tostring(State.active) ..
        " activationId=" ..
        tostring(State.activationId) ..
        " endsAt=" ..
        tostring(State.endsAt)
    )

    WorldDBExecute(string.format(
        "REPLACE INTO `custom_clancy_chest_state` " ..
        "(`event_key`, `active`, `activation_id`, `ends_at`) " ..
        "VALUES (%s, %u, %u, %u)",
        EventKeySql(),
        State.active and 1 or 0,
        State.activationId,
        State.endsAt
    ))
end

local function ItemExists(itemEntry)
    local q = WorldDBQuery(
        "SELECT `entry` FROM `item_template` WHERE `entry` = " ..
        tostring(itemEntry) ..
        " LIMIT 1"
    )

    return q ~= nil
end

local function GetItemName(itemEntry)
    local q = WorldDBQuery(
        "SELECT `name` FROM `item_template` WHERE `entry` = " ..
        tostring(itemEntry) ..
        " LIMIT 1"
    )

    if q then
        return q:GetString(0)
    end

    return "Item " .. tostring(itemEntry)
end

local function GetRewardName(entry)
    local kind = GetRewardKind(entry)
    if kind == "honor" then return "Puntos de honor" end
    if kind == "arena" then return "Puntos de arena" end
    if kind == "gold"  then return "Oro"             end
    return GetItemName(entry)
end

local function PersistStockItem(itemEntry)
    local data = State.items[itemEntry]
    local amount = 0
    local chance = 100

    if data then
        amount = ToUInt(data.amount, 0)
        chance = ClampChance(data.chance)
    end

    D(
        "PersistStockItem itemEntry=" ..
        tostring(itemEntry) ..
        " amount=" ..
        tostring(amount) ..
        " chance=" ..
        tostring(chance)
    )

    if amount > 0 then
        WorldDBExecute(string.format(
            "REPLACE INTO `custom_clancy_chest_stock` " ..
            "(`event_key`, `item_entry`, `amount`, `chance_pct`) " ..
            "VALUES (%s, %u, %u, %u)",
            EventKeySql(),
            itemEntry,
            amount,
            chance
        ))
    else
        WorldDBExecute(string.format(
            "DELETE FROM `custom_clancy_chest_stock` " ..
            "WHERE `event_key` = %s AND `item_entry` = %u",
            EventKeySql(),
            itemEntry
        ))
    end
end

local function ClearStock()
    D("ClearStock llamado.")

    State.items = {}

    WorldDBExecute(string.format(
        "DELETE FROM `custom_clancy_chest_stock` WHERE `event_key` = %s",
        EventKeySql()
    ))
end

local function LoadUsedChests()
    UsedChests = {}

    if not State.active then
        D("LoadUsedChests: evento inactivo.")
        return
    end

    local q = WorldDBQuery(string.format(
        "SELECT `gameobject_guid` FROM `custom_clancy_chest_loot` " ..
        "WHERE `event_key` = %s AND `activation_id` = %u",
        EventKeySql(),
        State.activationId
    ))

    if q then
        repeat
            local goGuid = q:GetUInt32(0)

            if goGuid > 0 then
                UsedChests[goGuid] = true
                D("LoadUsedChests cargado goGuid=" .. tostring(goGuid))
            end
        until not q:NextRow()
    end
end

local function LoadState()
    D("LoadState iniciado.")

    State.items = {}

    local stockQ = WorldDBQuery(string.format(
        "SELECT `item_entry`, `amount`, `chance_pct` " ..
        "FROM `custom_clancy_chest_stock` " ..
        "WHERE `event_key` = %s",
        EventKeySql()
    ))

    if stockQ then
        repeat
            local itemEntry = stockQ:GetUInt32(0)
            local amount = stockQ:GetUInt32(1)
            local chance = ClampChance(stockQ:GetUInt32(2))

            if itemEntry > 0 and amount > 0 then
                State.items[itemEntry] = {
                    amount = amount,
                    chance = chance
                }

                D(
                    "LoadState stock itemEntry=" ..
                    tostring(itemEntry) ..
                    " amount=" ..
                    tostring(amount) ..
                    " chance=" ..
                    tostring(chance)
                )
            end
        until not stockQ:NextRow()
    end

    local stateQ = WorldDBQuery(string.format(
        "SELECT `active`, `activation_id`, `ends_at` " ..
        "FROM `custom_clancy_chest_state` " ..
        "WHERE `event_key` = %s LIMIT 1",
        EventKeySql()
    ))

    if stateQ then
        State.active = stateQ:GetUInt32(0) == 1
        State.activationId = stateQ:GetUInt32(1)
        State.endsAt = stateQ:GetUInt32(2)

        D(
            "LoadState state active=" ..
            tostring(State.active) ..
            " activationId=" ..
            tostring(State.activationId) ..
            " endsAt=" ..
            tostring(State.endsAt)
        )
    else
        State.active = false
        State.activationId = 0
        State.endsAt = 0
        SaveState()
    end

    if State.active and State.endsAt <= os.time() then
        D("LoadState: evento activo expirado. Desactivando estado.")

        State.active = false
        State.endsAt = 0
        SaveState()
    end

    LoadUsedChests()

    D("LoadState terminado.")
end

local function IsStockEmpty()
    for entry, data in pairs(State.items) do
        local amount = ToUInt(data.amount, 0)
        local chance = ClampChance(data.chance)

        D(
            "IsStockEmpty check entry=" ..
            tostring(entry) ..
            " amount=" ..
            tostring(amount) ..
            " chance=" ..
            tostring(chance)
        )

        if amount > 0 and chance > 0 then
            return false
        end
    end

    return true
end

local function GetSortedStock()
    local list = {}

    for entry, data in pairs(State.items) do
        local amount = ToUInt(data.amount, 0)
        local chance = ClampChance(data.chance)

        if amount > 0 then
            table.insert(list, {
                entry  = entry,
                kind   = GetRewardKind(entry),
                amount = amount,
                chance = chance,
                name   = GetRewardName(entry)
            })
        end
    end

    table.sort(list, function(a, b)
        return a.entry < b.entry
    end)

    return list
end

local function CountAvailableChests()
    local q = WorldDBQuery(
        "SELECT COUNT(*) FROM `gameobject` WHERE `id` = " ..
        tostring(CONFIG.ACTIVE_GO_ENTRY)
    )

    if q then
        local count = q:GetUInt32(0)
        D("CountAvailableChests total=" .. tostring(count))
        return count
    end

    D("CountAvailableChests total=0")
    return 0
end

local function CountMemoryUsedChests()
    local count = 0

    for _, used in pairs(UsedChests) do
        if used then
            count = count + 1
        end
    end

    return count
end

local function CountLootedChests()
    local dbCount = 0

    local q = WorldDBQuery(string.format(
        "SELECT COUNT(DISTINCT `gameobject_guid`) FROM `custom_clancy_chest_loot` " ..
        "WHERE `event_key` = %s AND `activation_id` = %u",
        EventKeySql(),
        State.activationId
    ))

    if q then
        dbCount = q:GetUInt32(0)
    end

    local memoryCount = CountMemoryUsedChests()
    local finalCount = math.max(dbCount, memoryCount)

    D(
        "CountLootedChests dbCount=" ..
        tostring(dbCount) ..
        " memoryCount=" ..
        tostring(memoryCount) ..
        " using=" ..
        tostring(finalCount)
    )

    return finalCount
end

local function BuildSnapshotPayload()
    local now = os.time()
    local remaining = 0

    if State.active and State.endsAt > now then
        remaining = State.endsAt - now
    end

    local stock = GetSortedStock()
    local totalChests = CountAvailableChests()
    local lootedChests = CountLootedChests()

    local lines = {}

    for _, item in ipairs(stock) do
        -- Formato nuevo: entry|kind|amount|chance|name
        -- El cliente acepta también el formato antiguo
        -- "<entry> x<amount> [<chance>%] - <name>" para compatibilidad,
        -- pero ya no lo emitimos.
        table.insert(
            lines,
            tostring(item.entry)         .. "|" ..
            tostring(item.kind or "item") .. "|" ..
            tostring(item.amount)        .. "|" ..
            tostring(item.chance or 100) .. "|" ..
            tostring(item.name or "")
        )
    end

    local itemsText = table.concat(lines, "\n")

    local payload = table.concat({
        tostring(State.active and 1 or 0),
        tostring(State.activationId),
        tostring(remaining),
        tostring(totalChests),
        tostring(lootedChests),
        itemsText
    }, PAYLOAD_SEP)

    D(
        "BuildSnapshotPayload SEND active=" ..
        tostring(State.active and 1 or 0) ..
        " activationId=" ..
        tostring(State.activationId) ..
        " remaining=" ..
        tostring(remaining) ..
        " totalChests=" ..
        tostring(totalChests) ..
        " lootedChests=" ..
        tostring(lootedChests)
    )

    return payload
end

local function SendAdminWindow(player)
    D("SendAdminWindow PAYLOAD hacia " .. PName(player))
    AIO.Handle(player, HANDLER, "OpenAdminPayload", BuildSnapshotPayload())
end

local function RefreshAdminWindow(player)
    D("RefreshAdminWindow PAYLOAD hacia " .. PName(player))
    AIO.Handle(player, HANDLER, "OpenAdminPayload", BuildSnapshotPayload())
end

local function CancelStopTimer()
    if stopEventId then
        D("CancelStopTimer id=" .. tostring(stopEventId))
        RemoveEventById(stopEventId)
        stopEventId = nil
    end
end

Deactivate = function(player, reason)
    D(
        "Deactivate llamado reason=" ..
        tostring(reason) ..
        " active=" ..
        tostring(State.active)
    )

    if not State.active then
        if player then
            player:SendBroadcastMessage("El evento ya está desactivado.")
            RefreshAdminWindow(player)
        end

        return
    end

    State.active = false
    State.endsAt = 0

    SaveState()
    CancelStopTimer()

    -- No borramos la tabla de loot actual aquí, para que el conteo histórico quede visible.
    -- Se limpia en activaciones futuras según retención.
    UsedChests = {}

    if CONFIG.CLEAR_STOCK_ON_DEACTIVATE then
        ClearStock()
    end

    SafeWorldMessage("|cff00ccff[Clancy Chest]|r El evento de cofres se ha desactivado.")

    if player then
        player:SendBroadcastMessage("Evento de cofres desactivado.")
        RefreshAdminWindow(player)
    end
end

ScheduleStop = function()
    CancelStopTimer()

    if not State.active then
        return
    end

    local remaining = State.endsAt - os.time()

    D("ScheduleStop remaining=" .. tostring(remaining))

    if remaining <= 0 then
        Deactivate(nil, "expired")
        return
    end

    stopEventId = CreateLuaEvent(function()
        Deactivate(nil, "expired")
    end, remaining * 1000, 1)

    D("ScheduleStop creado id=" .. tostring(stopEventId))
end

CheckEventCompletion = function(player)
    if not State.active then
        D("CheckEventCompletion cancelado: evento inactivo.")
        return
    end

    local totalChests = CountAvailableChests()
    local lootedChests = CountLootedChests()

    D(
        "CheckEventCompletion totalChests=" ..
        tostring(totalChests) ..
        " lootedChests=" ..
        tostring(lootedChests) ..
        " activationId=" ..
        tostring(State.activationId)
    )

    if totalChests <= 0 then
        D("CheckEventCompletion cancelado: totalChests <= 0.")
        return
    end

    if lootedChests >= totalChests then
        SafeWorldMessage("|cff00ccff[Clancy Chest]|r Todos los cofres han sido encontrados. El evento ha finalizado.")
        Deactivate(nil, "all_chests_looted")
        return
    end

    local remaining = totalChests - lootedChests

    if CONFIG.ANNOUNCE_FOUND_CHESTS then
        SafeWorldMessage(
            "|cff00ccff[Clancy Chest]|r Cofre encontrado por " ..
            PName(player) ..
            ". Quedan " ..
            tostring(remaining) ..
            " cofres por encontrar."
        )
    end
end

local function Activate(player, durationMinutes)
    D("Activate llamado por=" .. PName(player) .. " durationRaw=" .. tostring(durationMinutes))

    if not RequireAdmin(player) then
        return
    end

    if State.active then
        player:SendBroadcastMessage("El evento ya está activo.")
        RefreshAdminWindow(player)
        return
    end

    if IsStockEmpty() then
        player:SendBroadcastMessage("No puedes activar el evento sin items configurados.")
        RefreshAdminWindow(player)
        return
    end

    local totalChests = CountAvailableChests()

    if totalChests <= 0 then
        player:SendBroadcastMessage("No hay cofres 910001 spawneados en el mundo.")
        RefreshAdminWindow(player)
        return
    end

    durationMinutes = ToUInt(durationMinutes, CONFIG.DEFAULT_DURATION_MINUTES)

    if durationMinutes <= 0 then
        durationMinutes = CONFIG.DEFAULT_DURATION_MINUTES
    end

    local durationSeconds = durationMinutes * 60

    if durationSeconds < CONFIG.MIN_DURATION_SECONDS then
        durationSeconds = CONFIG.MIN_DURATION_SECONDS
    end

    if durationSeconds > CONFIG.MAX_DURATION_SECONDS then
        durationSeconds = CONFIG.MAX_DURATION_SECONDS
    end

    State.activationId = State.activationId + 1
    State.active = true
    State.endsAt = os.time() + durationSeconds

    UsedChests = {}

    SaveState()

    WorldDBExecute(string.format(
        "DELETE FROM `custom_clancy_chest_loot` " ..
        "WHERE `event_key` = %s AND `activation_id` < %u",
        EventKeySql(),
        math.max(0, State.activationId - 20)
    ))

    ScheduleStop()

    SafeWorldMessage(
        "|cff00ccff[Clancy Chest]|r Un evento de cofres ha sido activado por " ..
        tostring(math.floor(durationSeconds / 60)) ..
        " minutos. Hay " ..
        tostring(totalChests) ..
        " cofres por encontrar."
    )

    player:SendBroadcastMessage("Evento activado.")
    RefreshAdminWindow(player)
end

local function HasLooted(player, gameObject)
    local goGuid = GetGameObjectGuidLow(gameObject)

    D(
        "HasLooted check player=" ..
        PName(player) ..
        " goGuid=" ..
        tostring(goGuid) ..
        " activationId=" ..
        tostring(State.activationId)
    )

    if goGuid <= 0 then
        D("HasLooted: goGuid inválido. Bloqueando.")
        return true
    end

    if UsedChests[goGuid] then
        D("HasLooted result=true memoria goGuid=" .. tostring(goGuid))
        return true
    end

    local q = WorldDBQuery(string.format(
        "SELECT `player_guid` FROM `custom_clancy_chest_loot` " ..
        "WHERE `event_key` = %s " ..
        "AND `activation_id` = %u " ..
        "AND `gameobject_guid` = %u LIMIT 1",
        EventKeySql(),
        State.activationId,
        goGuid
    ))

    if q then
        UsedChests[goGuid] = true
        D("HasLooted result=true DB goGuid=" .. tostring(goGuid))
        return true
    end

    D("HasLooted result=false goGuid=" .. tostring(goGuid))
    return false
end

local function MarkLooted(player, gameObject)
    local playerGuid = PGuid(player)
    local goGuid = GetGameObjectGuidLow(gameObject)

    D(
        "MarkLooted player=" ..
        PName(player) ..
        " playerGuid=" ..
        tostring(playerGuid) ..
        " goGuid=" ..
        tostring(goGuid) ..
        " activationId=" ..
        tostring(State.activationId)
    )

    if goGuid <= 0 then
        D("MarkLooted cancelado: goGuid inválido.")
        return false
    end

    UsedChests[goGuid] = true

    WorldDBExecute(string.format(
        "REPLACE INTO `custom_clancy_chest_loot` " ..
        "(`event_key`, `activation_id`, `gameobject_guid`, `player_guid`, `looted_at`) " ..
        "VALUES (%s, %u, %u, %u, %u)",
        EventKeySql(),
        State.activationId,
        goGuid,
        playerGuid,
        os.time()
    ))

    return true
end

local function UnmarkLooted(gameObject)
    local goGuid = GetGameObjectGuidLow(gameObject)

    if goGuid <= 0 then
        return
    end

    D("UnmarkLooted goGuid=" .. tostring(goGuid))

    UsedChests[goGuid] = nil

    WorldDBExecute(string.format(
        "DELETE FROM `custom_clancy_chest_loot` " ..
        "WHERE `event_key` = %s " ..
        "AND `activation_id` = %u " ..
        "AND `gameobject_guid` = %u",
        EventKeySql(),
        State.activationId,
        goGuid
    ))
end

local function TryDespawnChest(gameObject)
    if not CONFIG.DESPAWN_CHEST_ON_LOOT then
        return
    end

    if not gameObject then
        return
    end

    local ok, err = pcall(function()
        gameObject:Despawn()
    end)

    if not ok then
        D("TryDespawnChest error=" .. tostring(err))
    end
end

-- Devuelve los premios entregados al estado anterior cuando uno de los
-- AddItem falla por inventario lleno. Soporta los 4 tipos de premio.
local function RollbackGranted(player, granted)
    for i = #granted, 1, -1 do
        local g = granted[i]

        if g.kind == "item" then
            player:RemoveItem(g.entry, g.amount)
        elseif g.kind == "honor" then
            player:ModifyHonorPoints(-g.amount)
        elseif g.kind == "arena" then
            player:ModifyArenaPoints(-g.amount)
        elseif g.kind == "gold" then
            player:ModifyMoney(-(g.amount * 10000))
        end
    end
end

local function GrantStockToPlayer(player)
    local stock = GetSortedStock()
    local granted = {}
    local wonAnyItem = false

    for _, item in ipairs(stock) do
        local kind = item.kind or "item"
        local chance = ClampChance(item.chance)
        local roll = math.random(1, 100)

        D(
            "Loot roll entry=" ..
            tostring(item.entry) ..
            " kind=" ..
            tostring(kind) ..
            " amount=" ..
            tostring(item.amount) ..
            " chance=" ..
            tostring(chance) ..
            " roll=" ..
            tostring(roll)
        )

        if roll <= chance then
            if kind == "honor" then
                player:ModifyHonorPoints(item.amount)
                table.insert(granted, {
                    kind = "honor",
                    entry = item.entry,
                    amount = item.amount
                })
                wonAnyItem = true
            elseif kind == "arena" then
                player:ModifyArenaPoints(item.amount)
                table.insert(granted, {
                    kind = "arena",
                    entry = item.entry,
                    amount = item.amount
                })
                wonAnyItem = true
            elseif kind == "gold" then
                player:ModifyMoney(item.amount * 10000)
                table.insert(granted, {
                    kind = "gold",
                    entry = item.entry,
                    amount = item.amount
                })
                wonAnyItem = true
            else
                local beforeCount = player:GetItemCount(item.entry)
                local addedItem = player:AddItem(item.entry, item.amount)
                local afterCount = player:GetItemCount(item.entry)
                local delta = afterCount - beforeCount

                D(
                    "AddItem result item=" ..
                    tostring(item.entry) ..
                    " before=" ..
                    tostring(beforeCount) ..
                    " after=" ..
                    tostring(afterCount) ..
                    " delta=" ..
                    tostring(delta) ..
                    " addedItem=" ..
                    tostring(addedItem)
                )

                if delta > 0 then
                    table.insert(granted, {
                        kind = "item",
                        entry = item.entry,
                        amount = delta
                    })

                    wonAnyItem = true
                end

                if not addedItem or delta < item.amount then
                    RollbackGranted(player, granted)

                    return false, "No tienes suficiente espacio o no puedes recibir uno de los items del cofre."
                end
            end
        end
    end

    if not wonAnyItem then
        return true, "No encontraste ningún objeto dentro del cofre."
    end

    return true, nil
end

local function OnPrepChestHello(event, player, gameObject)
    D("OnPrepChestHello player=" .. PName(player))

    if not RequireAdmin(player) then
        return false
    end

    SendAdminWindow(player)
    return false
end

local function OnActiveChestHello(event, player, gameObject)
    D("OnActiveChestHello player=" .. PName(player))

    local goGuid = GetGameObjectGuidLow(gameObject)

    D("OnActiveChestHello goGuid=" .. tostring(goGuid))

    if goGuid <= 0 then
        player:SendBroadcastMessage("Este cofre no tiene GUID válido. Contacta a un GM.")
        return false
    end

    if not State.active or State.endsAt <= os.time() then
        if State.active and State.endsAt <= os.time() then
            Deactivate(nil, "expired_on_click")
        end

        player:SendBroadcastMessage("Este cofre está desactivado.")
        return false
    end

    if IsStockEmpty() then
        player:SendBroadcastMessage("El cofre no tiene items configurados.")
        return false
    end

    if HasLooted(player, gameObject) then
        player:SendBroadcastMessage("Este cofre ya fue recogido por otro jugador.")
        return false
    end

    local marked = MarkLooted(player, gameObject)

    if not marked then
        player:SendBroadcastMessage("No se pudo marcar este cofre como recogido.")
        return false
    end

    local ok, resultMessage = GrantStockToPlayer(player)

    if not ok then
        UnmarkLooted(gameObject)
        player:SendBroadcastMessage(resultMessage or "No se pudo entregar el contenido del cofre.")
        return false
    end

    if resultMessage then
        player:SendBroadcastMessage(resultMessage)
    else
        player:SendBroadcastMessage("Has recibido el contenido del cofre.")
    end

    TryDespawnChest(gameObject)
    CheckEventCompletion(player)

    return false
end

function ClancyChestSystem.RequestOpen(player)
    D("Handler RequestOpen player=" .. PName(player))

    if not RequireAdmin(player) then
        return
    end

    SendAdminWindow(player)
end

function ClancyChestSystem.AddItem(player, itemEntry, amount, chance, kind)
    D(
        "Handler AddItem player=" ..
        PName(player) ..
        " kindRaw=" ..
        tostring(kind) ..
        " itemEntryRaw=" ..
        tostring(itemEntry) ..
        " amountRaw=" ..
        tostring(amount) ..
        " chanceRaw=" ..
        tostring(chance)
    )

    if not RequireAdmin(player) then
        return
    end

    if State.active and not CONFIG.ALLOW_EDIT_WHILE_ACTIVE then
        player:SendBroadcastMessage("No puedes editar los items mientras el evento está activo.")
        RefreshAdminWindow(player)
        return
    end

    kind = NormalizeKind(kind)
    amount = ToUInt(amount, 0)
    chance = ClampChance(chance)

    if amount <= 0 then
        player:SendBroadcastMessage("Cantidad inválida.")
        RefreshAdminWindow(player)
        return
    end

    if kind == "item" then
        itemEntry = ToUInt(itemEntry, 0)

        if itemEntry <= 0 then
            player:SendBroadcastMessage("ItemID inválido.")
            RefreshAdminWindow(player)
            return
        end

        if not ItemExists(itemEntry) then
            player:SendBroadcastMessage("El item " .. tostring(itemEntry) .. " no existe en item_template.")
            RefreshAdminWindow(player)
            return
        end
    else
        -- Honor / arena / gold se guardan en un id mágico fijo por tipo,
        -- así que cada tipo es una sola fila en la tabla y los AddItem
        -- repetidos acumulan amount como con los items.
        itemEntry = GetKindMagicId(kind)
    end

    local currentAmount = 0

    if State.items[itemEntry] then
        currentAmount = ToUInt(State.items[itemEntry].amount, 0)
    end

    State.items[itemEntry] = {
        amount = currentAmount + amount,
        chance = chance
    }

    PersistStockItem(itemEntry)

    local label = GetRewardName(itemEntry)
    local unit  = ""

    if kind == "gold" then
        unit = "g"
    end

    player:SendBroadcastMessage(
        "Añadido: " ..
        tostring(label) ..
        " x" ..
        tostring(amount) ..
        unit ..
        " con " ..
        tostring(chance) ..
        "% de probabilidad."
    )

    RefreshAdminWindow(player)
end

function ClancyChestSystem.RemoveItem(player, itemEntry, amount)
    D(
        "Handler RemoveItem player=" ..
        PName(player) ..
        " itemEntryRaw=" ..
        tostring(itemEntry) ..
        " amountRaw=" ..
        tostring(amount)
    )

    if not RequireAdmin(player) then
        return
    end

    if State.active and not CONFIG.ALLOW_EDIT_WHILE_ACTIVE then
        player:SendBroadcastMessage("No puedes editar los items mientras el evento está activo.")
        RefreshAdminWindow(player)
        return
    end

    itemEntry = ToUInt(itemEntry, 0)
    amount = ToUInt(amount, 0)

    if itemEntry <= 0 then
        player:SendBroadcastMessage("ItemID inválido.")
        RefreshAdminWindow(player)
        return
    end

    local data = State.items[itemEntry]
    local current = 0
    local chance = 100

    if data then
        current = ToUInt(data.amount, 0)
        chance = ClampChance(data.chance)
    end

    if current <= 0 then
        player:SendBroadcastMessage("Ese item no está configurado en el cofre.")
        RefreshAdminWindow(player)
        return
    end

    if amount <= 0 or amount >= current then
        State.items[itemEntry] = nil
        PersistStockItem(itemEntry)
        player:SendBroadcastMessage("Item eliminado del cofre.")
    else
        State.items[itemEntry] = {
            amount = current - amount,
            chance = chance
        }

        PersistStockItem(itemEntry)
        player:SendBroadcastMessage("Cantidad reducida.")
    end

    RefreshAdminWindow(player)
end

function ClancyChestSystem.ClearStock(player)
    D("Handler ClearStock player=" .. PName(player))

    if not RequireAdmin(player) then
        return
    end

    if State.active and not CONFIG.ALLOW_EDIT_WHILE_ACTIVE then
        player:SendBroadcastMessage("No puedes limpiar los items mientras el evento está activo.")
        RefreshAdminWindow(player)
        return
    end

    ClearStock()
    player:SendBroadcastMessage("Items del cofre limpiados.")
    RefreshAdminWindow(player)
end

function ClancyChestSystem.Start(player, durationMinutes)
    D("Handler Start player=" .. PName(player) .. " duration=" .. tostring(durationMinutes))
    Activate(player, durationMinutes)
end

function ClancyChestSystem.Stop(player)
    D("Handler Stop player=" .. PName(player))

    if not RequireAdmin(player) then
        return
    end

    Deactivate(player, "manual")
end

D("Registrando gossip events...")
D("PREP_GO_ENTRY=" .. tostring(CONFIG.PREP_GO_ENTRY))
D("ACTIVE_GO_ENTRY=" .. tostring(CONFIG.ACTIVE_GO_ENTRY))

RegisterGameObjectGossipEvent(CONFIG.PREP_GO_ENTRY, GOSSIP_EVENT_ON_HELLO, OnPrepChestHello)
RegisterGameObjectGossipEvent(CONFIG.ACTIVE_GO_ENTRY, GOSSIP_EVENT_ON_HELLO, OnActiveChestHello)

LoadState()

if State.active then
    ScheduleStop()
end

D(
    "Loaded PAYLOAD MODE. Prep GO: " ..
    tostring(CONFIG.PREP_GO_ENTRY) ..
    " Active GO: " ..
    tostring(CONFIG.ACTIVE_GO_ENTRY) ..
    " Handler: " ..
    HANDLER
)