--[[    
    Sistema de Invocación de Jefes - Servidor    
    5 grupos de recompensas, 4 items cada uno    
    Bug fixes: AIO.Handle directo, itemIndex, conteo grupos, WorldDBQuery, CountValidGroups    
]]--    
    
local AIO = AIO or require("AIO")    
    
-- ========================================    
-- CONFIGURACIÓN    
-- ========================================    
    
local BOSS_ENTRY = 5000011    
local NPC_ENTRY = 5000010    
    
local SPAWN_COORDS = {    
    x = -8949.95,    
    y = -132.493,    
    z = 83.5312,    
    o = 0    
}    
    
local ITEM_ENTRIES = {36786, 30809, 34057, 33470, 22573, 22445, 14344}    
    
local REWARD_GROUPS = {    
    {    
        name = "Armas de los Héroes",    
        items = {    
            {id = 46017, count = 1, name = "Espada Legendaria"},    
            {id = 49623, count = 1, name = "Hacha Sagrada"},    
            {id = 47524, count = 1, name = "Daga Venenosa"},    
            {id = 50070, count = 1, name = "Maza Divina"}    
        }    
    },    
    {    
        name = "Materiales Legendarios",    
        items = {    
            {id = 34057, count = 10, name = "Polvo Arcano"},    
            {id = 22445, count = 20, name = "Runa de Poder"},    
            {id = 14344, count = 15, name = "Cristal Mágico"},    
            {id = 36860, count = 25, name = "Esencia Arcana"}    
        }    
    },    
    {    
        name = "Joyas Rúnicas",    
        items = {    
            {id = 40093, count = 30, name = "Rubí Brillante"},    
            {id = 50274, count = 50, name = "Zafiro Oscuro"},    
            {id = 45087, count = 50, name = "Esmeralda Mística"},    
            {id = 36919, count = 40, name = "Diamante Celestial"}    
        }    
    },    
    {    
        name = "Pociones Alquímicas",    
        items = {    
            {id = 43102, count = 1, name = "Poción de Poder"},    
            {id = 22845, count = 5, name = "Elixir de Vida"},    
            {id = 33447, count = 3, name = "Poción de Mana"},    
            {id = 33448, count = 5, name = "Frasco de Poder"}    
        }    
    },    
    {    
        name = "Misceláneos de Poder",    
        items = {    
            {id = 22573, count = 1, name = "Tomo Antiguo"},    
            {id = 33470, count = 2, name = "Pergamino Arcano"},    
            {id = 30809, count = 1, name = "Reliquia Mística"},    
            {id = 44958, count = 1, name = "Reliquia Ancestral"}    
        }    
    }    
}    
    
-- ========================================    
-- ESTADO    
-- ========================================    
    
local playerSelectedRewards = {}    
local playerSelectedSummoner = {}    
local bossIsSpawned = false    
local groupSelectedRewards = nil    
    
-- ========================================    
-- FUNCIONES AUXILIARES    
-- ========================================    
    
local function IsValidItem(itemID)    
    local query = WorldDBQuery("SELECT entry FROM item_template WHERE entry = " .. itemID)    
    return query ~= nil    
end    
    
local function HasRequiredItems(player)    
    for i = 1, #ITEM_ENTRIES do    
        if player:GetItemCount(ITEM_ENTRIES[i]) < 1 then    
            return false    
        end    
    end    
    return true    
end    
    
local function RemoveRequiredItems(player)    
    for i = 1, #ITEM_ENTRIES do    
        player:RemoveItem(ITEM_ENTRIES[i], 1)    
    end    
end    
    
-- FIX Bug 4: WorldDBQuery en vez de GetItemLink    
local function GetItemName(itemID, fallbackName)    
    local query = WorldDBQuery("SELECT name FROM item_template WHERE entry = " .. itemID)    
    if query then    
        return query:GetString(0)    
    end    
    return fallbackName or "Item ID " .. itemID    
end    
    
-- FIX Bug 3: contar grupos válidos    
local function CountValidGroups()    
    local count = 0    
    for _, group in ipairs(REWARD_GROUPS) do    
        local hasValid = false    
        for _, item in ipairs(group.items) do    
            if IsValidItem(item.id) then hasValid = true; break end    
        end    
        if hasValid then count = count + 1 end    
    end    
    return count    
end    
    
-- ========================================    
-- HANDLERS    
-- ========================================    
    
local handlers = {}    
    
function handlers.OpenSummonUI(player)    
    local msg = AIO.Msg()    
    
    if bossIsSpawned then    
        local summonerName = playerSelectedSummoner[player:GetGUIDLow()] or "Desconocido"    
        msg:Add("BossClancyGood", "ShowBossSpawned", summonerName)    
    else    
        local groupedRewards = {}    
        for groupIndex, group in ipairs(REWARD_GROUPS) do    
            local validItems = {}    
            for itemIndex, item in ipairs(group.items) do    
                if IsValidItem(item.id) then    
                    table.insert(validItems, {    
                        id = item.id,    
                        count = item.count,    
                        name = GetItemName(item.id, item.name),    
                        groupIndex = groupIndex,    
                        itemIndex = itemIndex    
                    })    
                end    
            end    
            if #validItems > 0 then    
                groupedRewards[groupIndex] = {    
                    name = group.name,    
                    items = validItems    
                }    
            end    
        end    
    
        local hasItems = HasRequiredItems(player)    
        local missingItems = {}    
        if not hasItems then    
            for i = 1, #ITEM_ENTRIES do    
                if player:GetItemCount(ITEM_ENTRIES[i]) < 1 then    
                    table.insert(missingItems, {    
                        id = ITEM_ENTRIES[i],    
                        name = GetItemName(ITEM_ENTRIES[i])    
                    })    
                end    
            end    
        end    
    
        msg:Add("BossClancyGood", "ShowRewardSelection", groupedRewards, hasItems, missingItems)    
    end    
    
    msg:Send(player)    
