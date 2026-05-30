local AIO = AIO or require("AIO")

-- ============================================================
-- CONFIGURACION
-- ============================================================
local playerCooldowns = {}
local COOLDOWN_SECONDS = 5
local pendingRewards = {}

-- Activa/desactiva los prints de debug. En produccion ponlo a false.
local DEBUG = true
local function dprint(...)
    if DEBUG then print(...) end
end

-- ============================================================
-- ENTREGA DE RECOMPENSAS POR CORREO
-- ============================================================
-- Si la mochila esta llena, o si el jugador ya tiene el item, lo enviamos al
-- buzon en lugar de a la mochila. Asi nunca se pierde la recompensa ni se le
-- ocupa un slot con duplicados.
local MAIL_IF_DUPLICATE = true              -- enviar por correo si el jugador ya tiene el item
local MAIL_INCLUDE_BANK = true              -- contar tambien los items del banco al detectar duplicados
local MAIL_SENDER_GUID  = 0                 -- GUIDLow del remitente (0 = sistema)
local MAIL_STATIONERY   = 41                -- 41 = MAIL_STATIONERY_DEFAULT, 61 = GM
local MAIL_SUBJECT      = "Recompensa de Cofre"
local MAIL_BODY_FULLBAG = "Tu inventario estaba lleno cuando ganaste tu recompensa, asi que te la enviamos al buzon. Disfrutala!"
local MAIL_BODY_DUP     = "Ya tenias este item, asi que para no ocupar espacio en tu inventario te lo enviamos al buzon. Disfrutalo!"

print("[StrikeChest] ====== SERVIDOR CARGADO ======")

-- ============================================================
-- DEFINICION DE COFRES (cargados desde SQL en LoadCasesFromDB)
-- ============================================================
-- Tablas en acore_world: csgo_box_cases, csgo_box_items.
-- Schema y datos iniciales en csgo_box_schema.sql.
--
-- En el juego, GM puede recargar la config en vivo con:  .cofres reload
-- (sin necesidad de .reload eluna).
-- ============================================================
local CASES = {}  -- poblado por LoadCasesFromDB(); ver al final del archivo.

-- Normaliza el costo del cofre. Acepta tanto cost = {...} como costGold = N (legacy).
local function NormalizeCost(case)
    if type(case.cost) == "table" then
        local c = case.cost
        if c.type == "item" and c.itemId and c.amount then
            return { type = "item", itemId = c.itemId, amount = c.amount }
        end
        if c.type == "gold" and c.amount then
            return { type = "gold", amount = c.amount }
        end
    end
    if case.costGold then
        return { type = "gold", amount = case.costGold }
    end
    return { type = "gold", amount = 0 }
end

-- Pre-construimos la info de cofres y la enviamos tal cual a cada cliente
-- en cada RequestCaseList. Se reconstruye solo cuando recargamos desde SQL.
local function BuildCasesInfo()
    local info = {}
    for id, case in pairs(CASES) do
        local itemList = {}
        for _, item in ipairs(case.items) do
            itemList[#itemList + 1] = {
                entry = item.entry,
                rarity = item.rarity,
                rarityName = item.rarityName,
                creatureEntry = item.creatureEntry or 0,
            }
        end
        info[id] = {
            name = case.name,
            icon = case.icon,
            cost = NormalizeCost(case),
            items = itemList,
        }
    end
    return info
end
local CASES_INFO = {}  -- regenerado por LoadCasesFromDB().

