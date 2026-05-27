local AIO = AIO or require("AIO")
if not AIO.IsServer() then return end

local StoreHandlers = AIO.AddHandlers("FelStormStore", {})

local STORE_CURRENCY_ID = 49426

-- CONSTANTES PARA REGALOS
local GIFT_LOG_TABLE = "felstorm_store_gift_log"
local GIFT_LOG_ERROR_TABLE = "felstorm_store_gift_log_error"

local MAIL_STATIONERY_GM = 61
local GIFT_MAIL_SUBJECT = "Regalo de la tienda"
local GIFT_MAIL_BODY_TEMPLATE = "Has recibido un regalo de %s.\n\nGracias por apoyar al servidor."
local MAX_ATTACHMENTS_PER_MAIL = 12

-- CONSTANTES PARA COMPRAS NORMALES (NUEVO)
local PURCHASE_MAIL_SUBJECT = "Compra de la tienda"
local PURCHASE_MAIL_BODY = "Gracias por tu compra.\n\nTus artículos han sido enviados a tu buzón."

local SQL_TABLES = {
    CATEGORIES = "felstorm_store_categories",
    REWARDS = "felstorm_store_rewards",
    PAQUETE_ITEMS = "felstorm_store_paquete"
}

local StoreCache = {
    categories = {},
    rewards = {},
    paqueteItems = {},
    itemNames = {},
    creatureCache = {}
}

local CacheLoaded = false

local function CloneTable(tbl)
    if type(tbl) ~= "table" then return tbl end
    local t = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            t[k] = CloneTable(v)
        else
            t[k] = v
        end
    end
    return t
end

-- HELPERS PARA REGALOS
local function EscapeSQL(str)
    str = tostring(str or "")
    str = string.gsub(str, "\\", "\\\\")
    str = string.gsub(str, "'", "\\'")
    return str
end