end    
    
function handlers.SelectReward(player, selectedRewards)    
    if bossIsSpawned then    
        player:SendBroadcastMessage("Ya hay un jefe activo.")    
        return    
    end    
    
    if not selectedRewards then    
        player:SendBroadcastMessage("Debes seleccionar una recompensa de cada grupo.")    
        return    
    end    
    
    local selectedCount = 0    
    for _ in pairs(selectedRewards) do selectedCount = selectedCount + 1 end    
    
    -- FIX Bug 3: comparar contra grupos válidos reales    
    if selectedCount < CountValidGroups() then    
        player:SendBroadcastMessage("Debes seleccionar una recompensa de cada grupo.")    
        return    
    end    
    
    if not HasRequiredItems(player) then    
        -- FIX Bug 1: llamar directamente al handler del servidor    
        handlers.OpenSummonUI(player)    
        return    
    end    
    
    local playerGUID = player:GetGUIDLow()    
    playerSelectedRewards[playerGUID] = selectedRewards    
    playerSelectedSummoner[playerGUID] = player:GetName()    
    groupSelectedRewards = selectedRewards    
    
    RemoveRequiredItems(player)    
    
    local boss = player:SpawnCreature(BOSS_ENTRY, SPAWN_COORDS.x, SPAWN_COORDS.y, SPAWN_COORDS.z, SPAWN_COORDS.o)    
    if boss then    
        boss:SetCreatorGUID(player:GetGUID())    
        bossIsSpawned = true    
        player:SendBroadcastMessage("Has invocado al jefe. Matalo para recibir tus recompensas!")    
    
        if player:IsInGroup() then    
            local group = player:GetGroup()    
            local groupMembers = group:GetMembers()    
            for _, member in ipairs(groupMembers) do    
                if member and member ~= player then    
                    -- FIX Bug 1: llamar directamente    
                    handlers.OpenSummonUI(member)    
                end    
            end    
        end    
    else    
        player:SendBroadcastMessage("Error al invocar el jefe.")    
        for i = 1, #ITEM_ENTRIES do    
            player:AddItem(ITEM_ENTRIES[i], 1)    
        end    
    end    
end    
    
-- ========================================    
-- EVENTOS    
-- ========================================    
    
local function OnGossipHello(event, player, object)    
    handlers.OpenSummonUI(player)    
    player:GossipComplete()    
end    
    
local function OnKillCreature(event, player, killed)    
    if killed:GetEntry() ~= BOSS_ENTRY then return end    
    
    local selectedRewards = groupSelectedRewards    
    if not selectedRewards then    
        player:SendBroadcastMessage("Error: No se encontraron recompensas seleccionadas.")    
        return    
    end    
    
    local function DistributeRewards(target)    
        for groupIndex, itemIndex in pairs(selectedRewards) do    
            local group = REWARD_GROUPS[groupIndex]    
            if group and group.items[itemIndex] then    
                local reward = group.items[itemIndex]    
                if not IsValidItem(reward.id) then    
                    player:SendBroadcastMessage("Error: Recompensa no existe.")    
                    return false    
                end    
                target:AddItem(reward.id, reward.count)    
                target:SendBroadcastMessage("Recompensa recibida: " .. (reward.name or "item"))    
            end    
        end    
        return true    
    end    
    
    if player:IsInGroup() then    
        local group = player:GetGroup()    
        local groupMembers = group:GetMembers()    
        if #groupMembers > 10 then    
            player:SendBroadcastMessage("Grupo demasiado grande. Maximo 10.")    
            return    
        end    
        for _, member in ipairs(groupMembers) do    
            if member and member:IsInMap(player) then    
                if not DistributeRewards(member) then return end    
            end    
        end    
    else    
        if not DistributeRewards(player) then return end    
    end    
    
    killed:DespawnOrUnsummon()    
    bossIsSpawned = false    
    groupSelectedRewards = nil    
    
    -- FIX Bug 1: llamar directamente    
    local function NotifyClient(target)    
        handlers.OpenSummonUI(target)    
    end    
    
    if player:IsInGroup() then    
        local group = player:GetGroup()    
        local groupMembers = group:GetMembers()    
        for _, member in ipairs(groupMembers) do    
            if member and member:IsInMap(player) then NotifyClient(member) end    
        end    
    else    
        NotifyClient(player)    
    end    
end    
    
-- ========================================    
-- REGISTRO    
-- ========================================    
    
AIO.AddHandlers("BossClancyGood", handlers)    
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)    
RegisterPlayerEvent(7, OnKillCreature)    
    
print("[Eluna] Sistema de Invocación de Jefes cargado.")