-- ============================================================
-- CREATURE CACHE: Pre-cargar datos de criaturas para el cliente
-- (Mismo sistema que usa la tienda)
-- ============================================================
local CreatureCache = {}
local CreatureCacheCount = 0  -- contador real, ya que las claves son IDs no consecutivos (#CreatureCache devolveria 0).
-- En recarga (.cofres reload) limpiamos el cache para que solo contenga las
-- criaturas referenciadas por los cofres actuales.
local function ResetCreatureCache()
    CreatureCache = {}
    CreatureCacheCount = 0
end

local function LoadCreatureCache()
    -- Recopilar todos los creatureEntry de las monturas
    local entries = {}
    local seen = {}
    for _, caseData in pairs(CASES) do
        for _, item in ipairs(caseData.items) do
            local ce = item.creatureEntry
            if ce and ce > 0 and not seen[ce] then
                seen[ce] = true
                entries[#entries + 1] = tostring(ce)
            end
        end
    end

    if #entries == 0 then
        print("[StrikeChest] No hay criaturas para pre-cachear")
        return
    end

    local entryStr = table.concat(entries, ", ")

    -- Consultar creature_template
    local Query = WorldDBQuery(
        "SELECT entry, name, subname, IconName, type_flags, type, family, `rank`, "
        .. "KillCredit1, KillCredit2, HealthModifier, ManaModifier, RacialLeader, MovementType "
        .. "FROM creature_template WHERE entry IN (" .. entryStr .. ")"
    )

    if Query then
        repeat
            local entry = Query:GetUInt32(0)
            if not CreatureCache[entry] then
                CreatureCacheCount = CreatureCacheCount + 1
            end
            CreatureCache[entry] = {
                entry,                  -- [1]
                Query:GetString(1),     -- [2] name
                Query:GetString(2),     -- [3] subname
                Query:GetString(3),     -- [4] IconName
                Query:GetUInt32(4),     -- [5] type_flags
                Query:GetUInt32(5),     -- [6] type
                Query:GetUInt32(6),     -- [7] family
                Query:GetUInt32(7),     -- [8] rank
                Query:GetUInt32(8),     -- [9] KillCredit1
                Query:GetUInt32(9),     -- [10] KillCredit2
                0,                      -- [11] modelId1 (se llena abajo)
                0,                      -- [12] modelId2
                0,                      -- [13] modelId3
                0,                      -- [14] modelId4
                Query:GetFloat(10),     -- [15] HealthModifier
                Query:GetFloat(11),     -- [16] ManaModifier
                Query:GetUInt32(12),    -- [17] RacialLeader
                Query:GetUInt32(13),    -- [18] MovementType
            }
        until not Query:NextRow()
    end

    -- Consultar creature_template_model para AzerothCore
    local ModelQuery = WorldDBQuery(
        "SELECT CreatureID, Idx, CreatureDisplayID FROM creature_template_model WHERE CreatureID IN (" .. entryStr .. ")"
    )

    if ModelQuery then
        repeat
            local entry = ModelQuery:GetUInt32(0)
            if CreatureCache[entry] then
                local idx = ModelQuery:GetUInt32(1)  -- Idx: 0, 1, 2, 3
                local displayId = ModelQuery:GetUInt32(2)
                if idx >= 0 and idx <= 3 then
                    -- modelId1 = index 11, modelId2 = 12, modelId3 = 13, modelId4 = 14
                    CreatureCache[entry][11 + idx] = displayId
                end
            end
        until not ModelQuery:NextRow()
    end

    print("[StrikeChest] Creature cache cargado: " .. CreatureCacheCount .. " criaturas")
end

-- ============================================================
-- ENVIAR SMSG_CREATURE_QUERY_RESPONSE AL CLIENTE
-- (Opcode 97 = 0x61)
-- ============================================================
local function SendCreatureQueryResponse(player, data)
    local packet = CreatePacket(97, 100)
    packet:WriteULong(data[1])          -- entry
    packet:WriteString(data[2] or "")   -- name
    packet:WriteUByte(0)                -- name2
    packet:WriteUByte(0)                -- name3
    packet:WriteUByte(0)                -- name4
    packet:WriteString(data[3] or "")   -- subname
    packet:WriteString(data[4] or "")   -- IconName
    packet:WriteULong(data[5])          -- type_flags
    packet:WriteULong(data[6])          -- type
    packet:WriteULong(data[7])          -- family
    packet:WriteULong(data[8])          -- rank
    packet:WriteULong(data[9])          -- KillCredit1
    packet:WriteULong(data[10])         -- KillCredit2
    packet:WriteULong(data[11])         -- modelId1
    packet:WriteULong(data[12])         -- modelId2
    packet:WriteULong(data[13])         -- modelId3
    packet:WriteULong(data[14])         -- modelId4
    packet:WriteFloat(data[15])         -- HealthModifier
    packet:WriteFloat(data[16])         -- ManaModifier
    packet:WriteUByte(data[17])         -- RacialLeader
    packet:WriteULong(0)                -- questItem1
    packet:WriteULong(0)                -- questItem2
    packet:WriteULong(0)                -- questItem3
    packet:WriteULong(0)                -- questItem4
    packet:WriteULong(0)                -- questItem5
    packet:WriteULong(0)                -- questItem6
    packet:WriteULong(data[18])         -- MovementType
    player:SendPacket(packet)
end

-- Enviar creature cache al jugador en login
local function OnPlayerLogin(event, player)
    for _, creatureData in pairs(CreatureCache) do
        SendCreatureQueryResponse(player, creatureData)
    end
    print("[StrikeChest] Creature cache enviado a " .. player:GetName() .. " (" .. CreatureCacheCount .. " criaturas)")
end
RegisterPlayerEvent(3, OnPlayerLogin)

-- ============================================================
-- FUNCIONES AUXILIARES
-- ============================================================
local function SelectWinner(caseData)
    local totalWeight = 0
    for _, item in ipairs(caseData.items) do
        totalWeight = totalWeight + (item.weight or 0)
    end
    if totalWeight <= 0 then
        -- Defensa: cofre vacio o mal configurado.
        return caseData.items[1]
    end
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for _, item in ipairs(caseData.items) do
        cumulative = cumulative + item.weight
        if roll <= cumulative then
            return item
        end
    end
    return caseData.items[#caseData.items]
end

local function BuildReel(caseData, winnerItem, totalCards, winPosition)
    local reel = {}
    local items = caseData.items
    local n = #items
    for i = 1, totalCards do
        local src
        if i == winPosition then
            src = winnerItem
        else
            src = items[math.random(1, n)]
        end
        reel[i] = {entry = src.entry, rarity = src.rarity, rarityName = src.rarityName}
    end
    return reel
end

-- ============================================================
-- HANDLERS AIO SERVIDOR
-- ============================================================
local CaseHandlers = AIO.AddHandlers("StrikeChest", {})

-- Devuelve true si el jugador ya tiene este item (en bolsa o, opcionalmente, banco).
local function PlayerAlreadyHas(player, entry)
    if not MAIL_IF_DUPLICATE then return false end
    -- Player:GetItemCount(entry, checkinBank=false). Defendido contra cores que no expongan la API.
    local ok, count = pcall(function() return player:GetItemCount(entry, MAIL_INCLUDE_BANK) end)
    return ok and count and count > 0
end

-- Envia el item por correo. Devuelve true si SendMail estaba disponible y no lanzo error.
local function MailItem(player, entry, body)
    if type(SendMail) ~= "function" then
        print("[StrikeChest] AVISO: SendMail no disponible en este nucleo, no se puede enviar al buzon")
        return false
    end
    local ok, err = pcall(
        SendMail,
        MAIL_SUBJECT,
        body or MAIL_BODY_FULLBAG,
        player:GetGUIDLow(),  -- receiverGUIDLow
        MAIL_SENDER_GUID,     -- senderGUIDLow
        MAIL_STATIONERY,      -- stationery
        0,                    -- delay (ms)
        0,                    -- money
        0,                    -- cod
        entry,                -- item entry
        1                     -- amount
    )
    if not ok then
        print("[StrikeChest] ERROR enviando correo: " .. tostring(err))
        return false
    end
    return true
end

-- Intenta entregar al jugador la recompensa pendiente (si existe).
-- Devuelve:
--   "none"      si no habia recompensa pendiente,
--   "delivered" si se entrego a la mochila,
--   "mailed"    si se envio al buzon (mochila llena o duplicado),
--   "failed"    si no fue posible entregarla por ningun medio.
local function TryDeliverPending(player)
    local guid = player:GetGUIDLow()
    local reward = pendingRewards[guid]
    if not reward then return "none" end

    -- Caso A: el jugador ya tiene este item -> directamente al buzon, sin tocar la mochila.
    if PlayerAlreadyHas(player, reward.entry) then
        if MailItem(player, reward.entry, MAIL_BODY_DUP) then
            player:SendBroadcastMessage("|cff00FF00[Cofres]|r Ya tenias este item, te lo enviamos al |cffFFD700buzon|r.")
            dprint("[StrikeChest] TryDeliverPending: " .. player:GetName() .. " recibio entry=" .. tostring(reward.entry) .. " por correo (duplicado)")
            pendingRewards[guid] = nil
            return "mailed"
        end
        -- Si SendMail fallo, caemos al flujo normal e intentamos meterlo en la mochila igualmente.
    end

    -- Caso B: intentamos darlo a la mochila.
    local addedItem = player:AddItem(reward.entry, 1)
    if addedItem then
        local itemLink = addedItem:GetItemLink(0)
        player:SendBroadcastMessage("|cff00FF00[Cofres]|r Has obtenido: " .. itemLink)
        dprint("[StrikeChest] TryDeliverPending: " .. player:GetName() .. " recibio " .. tostring(reward.entry) .. " (" .. tostring(reward.rarityName) .. ")")
        pendingRewards[guid] = nil
        return "delivered"
    end

    -- Caso C: la mochila estaba llena -> al buzon como red de seguridad.
    if MailItem(player, reward.entry, MAIL_BODY_FULLBAG) then
        player:SendBroadcastMessage("|cff00FF00[Cofres]|r Tu inventario estaba lleno, enviamos tu recompensa al |cffFFD700buzon|r.")
        dprint("[StrikeChest] TryDeliverPending: " .. player:GetName() .. " recibio entry=" .. tostring(reward.entry) .. " por correo (mochila llena)")
        pendingRewards[guid] = nil
        return "mailed"
    end

    -- Si tampoco se pudo enviar por correo: dejamos el reward pendiente para reintentar despues.
    return "failed"
end

function CaseHandlers.RequestCaseList(player)
    dprint("[StrikeChest] >>> RequestCaseList llamado por: " .. player:GetName())

    -- Si tenia una recompensa anterior atascada, la entregamos ahora (a la mochila o al buzon).
    local result = TryDeliverPending(player)
    if result == "failed" then
        AIO.Handle(player, "StrikeChest", "Error", "No pudimos entregar tu recompensa anterior. Avisa a un administrador.")
        return
    end

    AIO.Handle(player, "StrikeChest", "ShowCaseSelect", CASES_INFO)
    dprint("[StrikeChest] <<< ShowCaseSelect enviado a " .. player:GetName())
end

function CaseHandlers.RequestOpen(player, caseId)
    dprint("[StrikeChest] ========================================")
    dprint("[StrikeChest] >>> RequestOpen llamado")
    dprint("[StrikeChest] Jugador: " .. player:GetName())

    caseId = tonumber(caseId)
    dprint("[StrikeChest] caseId recibido: " .. tostring(caseId) .. " (type: " .. type(caseId) .. ")")

    if not caseId then
        AIO.Handle(player, "StrikeChest", "Error", "ID de cofre invalido.")
        return
    end

    local case = CASES[caseId]
    dprint("[StrikeChest] CASES[" .. tostring(caseId) .. "] = " .. tostring(case))

    if not case then
        AIO.Handle(player, "StrikeChest", "Error", "Cofre no encontrado.")
        return
    end

    dprint("[StrikeChest] Cofre encontrado: " .. case.name)

    local guid = player:GetGUIDLow()
    dprint("[StrikeChest] GUID: " .. tostring(guid))

    -- Cooldown check
    local now = os.time()
    local lastOpen = playerCooldowns[guid]
    if lastOpen and (now - lastOpen) < COOLDOWN_SECONDS then
        local remaining = COOLDOWN_SECONDS - (now - lastOpen)
        dprint("[StrikeChest] En cooldown, faltan " .. remaining .. " segundos")
        AIO.Handle(player, "StrikeChest", "Error", "Espera " .. remaining .. " segundos.")
        return
    end
    dprint("[StrikeChest] Sin cooldown activo")

    -- Si tiene un reward pendiente sin reclamar, intentamos entregarlo primero
    -- (a la mochila o al buzon). Solo bloqueamos si fallaron ambos canales.
    local pendingResult = TryDeliverPending(player)
    if pendingResult == "failed" then
        AIO.Handle(player, "StrikeChest", "Error", "No pudimos entregar tu recompensa anterior. Avisa a un administrador.")
        return
    end

    -- Cost check (gold o item)
    local cost = NormalizeCost(case)
    dprint("[StrikeChest] Costo del cofre: type=" .. tostring(cost.type) .. " amount=" .. tostring(cost.amount) .. " itemId=" .. tostring(cost.itemId))

    if cost.type == "gold" then
        local playerGold = player:GetCoinage()
        if playerGold < cost.amount then
            dprint("[StrikeChest] ORO INSUFICIENTE")
            AIO.Handle(player, "StrikeChest", "Error", "No tienes suficiente oro. Necesitas " .. math.floor(cost.amount / 10000) .. " gold.")
            return
        end
        player:ModifyMoney(-cost.amount)
        dprint("[StrikeChest] Oro despues de descuento: " .. tostring(player:GetCoinage()))

    elseif cost.type == "item" then
        -- Cobramos solo de la mochila (no del banco) para no requerir trips al banco.
        local have = player:GetItemCount(cost.itemId, false) or 0
        if have < cost.amount then
            local tpl = type(GetItemTemplate) == "function" and GetItemTemplate(cost.itemId) or nil
            local itemName = (tpl and tpl:GetName()) or ("item #" .. tostring(cost.itemId))
            dprint("[StrikeChest] MONEDA INSUFICIENTE: " .. itemName)
            AIO.Handle(player, "StrikeChest", "Error", "No tienes suficiente. Necesitas " .. cost.amount .. "x " .. itemName .. ".")
            return
        end
        -- Eluna's Player:RemoveItem suele devolver nil aunque borre los items, asi que
        -- no chequeamos su retorno. Re-verificamos con GetItemCount despues para asegurar.
        local ok, removeErr = pcall(function() player:RemoveItem(cost.itemId, cost.amount) end)
        if not ok then
            print("[StrikeChest] ERROR en RemoveItem: " .. tostring(removeErr))
            AIO.Handle(player, "StrikeChest", "Error", "No se pudo cobrar el costo del cofre. Avisa a un administrador.")
            return
        end
        local newHave = player:GetItemCount(cost.itemId, false) or 0
        if newHave > (have - cost.amount) then
            dprint("[StrikeChest] WARN: RemoveItem no descontó (" .. have .. " -> " .. newHave .. ")")
            AIO.Handle(player, "StrikeChest", "Error", "No se pudo cobrar el costo del cofre. Avisa a un administrador.")
            return
        end
        dprint("[StrikeChest] Items cobrados: " .. cost.amount .. "x " .. cost.itemId .. " (" .. have .. " -> " .. newHave .. ")")

    else
        AIO.Handle(player, "StrikeChest", "Error", "Tipo de costo invalido en este cofre.")
        return
    end

    -- Set cooldown
    playerCooldowns[guid] = now

    -- Select winner
    local winnerItem = SelectWinner(case)
    dprint("[StrikeChest] Item ganador: entry=" .. tostring(winnerItem.entry) .. " rarity=" .. winnerItem.rarity)

    -- Build reel
    local totalCards = 45
    local winPosition = math.random(35, 42)
    local reel = BuildReel(case, winnerItem, totalCards, winPosition)
    dprint("[StrikeChest] Reel construido: " .. #reel .. " items, winPosition=" .. winPosition)

    -- Store pending reward (se entrega despues de la animacion)
    pendingRewards[guid] = {entry = winnerItem.entry, rarityName = winnerItem.rarityName}
    dprint("[StrikeChest] Reward pendiente almacenado")

    -- Obtener creatureEntry para monturas
    local creatureId = winnerItem.creatureEntry or 0
    dprint("[StrikeChest] creatureId enviado al cliente: " .. tostring(creatureId))

    -- Send to client
    AIO.Handle(player, "StrikeChest", "StartSpin", caseId, reel, winPosition, winnerItem.entry, winnerItem.rarity, winnerItem.rarityName, creatureId)
    dprint("[StrikeChest] <<< StartSpin enviado")
    dprint("[StrikeChest] ========================================")
end

function CaseHandlers.ClaimReward(player)
    local result = TryDeliverPending(player)
    if result == "none" then
        dprint("[StrikeChest] ClaimReward: no hay reward pendiente para " .. player:GetName())
    elseif result == "failed" then
        -- No deberia ocurrir salvo que SendMail no este disponible en el nucleo.
        AIO.Handle(player, "StrikeChest", "Error", "No pudimos entregarte la recompensa. Avisa a un administrador.")
        print("[StrikeChest] ClaimReward: TryDeliverPending fallo para " .. player:GetName())
    end
end

-- Safety: si al desloguear queda un reward pendiente, intentamos entregarlo
-- (a mochila, o por correo si la mochila esta llena). Tambien limpiamos cooldowns.
local function OnPlayerLogout(event, player)
    local guid = player:GetGUIDLow()
    if pendingRewards[guid] then
        local result = TryDeliverPending(player)
        if result == "failed" then
            -- Ultimo intento: hacer AddItem a fuerza bruta (puede fallar y perderse,
            -- pero al menos lo intentamos sin depender de SendMail).
            local entry = pendingRewards[guid].entry
            player:AddItem(entry, 1)
            pendingRewards[guid] = nil
            print("[StrikeChest] Logout safety: TryDeliverPending fallo para " .. player:GetName() .. ", forzando AddItem entry=" .. tostring(entry))
        else
            dprint("[StrikeChest] Logout safety: " .. player:GetName() .. " (" .. result .. ")")
        end
    end
    playerCooldowns[guid] = nil
end
RegisterPlayerEvent(4, OnPlayerLogout)

-- ============================================================
-- LOADER: cargar cofres desde acore_world
-- ============================================================
-- Lee csgo_box_cases + csgo_box_items, valida contra item_template /
-- creature_template, repuebla CASES, regenera CASES_INFO y CreatureCache.
-- Se llama:
--   * Una vez al cargar este script (al final del archivo).
--   * Cada vez que un GM ejecuta .cofres reload.
local function LoadCasesFromDB()
    -- Limpiamos lo viejo (necesario para reload).
    for k in pairs(CASES) do CASES[k] = nil end
    ResetCreatureCache()

    -- 1) Cargar cofres habilitados.
    local caseQuery = WorldDBQuery(
        "SELECT id, name, icon, cost_type, cost_amount, cost_item_id "
        .. "FROM csgo_box_cases WHERE enabled = 1 ORDER BY id"
    )
    if not caseQuery then
        print("[StrikeChest] ERROR: la tabla csgo_box_cases no existe o esta vacia. "
            .. "Ejecuta csgo_box_schema.sql en acore_world.")
        return 0, 0
    end

    local caseIds = {}
    repeat
        local id          = caseQuery:GetUInt32(0)
        local name        = caseQuery:GetString(1)
        local icon        = caseQuery:GetString(2)
        local costType    = caseQuery:GetString(3)
        local costAmount  = caseQuery:GetUInt32(4)
        local costItemId  = caseQuery:GetUInt32(5)

        local cost
        if costType == "item" then
            cost = { type = "item", itemId = costItemId, amount = costAmount }
        else
            cost = { type = "gold", amount = costAmount }
        end

        CASES[id] = {
            name  = name,
            icon  = (icon ~= "" and icon) or "Interface\\Icons\\INV_Box_01",
            cost  = cost,
            items = {},
        }
        caseIds[#caseIds + 1] = tostring(id)
    until not caseQuery:NextRow()

    if #caseIds == 0 then
        print("[StrikeChest] ERROR: no hay cofres habilitados (enabled=1) en csgo_box_cases.")
        return 0, 0
    end

    -- 2) Cargar items de esos cofres en una sola query.
    local itemsQuery = WorldDBQuery(
        "SELECT case_id, item_entry, weight, rarity, rarity_name, creature_entry "
        .. "FROM csgo_box_items WHERE case_id IN (" .. table.concat(caseIds, ",") .. ") "
        .. "ORDER BY case_id, item_entry"
    )

    local totalItems = 0
    local seenItem = {}  -- para validar entries (cache local de existencia).
    if itemsQuery then
        repeat
            local caseId        = itemsQuery:GetUInt32(0)
            local entry         = itemsQuery:GetUInt32(1)
            local weight        = itemsQuery:GetUInt32(2)
            local rarity        = itemsQuery:GetString(3)
            local rarityName    = itemsQuery:GetString(4)
            local creatureEntry = itemsQuery:GetUInt32(5)

            local case = CASES[caseId]
            if case then
                -- Validacion (best-effort): comprobamos que item_template tenga la entry.
                -- Lo hacemos por entry-cacheado para no spammear DB con duplicados.
                local valid = seenItem[entry]
                if valid == nil then
                    local v = WorldDBQuery("SELECT 1 FROM item_template WHERE entry = " .. entry .. " LIMIT 1")
                    valid = (v ~= nil)
                    seenItem[entry] = valid
                end
                if valid then
                    case.items[#case.items + 1] = {
                        entry         = entry,
                        weight        = (weight > 0 and weight) or 1,
                        rarity        = (rarity ~= "" and rarity) or "white",
                        rarityName    = (rarityName ~= "" and rarityName) or "Comun",
                        creatureEntry = creatureEntry,
                    }
                    totalItems = totalItems + 1
                else
                    print("[StrikeChest] WARN: item entry=" .. entry .. " del cofre " .. caseId
                        .. " no existe en item_template. Se omite.")
                end
            else
                print("[StrikeChest] WARN: item entry=" .. entry .. " referencia a un cofre inexistente o deshabilitado (case_id=" .. caseId .. "). Se omite.")
            end
        until not itemsQuery:NextRow()
    end

    -- 3) Quitar cofres que se hayan quedado vacios tras la validacion.
    local validCaseCount = 0
    for id, case in pairs(CASES) do
        if #case.items == 0 then
            print("[StrikeChest] WARN: cofre " .. id .. " (" .. case.name .. ") no tiene items validos. Se desactiva.")
            CASES[id] = nil
        else
            validCaseCount = validCaseCount + 1
        end
    end

    -- 4) Regenerar caches derivados.
    CASES_INFO = BuildCasesInfo()
    LoadCreatureCache()

    print("[StrikeChest] Cofres cargados desde SQL: " .. validCaseCount .. " cofres, " .. totalItems .. " items.")
    return validCaseCount, totalItems
end

-- ============================================================
-- COMANDOS .opencase y .cofres reload
-- ============================================================
-- Devuelve true si el jugador es GM (cualquier nivel de seguridad > 0).
local function IsGM(player)
    if not player then return false end
    if type(player.GetGMRank) == "function" then
        local r = player:GetGMRank()
        if r and r > 0 then return true end
    end
    -- Fallback universal en AzerothCore Eluna.
    if type(player.GetSecurity) == "function" then
        local s = player:GetSecurity()
        if s and s > 0 then return true end
    end
    return false
end

local function OnCommand(event, player, command)
    if command == "opencase" then
        CaseHandlers.RequestCaseList(player)
        return false
    end
    if command == "cofres reload" or command == "cofres recargar" then
        if not IsGM(player) then
            player:SendBroadcastMessage("|cffFF4040[Cofres]|r Solo un GM puede recargar la config.")
            return false
        end
        local cases, items = LoadCasesFromDB()
        player:SendBroadcastMessage("|cff66FF66[Cofres]|r Recarga completada: " .. cases .. " cofres, " .. items .. " items.")
        return false
    end
end
RegisterPlayerEvent(42, OnCommand)

-- ============================================================
-- CARGA INICIAL DESDE SQL
-- ============================================================
LoadCasesFromDB()

print("[StrikeChest] Comandos registrados: .opencase, .cofres reload")
print("[StrikeChest] ====== SERVIDOR LISTO ======")