local function NormalizeCharacterName(name)
    name = tostring(name or "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    if name == "" then
        return ""
    end
    return string.upper(string.sub(name, 1, 1)) .. string.lower(string.sub(name, 2))
end

local function FindCharacterByName(name)
    name = NormalizeCharacterName(name)
    if name == "" then
        return nil
    end

    local q = CharDBQuery("SELECT guid, name, account FROM characters WHERE name = '" .. EscapeSQL(name) .. "' LIMIT 1;")
    if not q then
        return nil
    end

    return {
        guid = q:GetUInt32(0),
        name = q:GetString(1),
        account = q:GetUInt32(2)
    }
end

local function LogGiftSuccess(sender, receiver, categoryName, entry)
    CharDBExecute(string.format(
        "INSERT INTO %s (sender_guid, sender_name, receiver_guid, receiver_name, category, entry_id, entry_type, entry_name, price, currency_id, status) VALUES (%u, '%s', %u, '%s', '%s', %u, '%s', '%s', %u, %u, 'sent');",
        GIFT_LOG_TABLE,
        sender:GetGUIDLow(),
        EscapeSQL(sender:GetName()),
        receiver.guid,
        EscapeSQL(receiver.name),
        EscapeSQL(categoryName or ""),
        tonumber(entry.id) or 0,
        EscapeSQL(entry.entryType or "product"),
        EscapeSQL(entry.name or "Desconocido"),
        tonumber(entry.price) or 0,
        STORE_CURRENCY_ID
    ))
end

local function LogGiftError(sender, receiverName, categoryName, entryId, reason)
    CharDBExecute(string.format(
        "INSERT INTO %s (sender_guid, sender_name, receiver_name, category, entry_id, reason) VALUES (%u, '%s', '%s', '%s', %u, '%s');",
        GIFT_LOG_ERROR_TABLE,
        sender:GetGUIDLow(),
        EscapeSQL(sender:GetName()),
        EscapeSQL(receiverName or ""),
        EscapeSQL(categoryName or ""),
        tonumber(entryId) or 0,
        EscapeSQL(reason or "Error desconocido")
    ))
end

local function BuildGiftAttachmentsFromEntry(entry)
    local attachments = {}

    if not entry then
        return attachments
    end

    if entry.entryType == "package" then
        for _, reward in ipairs(entry.rewards or {}) do
            if reward.itemSet and #reward.itemSet > 0 then
                for _, setItemId in ipairs(reward.itemSet) do
                    table.insert(attachments, {
                        itemId = setItemId,
                        count = 1
                    })
                end
            elseif reward.id and reward.id > 0 then
                table.insert(attachments, {
                    itemId = reward.id,
                    count = reward.count or 1
                })
            end
        end
        return attachments
    end

    if entry.service then
        return attachments
    end

    if entry.itemId and entry.itemId > 0 then
        table.insert(attachments, {
            itemId = entry.itemId,
            count = entry.count or 1
        })
    end

    return attachments
end

local _unpack = table.unpack or unpack

local function SendSingleMailChunk(receiverGuid, subject, body, chunk)
    local args = {
    subject,
    body,
    receiverGuid,
    0,
    MAIL_STATIONERY_GM,
    0,
    0,
    0
}

    for _, itemData in ipairs(chunk) do
        table.insert(args, tonumber(itemData.itemId) or 0)
        table.insert(args, tonumber(itemData.count) or 1)
    end

    local ok, err = pcall(function()
        SendMail(_unpack(args))
    end)

    if not ok then
        print("[FelStorm Store][GiftMailError] " .. tostring(err))
        return false, tostring(err)
    end

    return true
end

local function SendGiftAttachments(receiverGuid, senderName, entryName, attachments)
    if not receiverGuid or receiverGuid <= 0 then
        return false, "Destinatario inválido"
    end

    if not attachments or #attachments == 0 then
        return false, "No hay objetos para enviar"
    end

    local total = #attachments
    local index = 1
    local mailPart = 1

    while index <= total do
        local chunk = {}

        for _ = 1, MAX_ATTACHMENTS_PER_MAIL do
            if index > total then
                break
            end

            local itemData = attachments[index]
            local itemId = tonumber(itemData.itemId) or 0
            local count = tonumber(itemData.count) or 1

            if itemId > 0 and count > 0 then
                table.insert(chunk, {
                    itemId = itemId,
                    count = count
                })
            end

            index = index + 1
        end

        if #chunk == 0 then
            return false, "No hay adjuntos válidos para enviar"
        end

        local subject = GIFT_MAIL_SUBJECT .. ": " .. tostring(entryName or "Regalo")
        if total > MAX_ATTACHMENTS_PER_MAIL then
            subject = subject .. " (" .. tostring(mailPart) .. ")"
        end

        local body = string.format(GIFT_MAIL_BODY_TEMPLATE, tostring(senderName or "Un jugador"))

        local ok, err = SendSingleMailChunk(receiverGuid, subject, body, chunk)
        if not ok then
            return false, err
        end

        mailPart = mailPart + 1
    end

    return true
end

-- NUEVA FUNCIÓN: Enviar compras normales al buzón (NUEVO)
local function SendPurchaseAttachments(receiverGuid, entryName, attachments)
    if not receiverGuid or receiverGuid <= 0 then
        return false, "Destinatario inválido"
    end

    if not attachments or #attachments == 0 then
        return false, "No hay objetos para enviar"
    end

    local total = #attachments
    local index = 1
    local mailPart = 1

    while index <= total do
        local chunk = {}

        for _ = 1, MAX_ATTACHMENTS_PER_MAIL do
            if index > total then
                break
            end

            local itemData = attachments[index]
            local itemId = tonumber(itemData.itemId) or 0
            local count = tonumber(itemData.count) or 1

            if itemId > 0 and count > 0 then
                table.insert(chunk, {
                    itemId = itemId,
                    count = count
                })
            end

            index = index + 1
        end

        if #chunk == 0 then
            return false, "No hay adjuntos válidos para enviar"
        end

        local subject = PURCHASE_MAIL_SUBJECT .. ": " .. tostring(entryName or "Compra")
        if total > MAX_ATTACHMENTS_PER_MAIL then
            subject = subject .. " (" .. tostring(mailPart) .. ")"
        end

        local ok, err = SendSingleMailChunk(receiverGuid, subject, PURCHASE_MAIL_BODY, chunk)
        if not ok then
            return false, err
        end

        mailPart = mailPart + 1
    end

    return true
end

local function GetItemNameFromDB(itemId)
    if not itemId or itemId <= 0 then return nil end
    if StoreCache.itemNames[itemId] then
        return StoreCache.itemNames[itemId]
    end
    local query = WorldDBQuery("SELECT name FROM item_template WHERE entry = " .. tonumber(itemId) .. ";")
    if query then
        local name = query:GetString(0)
        StoreCache.itemNames[itemId] = name
        return name
    end
    return nil
end

local function LoadCategoriesFromDB()
    StoreCache.categories = {}
    local query = WorldDBQuery("SELECT ID, Name FROM " .. SQL_TABLES.CATEGORIES .. " ORDER BY ID;")
    if query then
        repeat
            local id = query:GetUInt32(0)
            local name = query:GetString(1)
            StoreCache.categories[id] = {
                id = id,
                name = name,
                layoutType = "featured_grid",
                title = string.upper(name),
                subtitle = "",
                description = "Artículos disponibles en la categoría " .. name .. "."
            }
        until not query:NextRow()
    end
end

local function LoadRewardsFromDB()
    StoreCache.rewards = {}
    local query = WorldDBQuery([[
        SELECT ID, IDcategoria, IDPaquete, Descripcion, Item, Cant, DisplayID, 
               activar_modo_3d, Precio, Icono, service, descuento, model_scale 
        FROM ]] .. SQL_TABLES.REWARDS .. ";")

    if query then
        repeat
            local row = {
                sqlId = query:GetUInt32(0),
                categoryId = query:GetUInt32(1),
                paqueteId = query:GetUInt32(2),
                description = query:GetString(3) or "",
                itemId = query:GetUInt32(4),
                cantidad = query:GetUInt32(5),
                displayId = query:GetUInt32(6),
                modo3d = query:GetUInt32(7) == 1,
                precio = query:GetUInt32(8),
                icono = query:GetString(9) or "",
                service = query:GetUInt32(10),
                descuento = query:GetUInt32(11) or 0,
                modelScale = query:GetFloat(12) or 1.0
            }

            if row.descuento > 0 then
                row.precioOriginal = row.precio
                row.precio = math.floor(row.precio * (1 - row.descuento / 100))
            end

            if row.paqueteId and row.paqueteId > 0 then
                row.entryType = "package"
                row.id = row.paqueteId
                row.previewType = "multiModel"
                row.name = row.description
                row.price = row.precio
                row.originalPrice = row.precioOriginal
                row.discount = row.descuento
                row.icon = (row.icono ~= "" and row.icono ~= nil) and row.icono or "INV_Misc_Gift_01"
                row.service = nil
                row.rewards = {}

            elseif row.service and row.service > 0 then
                row.entryType = "product"
                row.id = 900000 + row.sqlId
                row.previewType = "iconHero"
                row.name = row.description
                row.price = row.precio
                row.originalPrice = row.precioOriginal
                row.discount = row.descuento
                if row.icono and row.icono ~= "" then
                    row.icon = row.icono
                else
                    row.icon = "INV_Misc_Gear_01"
                end
                row.heroTexture = "Interface\\Icons\\" .. row.icon
                row.serviceKey = row.service
                row.service = true
                row.serviceValue = row.serviceKey

            elseif row.itemId and row.itemId > 0 then
                row.entryType = "product"
                row.id = row.itemId
                row.itemId = row.itemId

                if row.modo3d then
                    row.previewType = "creature3D"
                    row.creatureid = row.displayId
                row.modelScale = row.modelScale or 1.0
                    row.icon = nil
                else
                    row.previewType = "iconHero"
                    row.creatureid = nil
                    if row.icono and row.icono ~= "" then
                        row.icon = row.icono
                    else
                        row.icon = nil
                    end
                    row.heroTexture = row.icon and ("Interface\\Icons\\" .. row.icon) or nil
                end

                row.name = GetItemNameFromDB(row.itemId) or ("Item #" .. row.itemId)
                row.price = row.precio
                row.originalPrice = row.precioOriginal
                row.discount = row.descuento
                row.count = row.cantidad
                row.service = nil
            end

            if row then
                table.insert(StoreCache.rewards, row)
            end
        until not query:NextRow()
    end
end

local function LoadPaqueteItemsFromDB()
    StoreCache.paqueteItems = {}
    local query = WorldDBQuery("SELECT ID, IDPaquete, item1, cant1, item2, cant2, item3, cant3, item4, cant4, item5, cant5, item6, cant6, item7, cant7, item8, cant8, item9, cant9, item10, cant10, item11, cant11, item12, cant12, item13, cant13, item14, cant14, DisplayID, activar_modo_3d, es_set_armadura, tipo_armadura, raza_display, genero_display, Descripcion, model_scale FROM " .. SQL_TABLES.PAQUETE_ITEMS .. ";")

    if query then
        repeat
            local row = {
                id = query:GetUInt32(0),
                paqueteId = query:GetUInt32(1)
            }

            row.items = {}
            for i = 1, 14 do
                local itemIdx = 2 + (i-1)*2
                local cantIdx = 3 + (i-1)*2
                local itemId = query:GetUInt32(itemIdx)
                local cantidad = query:GetUInt32(cantIdx)
                if itemId and itemId > 0 then
                    table.insert(row.items, {
                        itemId = itemId,
                        cantidad = cantidad > 0 and cantidad or 1
                    })
                end
            end

            row.displayId = query:GetUInt32(30)
            row.modo3d = query:GetUInt32(31) == 1
            row.esSetArmadura = query:GetUInt32(32) == 1
            row.tipoArmadura = query:GetString(33) or ""
            row.razaDisplay = query:GetUInt32(34) or 1
            row.generoDisplay = query:GetUInt32(35) or 0
            row.descripcion = query:GetString(36) or ""
            row.modelScale = query:GetFloat(37) or 1.0

            if not StoreCache.paqueteItems[row.paqueteId] then
                StoreCache.paqueteItems[row.paqueteId] = {}
            end
            table.insert(StoreCache.paqueteItems[row.paqueteId], row)
        until not query:NextRow()
    end
end

local function BuildPackageRewards(paqueteId)
    local rewards = {}
    local paqueteData = StoreCache.paqueteItems[paqueteId]

    if not paqueteData then return rewards end

    for _, entry in ipairs(paqueteData) do
        if entry.esSetArmadura and #entry.items > 0 then
            local itemSetIds = {}
            for _, itemInfo in ipairs(entry.items) do
                table.insert(itemSetIds, itemInfo.itemId)
            end

            table.insert(rewards, {
                type = "itemSet",
                id = entry.items[1].itemId,
                count = 1,
                name = entry.descripcion ~= "" and entry.descripcion or "Set de Armadura",
                description = entry.descripcion ~= "" and entry.descripcion or "Set completo de transfiguración",
                icon = nil,
                previewType = "itemSet",
                creatureid = nil,
                itemSet = itemSetIds,
                armorType = entry.tipoArmadura,
                displayRace = entry.razaDisplay,
                displayGender = entry.generoDisplay,
                    modelScale = entry.modelScale or 1.0,
                showModel = true
            })

        elseif entry.modo3d and entry.displayId and entry.displayId > 0 then
            for _, itemInfo in ipairs(entry.items) do
                local itemId = itemInfo.itemId
                local count = itemInfo.cantidad
                local itemName = GetItemNameFromDB(itemId) or ("Montura #" .. itemId)

                table.insert(rewards, {
                    type = "creature3D",
                    id = itemId,
                    count = count,
                    name = itemName,
                    description = entry.descripcion ~= "" and entry.descripcion or itemName,
                    icon = nil,
                    previewType = "creature3D",
                    creatureid = entry.displayId,
                    modelScale = entry.modelScale or 1.0,
                    showModel = true,
                    isCreature = true
                })
            end

        else
            for _, itemInfo in ipairs(entry.items) do
                local itemId = itemInfo.itemId
                local count = itemInfo.cantidad
                local itemName = GetItemNameFromDB(itemId) or ("Item #" .. itemId)

                table.insert(rewards, {
                    type = "item",
                    id = itemId,
                    count = count,
                    name = itemName,
                    description = entry.descripcion ~= "" and entry.descripcion or ("x" .. count .. " " .. itemName),
                    icon = nil,
                    previewType = "iconHero",
                    creatureid = nil
                })
            end
        end
    end

    return rewards
end

local function CountPackage3DModels(rewards)
    if not rewards or #rewards == 0 then return 0, 0 end

    local creatureCount = 0
    local charCount = 0

    for _, reward in ipairs(rewards) do
        if reward.previewType == "creature3D" or reward.type == "creature3D" then
            creatureCount = creatureCount + 1
        elseif reward.previewType == "itemSet" or reward.type == "itemSet" then
            charCount = charCount + 1
        end
    end

    return creatureCount, charCount
end

local function ShouldPackageBeFeatured(rewards)
    local creatureCount, charCount = CountPackage3DModels(rewards)

    if creatureCount > 0 and charCount > 0 then
        return true
    end

    if creatureCount >= 2 then
        return true
    end

    if charCount >= 2 then
        return true
    end

    return false
end

local function BuildStoreDB()
    local storeDB = {}
    local rewardsByCategory = {}

    for _, reward in ipairs(StoreCache.rewards) do
        local catId = reward.categoryId
        if not rewardsByCategory[catId] then
            rewardsByCategory[catId] = {packages = {}, products = {}}
        end

        if reward.entryType == "package" then
            local exists = false
            for _, pkg in ipairs(rewardsByCategory[catId].packages) do
                if pkg.id == reward.id then
                    exists = true
                    break
                end
            end

            if not exists then
                local pkg = CloneTable(reward)
                pkg.rewards = BuildPackageRewards(reward.paqueteId)

                if ShouldPackageBeFeatured(pkg.rewards) then
                    pkg.cardType = "featured"
                else
                    pkg.cardType = "grid"
                end

                if not pkg.icon or pkg.icon == "" then
                    pkg.icon = "INV_Misc_Gift_01"
                end

                pkg.bannerTexture = "Interface\\Icons\\" .. pkg.icon
                pkg.heroTexture = pkg.bannerTexture

                table.insert(rewardsByCategory[catId].packages, pkg)
            end
        else
            local prod = CloneTable(reward)
            if prod.icon and prod.icon ~= "" then
                prod.heroTexture = "Interface\\Icons\\" .. prod.icon
                prod.bannerTexture = prod.heroTexture
            end
            table.insert(rewardsByCategory[catId].products, prod)
        end
    end

    for catId, catData in pairs(StoreCache.categories) do
        local catName = catData.name
        local catRewards = rewardsByCategory[catId] or {packages = {}, products = {}}

        storeDB[catName] = {
            layoutType = "featured_grid",
            title = catData.title,
            subtitle = catData.subtitle,
            description = catData.description,
            featured = catRewards.packages[1],
            products = {}
        }

        for i = 2, #catRewards.packages do
            local pkg = catRewards.packages[i]
            table.insert(storeDB[catName].products, pkg)
        end

        for _, prod in ipairs(catRewards.products) do
            prod.cardType = "grid"
            table.insert(storeDB[catName].products, prod)
        end
    end

    return storeDB
end

local function LoadFullCache()
    if CacheLoaded then return end
    LoadCategoriesFromDB()
    LoadRewardsFromDB()
    LoadPaqueteItemsFromDB()
    CacheLoaded = true
end

local function CollectMountCreatureEntries()
    LoadFullCache()
    local set = {}

    for _, entries in pairs(StoreCache.paqueteItems) do
        for _, entry in ipairs(entries) do
            if entry.modo3d and entry.displayId and entry.displayId > 0 and not entry.esSetArmadura then
                set[entry.displayId] = true
            end
        end
    end

    for _, reward in ipairs(StoreCache.rewards) do
        if reward.modo3d and reward.displayId and reward.displayId > 0 then
            set[reward.displayId] = true
        end
    end

    local out = {}
    for entry, _ in pairs(set) do
        table.insert(out, entry)
    end

    return out
end

local function SendCreatureQueryResponse(player, data)
    local packet = CreatePacket(97, 100)
    packet:WriteULong(data[1])
    packet:WriteString(data[2] or "")
    packet:WriteUByte(0)
    packet:WriteUByte(0)
    packet:WriteUByte(0)
    packet:WriteString(data[3] or "")
    packet:WriteString(data[4] or "")
    packet:WriteULong(data[5] or 0)
    packet:WriteULong(data[6] or 0)
    packet:WriteULong(data[7] or 0)
    packet:WriteULong(data[8] or 0)
    packet:WriteULong(data[9] or 0)
    packet:WriteULong(data[10] or 0)
    packet:WriteULong(data[11] or 0)
    packet:WriteULong(data[12] or 0)
    packet:WriteULong(data[13] or 0)
    packet:WriteULong(data[14] or 0)
    packet:WriteFloat(data[15] or 1.0)
    packet:WriteFloat(data[16] or 1.0)
    packet:WriteUByte(data[17] or 0)
    packet:WriteULong(0)
    packet:WriteULong(0)
    packet:WriteULong(0)
    packet:WriteULong(0)
    packet:WriteULong(0)
    packet:WriteULong(0)
    packet:WriteULong(data[18] or 0)
    player:SendPacket(packet)
end

local function LoadCreatureCacheForEntries(entries)
    if not entries or #entries == 0 then return {} end

    local tmp = table.concat(entries, ",")
    local cache = {}
    local core = GetCoreName()
    local query

    if core == "TrinityCore" then
        query = WorldDBQuery("SELECT entry, `name`, subname, IconName, type_flags, `type`, family, `rank`, KillCredit1, KillCredit2, HealthModifier, ManaModifier, RacialLeader, MovementType, modelid1, modelid2, modelid3, modelid4 FROM creature_template WHERE entry IN ("..tmp..");")
    else
        query = WorldDBQuery("SELECT entry, `name`, subname, IconName, type_flags, `type`, family, `rank`, KillCredit1, KillCredit2, HealthModifier, ManaModifier, RacialLeader, MovementType FROM creature_template WHERE entry IN ("..tmp..");")
    end

    if query then
        repeat
            local model1, model2, model3, model4 = 0, 0, 0, 0
            if core == "TrinityCore" then
                model1 = query:GetUInt32(14)
                model2 = query:GetUInt32(15)
                model3 = query:GetUInt32(16)
                model4 = query:GetUInt32(17)
            end
            local entry = query:GetUInt32(0)
            cache[entry] = {
                entry, query:GetString(1), query:GetString(2), query:GetString(3), query:GetUInt32(4), query:GetUInt32(5), query:GetUInt32(6), query:GetUInt32(7), query:GetUInt32(8), query:GetUInt32(9), model1, model2, model3, model4, query:GetFloat(10), query:GetFloat(11), query:GetUInt32(12), query:GetUInt32(13)
            }
        until not query:NextRow()
    end

    if core == "AzerothCore" then
        local modelQuery = WorldDBQuery("SELECT CreatureID, Idx, CreatureDisplayID FROM creature_template_model WHERE CreatureID IN ("..tmp..");")
        if modelQuery then
            repeat
                local entry = modelQuery:GetUInt32(0)
                local idx = modelQuery:GetUInt32(1)
                local displayId = modelQuery:GetUInt32(2)
                if cache[entry] then
                    local key = idx + 11
                    cache[entry][key] = displayId
                end
            until not modelQuery:NextRow()
        end
    end

    return cache
end

local MountCreatureCache = nil

local function EnsureMountCreatureCache()
    if MountCreatureCache then return MountCreatureCache end
    local entries = CollectMountCreatureEntries()
    MountCreatureCache = LoadCreatureCacheForEntries(entries)
    return MountCreatureCache
end

local function SendMountCreatureQueries(player)
    local cache = EnsureMountCreatureCache()
    for entry, data in pairs(cache or {}) do
        SendCreatureQueryResponse(player, data)
    end
end

local function GetCategoryData(categoryName)
    LoadFullCache()
    local storeDB = BuildStoreDB()
    local cat = storeDB[categoryName]
    if not cat then return nil end

    local data = CloneTable(cat)
    data.category = categoryName
    if data.featured then
        data.featured.category = categoryName
    end
    for i, item in ipairs(data.products or {}) do
        item.category = categoryName
        data.products[i] = item
    end
    return data
end

local function FindEntry(categoryName, entryId)
    LoadFullCache()
    local storeDB = BuildStoreDB()
    local cat = storeDB[categoryName]
    entryId = tonumber(entryId) or 0
    if not cat then return nil end

    if cat.featured and tonumber(cat.featured.id) == entryId then
        local row = CloneTable(cat.featured)
        row.category = categoryName
        return row
    end
    for _, item in ipairs(cat.products or {}) do
        if tonumber(item.id) == entryId then
            local row = CloneTable(item)
            row.category = categoryName
            return row
        end
    end
    return nil
end

local function GetCurrencyCount(player)
    return player:GetItemCount(STORE_CURRENCY_ID, false)
end

local function SendCurrency(player)
    AIO.Handle(player, "FelStormStore", "UpdateCurrency", GetCurrencyCount(player), STORE_CURRENCY_ID)
end

local function HandleServiceReward(player, serviceKey)
    local flag = tonumber(serviceKey)
    if not flag or flag <= 0 then
        return false, "Servicio no válido"
    end
    local serviceNames = {
        [1] = "Cambio de Nombre",
        [8] = "Personalización",
        [64] = "Cambio de Facción",
        [128] = "Cambio de Raza"
    }
    local serviceName = serviceNames[flag] or "Servicio"
    player:SetAtLoginFlag(flag)
    return true, serviceName .. " activado. Por favor, reconecta tu personaje."
end

-- REEMPLAZADA: GrantEntryRewards ahora envía al buzón (MODIFICADA)
local function GrantEntryRewards(player, entry)
    local success, result = pcall(function()
        if not entry then
            return false, "Entrada inválida"
        end

        -- Servicios siguen siendo instantáneos
        if entry.service and entry.serviceKey then
            return HandleServiceReward(player, entry.serviceKey)
        end

        -- Items y paquetes van al buzón
        local attachments = BuildGiftAttachmentsFromEntry(entry)
        if not attachments or #attachments == 0 then
            return false, "No hay objetos válidos para enviar"
        end

        local okMail, mailErr = SendPurchaseAttachments(
            player:GetGUIDLow(),
            entry.name or "Compra",
            attachments
        )

        if not okMail then
            return false, "No se pudo enviar la compra por correo: " .. tostring(mailErr)
        end

        if entry.entryType == "package" then
    return true, "Paquete comprado con éxito. Revisa tu buzón."
end

return true, "Compra realizada con éxito. Revisa tu buzón."
    end)

    if not success then
        return false, "Error interno: " .. tostring(result)
    end

    return result
end

local function OpenStore(player)
    SendMountCreatureQueries(player)
    AIO.Handle(player, "FelStormStore", "ShowStore")
    SendCurrency(player)

    local firstCategory = "Destacado"
    for id, cat in pairs(StoreCache.categories) do
        if id == 1 then
            firstCategory = cat.name
            break
        end
    end

    local data = GetCategoryData(firstCategory)
    AIO.Handle(player, "FelStormStore", "LoadCategory", data, firstCategory)

    if data and data.featured then
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", data.featured)
    elseif data and data.products and data.products[1] then
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", data.products[1])
    else
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", nil)
    end
end

function StoreHandlers.RequestCategory(player, categoryName)
    LoadFullCache()
    categoryName = tostring(categoryName or "Destacado")

    local exists = false
    for _, cat in pairs(StoreCache.categories) do
        if cat.name == categoryName then
            exists = true
            break
        end
    end

    if not exists then
        categoryName = "Destacado"
    end

    local data = GetCategoryData(categoryName)
    AIO.Handle(player, "FelStormStore", "LoadCategory", data, categoryName)

    if data and data.featured then
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", data.featured)
    elseif data and data.products and data.products[1] then
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", data.products[1])
    else
        AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", nil)
    end
    SendCurrency(player)
end

function StoreHandlers.RequestSelectedItem(player, categoryName, itemId)
    LoadFullCache()
    categoryName = tostring(categoryName or "Destacado")
    SendMountCreatureQueries(player)
    local entry = FindEntry(categoryName, itemId)
    AIO.Handle(player, "FelStormStore", "ReceiveSelectedItem", entry)
end

local pendingPurchases = {}
local pendingGifts = {}

-- REEMPLAZADA: BuyItemRequest sin chequeo de bolsas (MODIFICADA)
function StoreHandlers.BuyItemRequest(player, categoryName, itemId)
    local playerGuid = player:GetGUIDLow()
    local purchaseKey = playerGuid .. "_" .. tostring(itemId)

    if pendingPurchases[purchaseKey] then
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, "Compra en progreso, por favor espera")
        return
    end

    pendingPurchases[purchaseKey] = true

    LoadFullCache()
    categoryName = tostring(categoryName or "Destacado")
    local entry = FindEntry(categoryName, itemId)

    if not entry then
        pendingPurchases[purchaseKey] = nil
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, "Entrada inválida")
        return
    end

    local price = tonumber(entry.price) or 0

    if price <= 0 then
        pendingPurchases[purchaseKey] = nil
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, "Precio inválido")
        return
    end

    local balance = GetCurrencyCount(player)

    if balance < price then
        pendingPurchases[purchaseKey] = nil
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, "No tienes suficientes Emblemas")
        return
    end

    -- ELIMINADO: Chequeo de espacio en bolsas - ya no es necesario porque va al correo

    local okPay, errPay = pcall(function()
        player:RemoveItem(STORE_CURRENCY_ID, price)
    end)

    if not okPay then
        pendingPurchases[purchaseKey] = nil
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, "Error al procesar pago")
        return
    end

    local okReward, msg = GrantEntryRewards(player, entry)

    if not okReward then
        player:AddItem(STORE_CURRENCY_ID, price)
        pendingPurchases[purchaseKey] = nil
        AIO.Handle(player, "FelStormStore", "BuyResponse", false, msg or "No se pudo completar la compra")
        return
    end

    AIO.Handle(player, "FelStormStore", "BuyResponse", true, msg or "Compra realizada con éxito. El artículo fue enviado a tu buzón.")
    SendCurrency(player)
    SendMountCreatureQueries(player)

    CreateLuaEvent(function()
        pendingPurchases[purchaseKey] = nil
    end, 3000, 1)
end

function StoreHandlers.GiftItemRequest(player, categoryName, itemId, targetName)
    LoadFullCache()

    categoryName = tostring(categoryName or "Destacado")
    targetName = NormalizeCharacterName(targetName)

    if targetName == "" then
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Debes escribir el nombre del personaje destino.")
        return
    end

    if string.len(targetName) < 2 or string.len(targetName) > 12 then
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Nombre de personaje inválido.")
        return
    end

    local giftKey = player:GetGUIDLow() .. "_" .. tostring(itemId) .. "_" .. targetName
    if pendingGifts[giftKey] then
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Regalo en progreso, por favor espera.")
        return
    end

    pendingGifts[giftKey] = true

    local entry = FindEntry(categoryName, itemId)
    if not entry then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Entrada inválida")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Entrada inválida.")
        return
    end

    if entry.service then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Intento de regalar servicio")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Los servicios no se pueden regalar.")
        return
    end

    local receiver = FindCharacterByName(targetName)
    if not receiver then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Personaje destino no existe")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "El personaje destino no existe.")
        return
    end

    if receiver.guid == player:GetGUIDLow() then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Intento de autoregalo")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Usa Comprar si quieres obtenerlo para tu propio personaje.")
        return
    end

    local price = tonumber(entry.price) or 0
    if price <= 0 then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Precio inválido")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Precio inválido.")
        return
    end

    local balance = GetCurrencyCount(player)
    if balance < price then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Saldo insuficiente")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "No tienes suficientes Emblemas.")
        return
    end

    local attachments = BuildGiftAttachmentsFromEntry(entry)
    if not attachments or #attachments == 0 then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Sin adjuntos válidos")
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "No hay objetos válidos para regalar.")
        return
    end

    local okPay, errPay = pcall(function()
        player:RemoveItem(STORE_CURRENCY_ID, price)
    end)

    if not okPay then
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, entryId, "Error al descontar moneda: " .. tostring(errPay))
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "Error al procesar el pago.")
        return
    end

    local okMail, mailErr = SendGiftAttachments(receiver.guid, player:GetName(), entry.name or "Regalo", attachments)
    if not okMail then
        print("[FelStorm Store][GiftMailError] " .. tostring(mailErr))
        player:AddItem(STORE_CURRENCY_ID, price)
        pendingGifts[giftKey] = nil
        LogGiftError(player, targetName, categoryName, itemId, "Error al enviar correo: " .. tostring(mailErr))
        AIO.Handle(player, "FelStormStore", "GiftResponse", false, "No se pudo enviar el regalo por correo.")
        return
    end

    LogGiftSuccess(player, receiver, categoryName, entry)
    SendCurrency(player)
    AIO.Handle(player, "FelStormStore", "GiftResponse", true, "Regalo enviado con éxito a " .. receiver.name .. ".")

    CreateLuaEvent(function()
        pendingGifts[giftKey] = nil
    end, 3000, 1)
end

function StoreHandlers.RequestOpenStore(player)
    LoadFullCache()
    OpenStore(player)
end

LoadFullCache()