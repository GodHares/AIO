local AIO = AIO or require("AIO")
local QuestCreator = AIO.AddHandlers("QuestCreator", {})

-- =========================================================
-- QuestCreator Server
-- AzerothCore WotLK 3.3.5 + Eluna + AIO
-- VERSION: QUESTCREATOR-V3-FULL-SCHEMA-2026-05-08
-- =========================================================

local Config = {
    RequiredGmRank = 3,

    CustomQuestMinId = 7000,
    CustomQuestMaxId = 999999,

    BrowserQuestMinId = 1,
    BrowserQuestMaxId = 999999,

    ListPageSize = 20,

    AllowDeleteOutsideCustomRange = false,
    DefaultVerifiedBuild = 12340,
    DebugList = true
}

local TableColumnCache = {}
local SchemaCache = nil

-- =========================================================
-- Schema fields
-- =========================================================

local QT_FIELDS = {
    { key = "questType", col = "QuestType", type = "num", default = 2 },
    { key = "questLevel", col = "QuestLevel", type = "num", default = 1 },
    { key = "minLevel", col = "MinLevel", type = "num", default = 1 },
    { key = "questSortId", col = "QuestSortID", type = "num", default = 0 },
    { key = "questInfoId", col = "QuestInfoID", type = "num", default = 0 },
    { key = "suggestedGroupNum", col = "SuggestedGroupNum", type = "num", default = 0 },

    { key = "requiredFactionId1", col = "RequiredFactionId1", type = "num", default = 0 },
    { key = "requiredFactionId2", col = "RequiredFactionId2", type = "num", default = 0 },
    { key = "requiredFactionValue1", col = "RequiredFactionValue1", type = "num", default = 0 },
    { key = "requiredFactionValue2", col = "RequiredFactionValue2", type = "num", default = 0 },

    { key = "rewardNextQuest", col = "RewardNextQuest", type = "num", default = 0 },
    { key = "rewardXpDifficulty", col = "RewardXPDifficulty", type = "num", default = 5 },
    { key = "rewardMoney", col = "RewardMoney", type = "num", default = 0 },
    { key = "rewardMoneyDifficulty", col = "RewardMoneyDifficulty", type = "num", default = 0 },
    { key = "rewardDisplaySpell", col = "RewardDisplaySpell", type = "num", default = 0 },
    { key = "rewardSpell", col = "RewardSpell", type = "num", default = 0 },
    { key = "rewardHonor", col = "RewardHonor", type = "num", default = 0 },
    { key = "rewardKillHonor", col = "RewardKillHonor", type = "num", default = 0 },

    { key = "startItem", col = "StartItem", type = "num", default = 0 },
    { key = "flags", col = "Flags", type = "num", default = 8 },
    { key = "requiredPlayerKills", col = "RequiredPlayerKills", type = "num", default = 0 },

    { key = "rewardItem1", col = "RewardItem1", type = "num", default = 0 },
    { key = "rewardAmount1", col = "RewardAmount1", type = "num", default = 0 },
    { key = "rewardItem2", col = "RewardItem2", type = "num", default = 0 },
    { key = "rewardAmount2", col = "RewardAmount2", type = "num", default = 0 },
    { key = "rewardItem3", col = "RewardItem3", type = "num", default = 0 },
    { key = "rewardAmount3", col = "RewardAmount3", type = "num", default = 0 },
    { key = "rewardItem4", col = "RewardItem4", type = "num", default = 0 },
    { key = "rewardAmount4", col = "RewardAmount4", type = "num", default = 0 },

    { key = "itemDrop1", col = "ItemDrop1", type = "num", default = 0 },
    { key = "itemDropQuantity1", col = "ItemDropQuantity1", type = "num", default = 0 },
    { key = "itemDrop2", col = "ItemDrop2", type = "num", default = 0 },
    { key = "itemDropQuantity2", col = "ItemDropQuantity2", type = "num", default = 0 },
    { key = "itemDrop3", col = "ItemDrop3", type = "num", default = 0 },
    { key = "itemDropQuantity3", col = "ItemDropQuantity3", type = "num", default = 0 },
    { key = "itemDrop4", col = "ItemDrop4", type = "num", default = 0 },
    { key = "itemDropQuantity4", col = "ItemDropQuantity4", type = "num", default = 0 },

    { key = "rewardChoiceItemId1", col = "RewardChoiceItemID1", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity1", col = "RewardChoiceItemQuantity1", type = "num", default = 0 },
    { key = "rewardChoiceItemId2", col = "RewardChoiceItemID2", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity2", col = "RewardChoiceItemQuantity2", type = "num", default = 0 },
    { key = "rewardChoiceItemId3", col = "RewardChoiceItemID3", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity3", col = "RewardChoiceItemQuantity3", type = "num", default = 0 },
    { key = "rewardChoiceItemId4", col = "RewardChoiceItemID4", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity4", col = "RewardChoiceItemQuantity4", type = "num", default = 0 },
    { key = "rewardChoiceItemId5", col = "RewardChoiceItemID5", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity5", col = "RewardChoiceItemQuantity5", type = "num", default = 0 },
    { key = "rewardChoiceItemId6", col = "RewardChoiceItemID6", type = "num", default = 0 },
    { key = "rewardChoiceItemQuantity6", col = "RewardChoiceItemQuantity6", type = "num", default = 0 },

    { key = "poiContinent", col = "POIContinent", type = "num", default = 0 },
    { key = "poiX", col = "POIx", type = "num", default = 0 },
    { key = "poiY", col = "POIy", type = "num", default = 0 },
    { key = "poiPriority", col = "POIPriority", type = "num", default = 0 },

    { key = "rewardTitle", col = "RewardTitle", type = "num", default = 0 },
    { key = "rewardTalents", col = "RewardTalents", type = "num", default = 0 },
    { key = "rewardArenaPoints", col = "RewardArenaPoints", type = "num", default = 0 },

    { key = "rewardFactionId1", col = "RewardFactionID1", type = "num", default = 0 },
    { key = "rewardFactionValue1", col = "RewardFactionValue1", type = "num", default = 0 },
    { key = "rewardFactionOverride1", col = "RewardFactionOverride1", type = "num", default = 0 },
    { key = "rewardFactionId2", col = "RewardFactionID2", type = "num", default = 0 },
    { key = "rewardFactionValue2", col = "RewardFactionValue2", type = "num", default = 0 },
    { key = "rewardFactionOverride2", col = "RewardFactionOverride2", type = "num", default = 0 },
    { key = "rewardFactionId3", col = "RewardFactionID3", type = "num", default = 0 },
    { key = "rewardFactionValue3", col = "RewardFactionValue3", type = "num", default = 0 },
    { key = "rewardFactionOverride3", col = "RewardFactionOverride3", type = "num", default = 0 },
    { key = "rewardFactionId4", col = "RewardFactionID4", type = "num", default = 0 },
    { key = "rewardFactionValue4", col = "RewardFactionValue4", type = "num", default = 0 },
    { key = "rewardFactionOverride4", col = "RewardFactionOverride4", type = "num", default = 0 },
    { key = "rewardFactionId5", col = "RewardFactionID5", type = "num", default = 0 },
    { key = "rewardFactionValue5", col = "RewardFactionValue5", type = "num", default = 0 },
    { key = "rewardFactionOverride5", col = "RewardFactionOverride5", type = "num", default = 0 },

    { key = "timeAllowed", col = "TimeAllowed", type = "num", default = 0 },
    { key = "allowableRaces", col = "AllowableRaces", type = "num", default = 0 },

    { key = "logDescription", col = "LogDescription", type = "str", default = "" },
    { key = "questDescription", col = "QuestDescription", type = "str", default = "" },
    { key = "areaDescription", col = "AreaDescription", type = "str", default = "" },
    { key = "completionLog", col = "QuestCompletionLog", type = "str", default = "" },

    { key = "requiredNpcOrGo1", col = "RequiredNpcOrGo1", type = "num", default = 0 },
    { key = "requiredNpcOrGo2", col = "RequiredNpcOrGo2", type = "num", default = 0 },
    { key = "requiredNpcOrGo3", col = "RequiredNpcOrGo3", type = "num", default = 0 },
    { key = "requiredNpcOrGo4", col = "RequiredNpcOrGo4", type = "num", default = 0 },
    { key = "requiredNpcOrGoCount1", col = "RequiredNpcOrGoCount1", type = "num", default = 0 },
    { key = "requiredNpcOrGoCount2", col = "RequiredNpcOrGoCount2", type = "num", default = 0 },
    { key = "requiredNpcOrGoCount3", col = "RequiredNpcOrGoCount3", type = "num", default = 0 },
    { key = "requiredNpcOrGoCount4", col = "RequiredNpcOrGoCount4", type = "num", default = 0 },

    { key = "requiredItemId1", col = "RequiredItemId1", type = "num", default = 0 },
    { key = "requiredItemId2", col = "RequiredItemId2", type = "num", default = 0 },
    { key = "requiredItemId3", col = "RequiredItemId3", type = "num", default = 0 },
    { key = "requiredItemId4", col = "RequiredItemId4", type = "num", default = 0 },
    { key = "requiredItemId5", col = "RequiredItemId5", type = "num", default = 0 },
    { key = "requiredItemId6", col = "RequiredItemId6", type = "num", default = 0 },
    { key = "requiredItemCount1", col = "RequiredItemCount1", type = "num", default = 0 },
    { key = "requiredItemCount2", col = "RequiredItemCount2", type = "num", default = 0 },
    { key = "requiredItemCount3", col = "RequiredItemCount3", type = "num", default = 0 },
    { key = "requiredItemCount4", col = "RequiredItemCount4", type = "num", default = 0 },
    { key = "requiredItemCount5", col = "RequiredItemCount5", type = "num", default = 0 },
    { key = "requiredItemCount6", col = "RequiredItemCount6", type = "num", default = 0 },

    { key = "unknown0", col = "Unknown0", type = "num", default = 0 },
    { key = "objectiveText1", col = "ObjectiveText1", type = "str", default = "" },
    { key = "objectiveText2", col = "ObjectiveText2", type = "str", default = "" },
    { key = "objectiveText3", col = "ObjectiveText3", type = "str", default = "" },
    { key = "objectiveText4", col = "ObjectiveText4", type = "str", default = "" },

    { key = "verifiedBuild", col = "VerifiedBuild", type = "num", default = 12340 }
}

local ADDON_FIELDS = {
    { key = "maxLevel", col = "MaxLevel", type = "num", default = 0 },
    { key = "allowableClasses", col = "AllowableClasses", type = "num", default = 0 },
    { key = "sourceSpellId", col = "SourceSpellID", type = "num", default = 0 },
    { key = "prevQuestId", col = "PrevQuestID", type = "num", default = 0 },
    { key = "nextQuestId", col = "NextQuestID", type = "num", default = 0 },
    { key = "exclusiveGroup", col = "ExclusiveGroup", type = "num", default = 0 },
    { key = "rewardMailTemplateId", col = "RewardMailTemplateID", type = "num", default = 0 },
    { key = "rewardMailDelay", col = "RewardMailDelay", type = "num", default = 0 },
    { key = "requiredSkillId", col = "RequiredSkillID", type = "num", default = 0 },
    { key = "requiredSkillPoints", col = "RequiredSkillPoints", type = "num", default = 0 },
    { key = "requiredMinRepFaction", col = "RequiredMinRepFaction", type = "num", default = 0 },
    { key = "requiredMaxRepFaction", col = "RequiredMaxRepFaction", type = "num", default = 0 },
    { key = "requiredMinRepValue", col = "RequiredMinRepValue", type = "num", default = 0 },
    { key = "requiredMaxRepValue", col = "RequiredMaxRepValue", type = "num", default = 0 },
    { key = "providedItemCount", col = "ProvidedItemCount", type = "num", default = 0 },
    { key = "specialFlags", col = "SpecialFlags", type = "num", default = 0 }
}

local REQUEST_FIELDS = {
    { key = "emoteOnComplete", col = "EmoteOnComplete", type = "num", default = 1 },
    { key = "emoteOnIncomplete", col = "EmoteOnIncomplete", type = "num", default = 0 },
    { key = "completionText", col = "CompletionText", type = "str", default = "" },
    { key = "requestVerifiedBuild", col = "VerifiedBuild", type = "num", default = 12340 }
}

local OFFER_FIELDS = {
    { key = "rewardEmote1", col = "Emote1", type = "num", default = 0 },
    { key = "rewardEmote2", col = "Emote2", type = "num", default = 0 },
    { key = "rewardEmote3", col = "Emote3", type = "num", default = 0 },
    { key = "rewardEmote4", col = "Emote4", type = "num", default = 0 },
    { key = "rewardEmoteDelay1", col = "EmoteDelay1", type = "num", default = 0 },
    { key = "rewardEmoteDelay2", col = "EmoteDelay2", type = "num", default = 0 },
    { key = "rewardEmoteDelay3", col = "EmoteDelay3", type = "num", default = 0 },
    { key = "rewardEmoteDelay4", col = "EmoteDelay4", type = "num", default = 0 },
    { key = "rewardText", col = "RewardText", type = "str", default = "" },
    { key = "offerVerifiedBuild", col = "VerifiedBuild", type = "num", default = 12340 }
}

-- =========================================================
-- Utility
-- =========================================================

local function Debug(player, msg)
    if Config.DebugList and player then
        player:SendBroadcastMessage("|cff33ccffQuestCreator Debug:|r " .. tostring(msg))
    end
end

local function ToNumber(value, default)
    local n = tonumber(value)
    if n == nil then
        return default or 0
    end
    return math.floor(n)
end

local function EscapeString(value)
    if value == nil then
        return ""
    end

    value = tostring(value)
    value = value:gsub("\\", "\\\\")
    value = value:gsub("'", "\\'")
    value = value:gsub("\0", "")
    value = value:gsub("\r", "\\r")
    value = value:gsub("\n", "\\n")
    return value
end

local function SqlString(value)
    return "'" .. EscapeString(value) .. "'"
end

local function SqlNumber(value, default)
    return tostring(ToNumber(value, default or 0))
end

local function HasPermission(player)
    return player and player:GetGMRank() >= Config.RequiredGmRank
end

-- Recarga todas las tablas relacionadas con quests en el worldserver.
local function ReloadQuestTables(player)
    local tables = {
        "quest_template",
        "quest_template_addon",
        "quest_template_locale",
        "quest_request_items_locale",
        "quest_poi",
        "quest_offer_reward_locale",
        "quest_greeting",
        "creature_questender",
        "creature_queststarter",
    }

    if RunCommand then
        local allOk = true
        for _, tbl in ipairs(tables) do
            local ok = pcall(function() RunCommand("reload " .. tbl) end)
            if not ok then allOk = false end
        end

        if allOk then
            player:SendBroadcastMessage(
                "|cff33ff33[QuestCreator]|r Tablas recargadas correctamente.")
        else
            player:SendBroadcastMessage(
                "|cffffaa00[QuestCreator]|r Algunas tablas no pudieron recargarse, revisa la consola.")
        end
        return allOk
    end

    -- Fallback: instrucciones manuales
    player:SendBroadcastMessage("|cffffaa00[QuestCreator]|r RunCommand no disponible. Recarga manual:")
    for _, tbl in ipairs(tables) do
        player:SendBroadcastMessage("|cffffffff.reload " .. tbl .. "|r")
    end
    return false
end

local function SafeQuery(sql)
    local ok, result = pcall(function()
        return WorldDBQuery(sql)
    end)

    if not ok then
        return nil, result
    end

    return result, nil
end

local function SafeExecute(sql)
    local ok, err = pcall(function()
        WorldDBExecute(sql)
    end)

    return ok, err
end

local function QueryExists(sql)
    return WorldDBQuery(sql) ~= nil
end

local function TableExists(tableName)
    return QueryExists("SHOW TABLES LIKE '" .. EscapeString(tableName) .. "'")
end

local function TableHasColumn(tableName, columnName)
    if not TableColumnCache[tableName] then
        TableColumnCache[tableName] = {}

        local result = WorldDBQuery("SHOW COLUMNS FROM `" .. EscapeString(tableName) .. "`")
        if result then
            repeat
                TableColumnCache[tableName][result:GetString(0)] = true
            until not result:NextRow()
        end
    end

    return TableColumnCache[tableName][columnName] == true
end

local function DetectSchema()
    if SchemaCache then
        return SchemaCache
    end

    local idColumn = "ID"
    local titleColumn = "LogTitle"

    if not TableHasColumn("quest_template", "ID") and TableHasColumn("quest_template", "entry") then
        idColumn = "entry"
    end

    if not TableHasColumn("quest_template", "LogTitle") and TableHasColumn("quest_template", "Title") then
        titleColumn = "Title"
    end

    SchemaCache = {
        questId = idColumn,
        questTitle = titleColumn,
        hasQuestTemplateAddon = TableExists("quest_template_addon"),
        hasQuestOfferReward = TableExists("quest_offer_reward"),
        hasQuestRequestItems = TableExists("quest_request_items")
    }

    return SchemaCache
end

local function QT_ID()
    return DetectSchema().questId
end

local function QT_TITLE()
    return DetectSchema().questTitle
end

local function QuestExists(questId)
    return QueryExists("SELECT 1 FROM quest_template WHERE `" .. QT_ID() .. "` = " .. SqlNumber(questId) .. " LIMIT 1")
end

local function CreatureExists(entry)
    return QueryExists("SELECT 1 FROM creature_template WHERE entry = " .. SqlNumber(entry) .. " LIMIT 1")
end

local function GameObjectExists(entry)
    return QueryExists("SELECT 1 FROM gameobject_template WHERE entry = " .. SqlNumber(entry) .. " LIMIT 1")
end

local function ItemExists(entry)
    return QueryExists("SELECT 1 FROM item_template WHERE entry = " .. SqlNumber(entry) .. " LIMIT 1")
end

local function HexEncode(value)
    value = tostring(value or "")
    local out = {}

    for i = 1, string.len(value) do
        out[#out + 1] = string.format("%02X", string.byte(value, i))
    end

    return table.concat(out, "")
end

local function SqlValueByType(value, fieldType)
    if fieldType == "str" then
        return SqlString(value or "")
    end

    return SqlNumber(value, 0)
end

local function BuildReplaceSql(tableName, values)
    local columns = {}
    local sqlValues = {}

    for column, value in pairs(values) do
        if TableHasColumn(tableName, column) then
            columns[#columns + 1] = "`" .. column .. "`"
            sqlValues[#sqlValues + 1] = value
        end
    end

    if #columns == 0 then
        return nil
    end

    return string.format(
        "REPLACE INTO `%s` (%s) VALUES (%s)",
        tableName,
        table.concat(columns, ", "),
        table.concat(sqlValues, ", ")
    )
end

local function ExecuteSql(sql)
    if not sql or sql == "" then
        return true
    end

    return SafeExecute(sql)
end

local function GetQuestStats()
    local idCol = QT_ID()

    local result = WorldDBQuery(string.format(
        "SELECT COUNT(*), MIN(`%s`), MAX(`%s`) FROM quest_template",
        idCol,
        idCol
    ))

    if not result then
        return { count = 0, minId = 0, maxId = 0 }
    end

    return {
        count = result:GetUInt32(0),
        minId = result:GetUInt32(1),
        maxId = result:GetUInt32(2)
    }
end

-- =========================================================
-- Stream List
-- =========================================================

local function SendQuestListStream(player, direction, startId, quests)
    Debug(player, "V3 STREAM-LIST server activo.")
    Debug(player, "quests stream = " .. tostring(#quests))

    AIO.Handle(
        player,
        "QuestCreator",
        "BeginQuestListStream",
        tostring(direction or "forward"),
        tostring(startId or 1),
        tostring(Config.ListPageSize),
        tostring(#quests)
    )

    for _, quest in ipairs(quests) do
        AIO.Handle(
            player,
            "QuestCreator",
            "AddQuestListRow",
            tostring(quest.id or 0),
            HexEncode(quest.title or ""),
            tostring(quest.level or 0),
            tostring(quest.minLevel or 0),
            tostring(quest.sortId or 0),
            tostring(quest.rewardNextQuest or 0)
        )
    end

    AIO.Handle(
        player,
        "QuestCreator",
        "EndQuestListStream",
        tostring(direction or "forward"),
        tostring(startId or 1),
        tostring(#quests)
    )
end

-- =========================================================
-- Normalize
-- =========================================================

local function NormalizeFieldGroup(quest, raw, defs)
    for _, def in ipairs(defs) do
        if def.type == "str" then
            quest[def.key] = tostring(raw[def.key] or def.default or "")
        else
            quest[def.key] = ToNumber(raw[def.key], def.default or 0)
        end
    end
end

local function NormalizePairRows(quest, raw, tableName, entryPrefix, countPrefix, slots)
    if type(raw[tableName]) ~= "table" then
        return
    end

    for i = 1, slots do
        local row = raw[tableName][i] or {}
        quest[entryPrefix .. i] = ToNumber(row.entry, 0)
        quest[countPrefix .. i] = ToNumber(row.count, 0)
    end
end

local function NormalizeRewardFactions(quest, raw)
    if type(raw.rewardFactions) ~= "table" then
        return
    end

    for i = 1, 5 do
        local row = raw.rewardFactions[i] or {}
        quest["rewardFactionId" .. i] = ToNumber(row.faction, 0)
        quest["rewardFactionValue" .. i] = ToNumber(row.value, 0)
        quest["rewardFactionOverride" .. i] = ToNumber(row.override, 0)
    end
end

local function NormalizeObjectiveTexts(quest, raw)
    if type(raw.objectiveTexts) ~= "table" then
        return
    end

    for i = 1, 4 do
        quest["objectiveText" .. i] = tostring(raw.objectiveTexts[i] or "")
    end
end

local function NormalizeQuest(raw)
    raw = raw or {}

    local quest = {
        id = ToNumber(raw.id, 0),
        title = tostring(raw.title or "")
    }

    NormalizeFieldGroup(quest, raw, QT_FIELDS)
    NormalizeFieldGroup(quest, raw, ADDON_FIELDS)
    NormalizeFieldGroup(quest, raw, REQUEST_FIELDS)
    NormalizeFieldGroup(quest, raw, OFFER_FIELDS)

    NormalizePairRows(quest, raw, "requiredNpcOrGo", "requiredNpcOrGo", "requiredNpcOrGoCount", 4)
    NormalizePairRows(quest, raw, "requiredItems", "requiredItemId", "requiredItemCount", 6)
    NormalizePairRows(quest, raw, "rewardItems", "rewardItem", "rewardAmount", 4)
    NormalizePairRows(quest, raw, "rewardChoiceItems", "rewardChoiceItemId", "rewardChoiceItemQuantity", 6)
    NormalizePairRows(quest, raw, "itemDrops", "itemDrop", "itemDropQuantity", 4)
    NormalizeRewardFactions(quest, raw)
    NormalizeObjectiveTexts(quest, raw)

    quest.starter = {
        type = "creature",
        entry = 0
    }

    if type(raw.starter) == "table" then
        quest.starter.type = tostring(raw.starter.type or "creature")
        quest.starter.entry = ToNumber(raw.starter.entry, 0)
    end

    quest.ender = {
        type = "creature",
        entry = 0
    }

    if type(raw.ender) == "table" then
        quest.ender.type = tostring(raw.ender.type or "creature")
        quest.ender.entry = ToNumber(raw.ender.entry, 0)
    end

    return quest
end

local function BuildQuestPayloadList(payload)
    local quests = {}

    if type(payload) ~= "table" then
        return quests
    end

    if type(payload.quests) == "table" then
        for _, rawQuest in ipairs(payload.quests) do
            quests[#quests + 1] = NormalizeQuest(rawQuest)
        end
    else
        quests[#quests + 1] = NormalizeQuest(payload)
    end

    if payload.chainMode == "linear" then
        for i, quest in ipairs(quests) do
            local previousQuest = quests[i - 1]
            local nextQuest = quests[i + 1]

            quest.prevQuestId = previousQuest and previousQuest.id or 0

            if nextQuest then
                quest.nextQuestId = nextQuest.id
                quest.rewardNextQuest = nextQuest.id
            else
                quest.nextQuestId = 0
                quest.rewardNextQuest = 0
            end
        end
    end

    return quests
end

-- =========================================================
-- Validation
-- =========================================================

local function ValidateQuest(quest)
    local errors = {}

    if quest.id < Config.CustomQuestMinId or quest.id > Config.CustomQuestMaxId then
        errors[#errors + 1] = "Quest " .. quest.id .. ": ID fuera del rango custom permitido."
    end

    if quest.title == "" then
        errors[#errors + 1] = "Quest " .. quest.id .. ": falta título."
    end

    if quest.logDescription == "" then
        errors[#errors + 1] = "Quest " .. quest.id .. ": falta LogDescription."
    end

    if quest.questDescription == "" then
        errors[#errors + 1] = "Quest " .. quest.id .. ": falta QuestDescription."
    end

    if quest.minLevel < 1 then
        errors[#errors + 1] = "Quest " .. quest.id .. ": MinLevel inválido."
    end

    if quest.starter.entry > 0 then
        if quest.starter.type == "creature" and not CreatureExists(quest.starter.entry) then
            errors[#errors + 1] = "Quest " .. quest.id .. ": starter NPC no existe: " .. quest.starter.entry
        elseif quest.starter.type == "gameobject" and not GameObjectExists(quest.starter.entry) then
            errors[#errors + 1] = "Quest " .. quest.id .. ": starter GO no existe: " .. quest.starter.entry
        end
    end

    if quest.ender.entry > 0 then
        if quest.ender.type == "creature" and not CreatureExists(quest.ender.entry) then
            errors[#errors + 1] = "Quest " .. quest.id .. ": ender NPC no existe: " .. quest.ender.entry
        elseif quest.ender.type == "gameobject" and not GameObjectExists(quest.ender.entry) then
            errors[#errors + 1] = "Quest " .. quest.id .. ": ender GO no existe: " .. quest.ender.entry
        end
    end

    for i = 1, 6 do
        local itemId = quest["requiredItemId" .. i]
        local count = quest["requiredItemCount" .. i]

        if itemId and itemId > 0 then
            if count <= 0 then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RequiredItem" .. i .. " necesita cantidad."
            end

            if not ItemExists(itemId) then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RequiredItem" .. i .. " no existe: " .. itemId
            end
        end
    end

    for i = 1, 4 do
        local itemId = quest["rewardItem" .. i]
        local count = quest["rewardAmount" .. i]

        if itemId and itemId > 0 then
            if count <= 0 then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RewardItem" .. i .. " necesita cantidad."
            end

            if not ItemExists(itemId) then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RewardItem" .. i .. " no existe: " .. itemId
            end
        end
    end

    for i = 1, 6 do
        local itemId = quest["rewardChoiceItemId" .. i]
        local count = quest["rewardChoiceItemQuantity" .. i]

        if itemId and itemId > 0 then
            if count <= 0 then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RewardChoiceItem" .. i .. " necesita cantidad."
            end

            if not ItemExists(itemId) then
                errors[#errors + 1] = "Quest " .. quest.id .. ": RewardChoiceItem" .. i .. " no existe: " .. itemId
            end
        end
    end

    return errors
end

local function ValidateQuestList(quests)
    local errors = {}
    local seen = {}

    for _, quest in ipairs(quests) do
        if seen[quest.id] then
            errors[#errors + 1] = "ID duplicado en payload: " .. quest.id
        end

        seen[quest.id] = true

        local questErrors = ValidateQuest(quest)
        for _, err in ipairs(questErrors) do
            errors[#errors + 1] = err
        end
    end

    return errors
end

-- =========================================================
-- Save
-- =========================================================

local function BuildValuesFromDefs(quest, defs)
    local values = {}

    for _, def in ipairs(defs) do
        values[def.col] = SqlValueByType(quest[def.key], def.type)
    end

    return values
end

local function BuildQuestTemplateValues(quest)
    local values = BuildValuesFromDefs(quest, QT_FIELDS)
    values[QT_ID()] = SqlNumber(quest.id)
    values[QT_TITLE()] = SqlString(quest.title)
    return values
end

local function BuildQuestAddonValues(quest)
    local values = BuildValuesFromDefs(quest, ADDON_FIELDS)
    values.ID = SqlNumber(quest.id)
    return values
end

local function BuildQuestRequestItemsValues(quest)
    local values = BuildValuesFromDefs(quest, REQUEST_FIELDS)
    values.ID = SqlNumber(quest.id)
    return values
end

local function BuildQuestOfferRewardValues(quest)
    local values = BuildValuesFromDefs(quest, OFFER_FIELDS)
    values.ID = SqlNumber(quest.id)
    return values
end

local function SaveTable(tableName, values)
    if not TableExists(tableName) then
        return true
    end

    local sql = BuildReplaceSql(tableName, values)
    return ExecuteSql(sql)
end

local function ClearQuestRelations(questId)
    WorldDBExecute("DELETE FROM creature_queststarter WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM creature_questender WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM gameobject_queststarter WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM gameobject_questender WHERE quest = " .. questId)
end

local function SaveStarter(quest)
    if quest.starter.entry <= 0 or quest.starter.type == "none" then
        return true
    end

    if quest.starter.type == "creature" then
        return ExecuteSql(string.format(
            "INSERT INTO creature_queststarter (`id`, `quest`) VALUES (%d, %d)",
            quest.starter.entry,
            quest.id
        ))
    end

    if quest.starter.type == "gameobject" then
        return ExecuteSql(string.format(
            "INSERT INTO gameobject_queststarter (`id`, `quest`) VALUES (%d, %d)",
            quest.starter.entry,
            quest.id
        ))
    end

    return false, "Starter type inválido."
end

local function SaveEnder(quest)
    if quest.ender.entry <= 0 or quest.ender.type == "none" then
        return true
    end

    if quest.ender.type == "creature" then
        return ExecuteSql(string.format(
            "INSERT INTO creature_questender (`id`, `quest`) VALUES (%d, %d)",
            quest.ender.entry,
            quest.id
        ))
    end

    if quest.ender.type == "gameobject" then
        return ExecuteSql(string.format(
            "INSERT INTO gameobject_questender (`id`, `quest`) VALUES (%d, %d)",
            quest.ender.entry,
            quest.id
        ))
    end

    return false, "Ender type inválido."
end

local function SaveSingleQuest(quest)
    local ok, err

    ClearQuestRelations(quest.id)

    ok, err = SaveTable("quest_template", BuildQuestTemplateValues(quest))
    if not ok then return false, "quest_template: " .. tostring(err) end

    ok, err = SaveTable("quest_template_addon", BuildQuestAddonValues(quest))
    if not ok then return false, "quest_template_addon: " .. tostring(err) end

    ok, err = SaveTable("quest_request_items", BuildQuestRequestItemsValues(quest))
    if not ok then return false, "quest_request_items: " .. tostring(err) end

    ok, err = SaveTable("quest_offer_reward", BuildQuestOfferRewardValues(quest))
    if not ok then return false, "quest_offer_reward: " .. tostring(err) end

    ok, err = SaveStarter(quest)
    if not ok then return false, "starter: " .. tostring(err) end

    ok, err = SaveEnder(quest)
    if not ok then return false, "ender: " .. tostring(err) end

    return true
end

local function SaveQuestList(player, quests)
    WorldDBExecute("START TRANSACTION")

    local ok, err = pcall(function()
        for _, quest in ipairs(quests) do
            local saved, saveErr = SaveSingleQuest(quest)
            if not saved then
                error("Quest " .. quest.id .. ": " .. tostring(saveErr))
            end
        end
    end)

    if not ok then
        WorldDBExecute("ROLLBACK")
        return false, err
    end

    WorldDBExecute("COMMIT")
    return true
end

-- =========================================================
-- Load
-- =========================================================

local function SelectColumn(tableName, alias, columnName, fallback)
    fallback = fallback or "0"

    if TableHasColumn(tableName, columnName) then
        return alias .. ".`" .. columnName .. "`"
    end

    return fallback
end

local function GetValueFromResult(result, index, fieldType)
    if fieldType == "str" then
        return result:GetString(index)
    end

    return result:GetInt32(index)
end

local function LoadFieldsFromTable(quest, tableName, idCol, defs)
    if not TableExists(tableName) then
        for _, def in ipairs(defs) do
            quest[def.key] = def.default
        end
        return
    end

    local selects = {}

    for _, def in ipairs(defs) do
        local fallback = def.type == "str" and "''" or tostring(def.default or 0)
        selects[#selects + 1] = SelectColumn(tableName, "t", def.col, fallback)
    end

    local sql = string.format(
        "SELECT %s FROM `%s` t WHERE t.`%s` = %d LIMIT 1",
        table.concat(selects, ", "),
        tableName,
        idCol,
        quest.id
    )

    local result = WorldDBQuery(sql)

    if not result then
        for _, def in ipairs(defs) do
            quest[def.key] = def.default
        end
        return
    end

    for i, def in ipairs(defs) do
        quest[def.key] = GetValueFromResult(result, i - 1, def.type)
    end
end

local function GetQuestStarter(questId)
    local result = WorldDBQuery("SELECT id FROM creature_queststarter WHERE quest = " .. questId .. " LIMIT 1")
    if result then
        return { type = "creature", entry = result:GetUInt32(0) }
    end

    result = WorldDBQuery("SELECT id FROM gameobject_queststarter WHERE quest = " .. questId .. " LIMIT 1")
    if result then
        return { type = "gameobject", entry = result:GetUInt32(0) }
    end

    return { type = "creature", entry = 0 }
end

local function GetQuestEnder(questId)
    local result = WorldDBQuery("SELECT id FROM creature_questender WHERE quest = " .. questId .. " LIMIT 1")
    if result then
        return { type = "creature", entry = result:GetUInt32(0) }
    end

    result = WorldDBQuery("SELECT id FROM gameobject_questender WHERE quest = " .. questId .. " LIMIT 1")
    if result then
        return { type = "gameobject", entry = result:GetUInt32(0) }
    end

    return { type = "creature", entry = 0 }
end

local function ForceLoadCriticalFields(quest)
    local idCol = QT_ID()

    local sql = string.format([[
        SELECT
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
            %s, %s, %s, %s, %s, %s, %s
        FROM quest_template qt
        WHERE qt.`%s` = %d
        LIMIT 1
    ]],
        SelectColumn("quest_template", "qt", "RequiredPlayerKills", "0"),
        SelectColumn("quest_template", "qt", "RewardHonor", "0"),
        SelectColumn("quest_template", "qt", "RewardKillHonor", "0"),
        SelectColumn("quest_template", "qt", "StartItem", "0"),
        SelectColumn("quest_template", "qt", "Flags", "0"),
        SelectColumn("quest_template", "qt", "QuestInfoID", "0"),
        SelectColumn("quest_template", "qt", "QuestType", "2"),
        SelectColumn("quest_template", "qt", "QuestLevel", "1"),
        SelectColumn("quest_template", "qt", "MinLevel", "1"),
        SelectColumn("quest_template", "qt", "QuestSortID", "0"),
        SelectColumn("quest_template", "qt", "RewardMoney", "0"),
        SelectColumn("quest_template", "qt", "RewardXPDifficulty", "5"),
        SelectColumn("quest_template", "qt", "RewardDisplaySpell", "0"),
        SelectColumn("quest_template", "qt", "RewardSpell", "0"),
        SelectColumn("quest_template", "qt", "RewardNextQuest", "0"),
        SelectColumn("quest_template", "qt", "RewardMoneyDifficulty", "0"),
        SelectColumn("quest_template", "qt", "AllowableRaces", "0"),
        idCol,
        quest.id
    )

    local result = WorldDBQuery(sql)

    if result then
        quest.requiredPlayerKills = result:GetUInt32(0)
        quest.rewardHonor = result:GetUInt32(1)
        quest.rewardKillHonor = result:GetUInt32(2)
        quest.startItem = result:GetUInt32(3)
        quest.flags = result:GetUInt32(4)
        quest.questInfoId = result:GetUInt32(5)
        quest.questType = result:GetUInt32(6)
        quest.questLevel = result:GetInt32(7)
        quest.minLevel = result:GetUInt32(8)
        quest.questSortId = result:GetInt32(9)
        quest.rewardMoney = result:GetInt32(10)
        quest.rewardXpDifficulty = result:GetUInt32(11)
        quest.rewardDisplaySpell = result:GetUInt32(12)
        quest.rewardSpell = result:GetUInt32(13)
        quest.rewardNextQuest = result:GetUInt32(14)
        quest.rewardMoneyDifficulty = result:GetInt32(15)
        quest.allowableRaces = result:GetInt32(16)
    end
end

local function LoadQuestData(questId)
    local idCol = QT_ID()
    local titleCol = QT_TITLE()

    local result = WorldDBQuery(string.format(
        "SELECT `%s`, `%s` FROM quest_template WHERE `%s` = %d LIMIT 1",
        idCol,
        titleCol,
        idCol,
        questId
    ))

    if not result then
        return nil
    end

    local quest = {
        id = result:GetUInt32(0),
        title = result:GetString(1)
    }

    LoadFieldsFromTable(quest, "quest_template", idCol, QT_FIELDS)
    LoadFieldsFromTable(quest, "quest_template_addon", "ID", ADDON_FIELDS)
    LoadFieldsFromTable(quest, "quest_request_items", "ID", REQUEST_FIELDS)
    LoadFieldsFromTable(quest, "quest_offer_reward", "ID", OFFER_FIELDS)

    ForceLoadCriticalFields(quest)

    quest.starter = GetQuestStarter(questId)
    quest.ender = GetQuestEnder(questId)

    return quest
end

local function SendCriticalQuestFields(player, quest)
    AIO.Handle(
        player,
        "QuestCreator",
        "ApplyCriticalQuestFields",
        tostring(quest.id or 0),
        tostring(quest.requiredPlayerKills or 0),
        tostring(quest.rewardHonor or 0),
        tostring(quest.rewardKillHonor or 0),
        tostring(quest.startItem or 0),
        tostring(quest.flags or 0),
        tostring(quest.specialFlags or 0),
        tostring(quest.questInfoId or 0),
        tostring(quest.questType or 2),
        tostring(quest.questLevel or 1),
        tostring(quest.minLevel or 1),
        tostring(quest.questSortId or 0),
        tostring(quest.rewardMoney or 0),
        tostring(quest.rewardXpDifficulty or 5),
        tostring(quest.rewardDisplaySpell or 0),
        tostring(quest.rewardSpell or 0),
        tostring(quest.rewardNextQuest or 0),
        tostring(quest.rewardMoneyDifficulty or 0),
        tostring(quest.allowableRaces or 0)
    )
end

-- =========================================================
-- List / Search
-- =========================================================

local function BuildListSelectSql(whereClause, orderClause, limit)
    local idCol = QT_ID()
    local titleCol = QT_TITLE()

    local selectLevel = TableHasColumn("quest_template", "QuestLevel") and "QuestLevel" or "0"
    local selectMinLevel = TableHasColumn("quest_template", "MinLevel") and "MinLevel" or "0"
    local selectSort = TableHasColumn("quest_template", "QuestSortID") and "QuestSortID" or "0"
    local selectRewardNext = TableHasColumn("quest_template", "RewardNextQuest") and "RewardNextQuest" or "0"

    return string.format(
        "SELECT `%s`, `%s`, %s, %s, %s, %s FROM quest_template %s %s LIMIT %d",
        idCol,
        titleCol,
        selectLevel,
        selectMinLevel,
        selectSort,
        selectRewardNext,
        whereClause or "",
        orderClause or ("ORDER BY `" .. idCol .. "` ASC"),
        limit or Config.ListPageSize
    )
end

local function FetchQuestListSimple(sql)
    local result, err = SafeQuery(sql)
    local quests = {}

    if err then
        return quests, err
    end

    if not result then
        return quests, nil
    end

    repeat
        quests[#quests + 1] = {
            id = result:GetUInt32(0),
            title = result:GetString(1),
            level = result:GetInt32(2),
            minLevel = result:GetUInt32(3),
            sortId = result:GetInt32(4),
            rewardNextQuest = result:GetUInt32(5)
        }
    until not result:NextRow()

    return quests, nil
end

function QuestCreator.ListQuestsForward(player, startId)
    if not HasPermission(player) then return end

    startId = ToNumber(startId, Config.BrowserQuestMinId)

    if startId < Config.BrowserQuestMinId then
        startId = Config.BrowserQuestMinId
    end

    local idCol = QT_ID()
    local stats = GetQuestStats()

    Debug(player, "quest_template count = " .. tostring(stats.count))
    Debug(player, "quest_template min/max = " .. tostring(stats.minId) .. " / " .. tostring(stats.maxId))
    Debug(player, "forward startId = " .. tostring(startId))

    local sql = BuildListSelectSql(
        "WHERE `" .. idCol .. "` >= " .. tostring(startId),
        "ORDER BY `" .. idCol .. "` ASC",
        Config.ListPageSize
    )

    local quests, err = FetchQuestListSimple(sql)

    if err then
        Debug(player, "ERROR SQL forward = " .. tostring(err))
    end

    SendQuestListStream(player, "forward", startId, quests)
end

function QuestCreator.ListQuestsBackward(player, startId)
    if not HasPermission(player) then return end

    startId = ToNumber(startId, Config.BrowserQuestMaxId)

    local idCol = QT_ID()

    local sql = BuildListSelectSql(
        "WHERE `" .. idCol .. "` <= " .. tostring(startId),
        "ORDER BY `" .. idCol .. "` DESC",
        Config.ListPageSize
    )

    local quests, err = FetchQuestListSimple(sql)

    if err then
        Debug(player, "ERROR SQL backward = " .. tostring(err))
    end

    SendQuestListStream(player, "backward", startId, quests)
end

function QuestCreator.SearchQuests(player, text)
    if not HasPermission(player) then return end

    text = EscapeString(tostring(text or ""))

    if text == "" then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Escribe texto o ID para buscar."
        })
        return
    end

    local idCol = QT_ID()
    local titleCol = QT_TITLE()
    local whereClause

    if tonumber(text) then
        whereClause = string.format(
            "WHERE `%s` = %d OR `%s` LIKE '%%%s%%'",
            idCol,
            ToNumber(text, 0),
            titleCol,
            text
        )
    else
        whereClause = string.format(
            "WHERE `%s` LIKE '%%%s%%'",
            titleCol,
            text
        )
    end

    local sql = BuildListSelectSql(
        whereClause,
        "ORDER BY `" .. idCol .. "` ASC",
        Config.ListPageSize
    )

    local quests, err = FetchQuestListSimple(sql)

    if err then
        Debug(player, "ERROR SQL search = " .. tostring(err))
    end

    Debug(player, "search text = " .. tostring(text))
    Debug(player, "search results = " .. tostring(#quests))

    SendQuestListStream(player, "search", 0, quests)
end

-- =========================================================
-- Load / Copy
-- =========================================================

function QuestCreator.LoadQuest(player, questId)
    if not HasPermission(player) then return end

    questId = ToNumber(questId, 0)

    local quest = LoadQuestData(questId)

    if not quest then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No existe quest con ID " .. questId .. "."
        })
        return
    end

    Debug(player, "LoadQuest ID = " .. tostring(quest.id))
    Debug(player, "LoadQuest RequiredPlayerKills = " .. tostring(quest.requiredPlayerKills or 0))
    Debug(player, "LoadQuest RewardHonor = " .. tostring(quest.rewardHonor or 0))

    AIO.Handle(player, "QuestCreator", "LoadQuestIntoUI", quest)
    SendCriticalQuestFields(player, quest)
end

local function GetNextFreeQuestId(startId)
    startId = ToNumber(startId, Config.CustomQuestMinId)

    if startId < Config.CustomQuestMinId then
        startId = Config.CustomQuestMinId
    end

    if not QuestExists(startId) then
        return startId
    end

    local idCol = QT_ID()

    local result = WorldDBQuery(string.format([[
        SELECT t1.`%s` + 1 AS next_id
        FROM quest_template t1
        LEFT JOIN quest_template t2 ON t2.`%s` = t1.`%s` + 1
        WHERE t1.`%s` >= %d
          AND t1.`%s` BETWEEN %d AND %d
          AND t2.`%s` IS NULL
        ORDER BY t1.`%s` ASC
        LIMIT 1
    ]],
        idCol,
        idCol,
        idCol,
        idCol,
        startId,
        idCol,
        Config.CustomQuestMinId,
        Config.CustomQuestMaxId,
        idCol,
        idCol
    ))

    if result then
        return result:GetUInt32(0)
    end

    return Config.CustomQuestMinId
end

function QuestCreator.CopyQuest(player, sourceQuestId, preferredNewId)
    if not HasPermission(player) then return end

    sourceQuestId = ToNumber(sourceQuestId, 0)
    preferredNewId = ToNumber(preferredNewId, 0)

    if not QuestExists(sourceQuestId) then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No existe la quest origen " .. sourceQuestId .. "."
        })
        return
    end

    local newId = preferredNewId

    if newId <= 0 then
        newId = GetNextFreeQuestId(Config.CustomQuestMinId)
    end

    if newId < Config.CustomQuestMinId or newId > Config.CustomQuestMaxId then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "El nuevo ID debe estar entre " .. Config.CustomQuestMinId .. " y " .. Config.CustomQuestMaxId .. "."
        })
        return
    end

    if QuestExists(newId) then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Ya existe una quest con el nuevo ID " .. newId .. "."
        })
        return
    end

    local quest = LoadQuestData(sourceQuestId)

    if not quest then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No se pudo cargar la quest origen " .. sourceQuestId .. "."
        })
        return
    end

    quest.id = newId
    -- Limpiar cualquier sufijo (Copy) que pudiera venir de copias previas,
    -- incluyendo variantes con \n o espacios extra
    local cleanTitle = tostring(quest.title or "")
    cleanTitle = cleanTitle:gsub("\\n", " ")           -- quitar \n literal
    cleanTitle = cleanTitle:gsub("\n", " ")             -- quitar newline real
    cleanTitle = cleanTitle:gsub("%s*%(Copy%)%s*$", "")
    cleanTitle = cleanTitle:gsub("%s*%(COPY%)%s*$", "")
    cleanTitle = cleanTitle:gsub("%s*%- Copy%s*$", "")
    cleanTitle = cleanTitle:gsub("%s+$", "")            -- trim trailing spaces
    quest.title = cleanTitle
    quest.rewardNextQuest = 0
    quest.prevQuestId = 0
    quest.nextQuestId = 0
    quest.exclusiveGroup = 0

    AIO.Handle(player, "QuestCreator", "LoadQuestCopyIntoUI", {
        sourceId = sourceQuestId,
        newId = newId,
        quest = quest
    })

    SendCriticalQuestFields(player, quest)
end

-- =========================================================
-- Delete
-- =========================================================

local function DeleteQuestInternal(questId)
    local idCol = QT_ID()

    if TableHasColumn("quest_template", "RewardNextQuest") then
        WorldDBExecute("UPDATE quest_template SET RewardNextQuest = 0 WHERE RewardNextQuest = " .. questId)
    end

    if TableExists("quest_template_addon") then
        WorldDBExecute("UPDATE quest_template_addon SET PrevQuestID = 0 WHERE PrevQuestID = " .. questId)
        WorldDBExecute("UPDATE quest_template_addon SET NextQuestID = 0 WHERE NextQuestID = " .. questId)
    end

    WorldDBExecute("DELETE FROM creature_queststarter WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM creature_questender WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM gameobject_queststarter WHERE quest = " .. questId)
    WorldDBExecute("DELETE FROM gameobject_questender WHERE quest = " .. questId)

    if TableExists("quest_request_items") then
        WorldDBExecute("DELETE FROM quest_request_items WHERE ID = " .. questId)
    end

    if TableExists("quest_offer_reward") then
        WorldDBExecute("DELETE FROM quest_offer_reward WHERE ID = " .. questId)
    end

    if TableExists("quest_template_addon") then
        WorldDBExecute("DELETE FROM quest_template_addon WHERE ID = " .. questId)
    end

    WorldDBExecute("DELETE FROM quest_template WHERE `" .. idCol .. "` = " .. questId)
end

function QuestCreator.PreviewDeleteQuest(player, questId)
    if not HasPermission(player) then return end

    questId = ToNumber(questId, 0)

    local result = WorldDBQuery(string.format(
        "SELECT `%s`, `%s` FROM quest_template WHERE `%s` = %d LIMIT 1",
        QT_ID(),
        QT_TITLE(),
        QT_ID(),
        questId
    ))

    if not result then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No existe quest " .. questId .. "."
        })
        return
    end

    AIO.Handle(player, "QuestCreator", "ShowDeletePreview", {
        id = result:GetUInt32(0),
        title = result:GetString(1),
        confirmText = "DELETE " .. questId
    })
end

function QuestCreator.DeleteQuest(player, questId, confirmText)
    if not HasPermission(player) then return end

    questId = ToNumber(questId, 0)

    if not QuestExists(questId) then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No existe quest " .. questId .. "."
        })
        return
    end

    if not Config.AllowDeleteOutsideCustomRange then
        if questId < Config.CustomQuestMinId or questId > Config.CustomQuestMaxId then
            AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
                "No puedes borrar quests fuera del rango custom."
            })
            return
        end
    end

    local requiredConfirm = "DELETE " .. questId

    if confirmText ~= requiredConfirm then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Confirmación incorrecta. Escribe exactamente: " .. requiredConfirm
        })
        return
    end

    WorldDBExecute("START TRANSACTION")

    local ok, err = pcall(function()
        DeleteQuestInternal(questId)
    end)

    if not ok then
        WorldDBExecute("ROLLBACK")
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Error borrando quest: " .. tostring(err)
        })
        return
    end

    WorldDBExecute("COMMIT")

    AIO.Handle(player, "QuestCreator", "ShowDeleteSuccess", questId)
    player:SendBroadcastMessage("QuestCreator: quest " .. questId .. " borrada.")
    ReloadQuestTables(player)
end

local function GetForwardChain(startQuestId, maxDepth)
    local chain = {}
    local seen = {}
    local current = ToNumber(startQuestId, 0)

    maxDepth = maxDepth or 50

    for i = 1, maxDepth do
        if current <= 0 then
            break
        end

        if seen[current] then
            break
        end

        seen[current] = true
        chain[#chain + 1] = current

        if not TableHasColumn("quest_template", "RewardNextQuest") then
            break
        end

        local result = WorldDBQuery(
            "SELECT RewardNextQuest FROM quest_template WHERE `" .. QT_ID() .. "` = " .. current .. " LIMIT 1"
        )

        if not result then
            break
        end

        current = result:GetUInt32(0)
    end

    return chain
end

function QuestCreator.DeleteQuestChain(player, startQuestId, confirmText)
    if not HasPermission(player) then return end

    startQuestId = ToNumber(startQuestId, 0)

    local requiredConfirm = "DELETE CHAIN " .. startQuestId

    if confirmText ~= requiredConfirm then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Confirmación incorrecta. Escribe exactamente: " .. requiredConfirm
        })
        return
    end

    local chain = GetForwardChain(startQuestId, 50)

    if #chain == 0 then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "No se encontró cadena desde " .. startQuestId .. "."
        })
        return
    end

    WorldDBExecute("START TRANSACTION")

    local ok, err = pcall(function()
        for _, questId in ipairs(chain) do
            DeleteQuestInternal(questId)
        end
    end)

    if not ok then
        WorldDBExecute("ROLLBACK")
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Error borrando cadena: " .. tostring(err)
        })
        return
    end

    WorldDBExecute("COMMIT")

    AIO.Handle(player, "QuestCreator", "ShowDeleteChainSuccess", chain)
    player:SendBroadcastMessage("QuestCreator: cadena borrada: " .. table.concat(chain, ", "))
    ReloadQuestTables(player)
end

-- =========================================================
-- Validate / Save
-- =========================================================

function QuestCreator.Validate(player, payload)
    if not HasPermission(player) then return end

    local quests = BuildQuestPayloadList(payload)
    local errors = ValidateQuestList(quests)

    if #quests == 0 then
        errors[#errors + 1] = "No se recibió ninguna quest."
    end

    if #errors > 0 then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", errors)
        return
    end

    AIO.Handle(player, "QuestCreator", "ShowValidationSuccess", {
        count = #quests
    })
end

function QuestCreator.Save(player, payload)
    if not HasPermission(player) then return end

    local quests = BuildQuestPayloadList(payload)
    local errors = ValidateQuestList(quests)

    if #quests == 0 then
        errors[#errors + 1] = "No se recibió ninguna quest."
    end

    if #errors > 0 then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", errors)
        return
    end

    local ok, err = SaveQuestList(player, quests)

    if not ok then
        AIO.Handle(player, "QuestCreator", "ShowValidationErrors", {
            "Error guardando: " .. tostring(err)
        })
        return
    end

    local ids = {}

    for _, quest in ipairs(quests) do
        ids[#ids + 1] = tostring(quest.id)
    end

    AIO.Handle(player, "QuestCreator", "ShowSaveSuccess", table.concat(ids, ", "))
    player:SendBroadcastMessage("QuestCreator: guardado correcto. IDs: " .. table.concat(ids, ", "))
    ReloadQuestTables(player)
end

-- =========================================================
-- Debug schema
-- =========================================================

function QuestCreator.DebugSchema(player)
    if not HasPermission(player) then return end

    local s = DetectSchema()
    local stats = GetQuestStats()

    player:SendBroadcastMessage("QuestCreator SERVER VERSION: QUESTCREATOR-V3-FULL-SCHEMA-2026-05-08")
    player:SendBroadcastMessage("QuestCreator Schema:")
    player:SendBroadcastMessage("quest_template ID column: " .. s.questId)
    player:SendBroadcastMessage("quest_template title column: " .. s.questTitle)
    player:SendBroadcastMessage("quest_template_addon: " .. tostring(s.hasQuestTemplateAddon))
    player:SendBroadcastMessage("quest_offer_reward: " .. tostring(s.hasQuestOfferReward))
    player:SendBroadcastMessage("quest_request_items: " .. tostring(s.hasQuestRequestItems))
    player:SendBroadcastMessage("quest_template count: " .. tostring(stats.count))
    player:SendBroadcastMessage("quest_template min ID: " .. tostring(stats.minId))
    player:SendBroadcastMessage("quest_template max ID: " .. tostring(stats.maxId))

    local result = WorldDBQuery(string.format(
        "SELECT `%s`, `%s` FROM quest_template ORDER BY `%s` ASC LIMIT 1",
        QT_ID(),
        QT_TITLE(),
        QT_ID()
    ))

    if result then
        player:SendBroadcastMessage("first quest: [" .. tostring(result:GetUInt32(0)) .. "] " .. tostring(result:GetString(1)))
    else
        player:SendBroadcastMessage("first quest: NONE")
    end
end

-- =========================================================
-- Creature info lookup (name + display id) for objectives preview
-- =========================================================

-- =========================================================
-- Creature info lookup + SMSG_CREATURE_QUERY_RESPONSE
-- =========================================================
-- Envía el opcode 97 (SMSG_CREATURE_QUERY_RESPONSE) al cliente,
-- igual que la referencia CSGO_Box_Server.lua.
-- Esto registra la criatura en el caché nativo del cliente WoW,
-- permitiendo que SetCreature() renderice el modelo sin haberla visto.
-- =========================================================

local function SendCreatureQueryResponse(player, data)
    -- data = { entry, name, subname, iconName, type_flags, type, family,
    --          rank, killCredit1, killCredit2,
    --          modelId1, modelId2, modelId3, modelId4,
    --          healthMod, manaMod, racialLeader, movementType }
    local packet = CreatePacket(97, 100)
    packet:WriteULong(data[1])          -- entry
    packet:WriteString(data[2] or "")   -- name
    packet:WriteUByte(0)                -- name2 (null)
    packet:WriteUByte(0)                -- name3 (null)
    packet:WriteUByte(0)                -- name4 (null)
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

function QuestCreator.RequestCreatureInfo(player, entry)
    if not HasPermission(player) then return end

    entry = ToNumber(entry, 0)

    if entry <= 0 then
        AIO.Handle(player, "QuestCreator", "ReceiveCreatureInfo",
            tostring(entry), "0", HexEncode(""), "0")
        return
    end

    -- Consultar creature_template con todos los campos necesarios para el packet
    local sql = "SELECT entry, name, subname, IconName, type_flags, type, family, `rank`, "
        .. "KillCredit1, KillCredit2, HealthModifier, ManaModifier, RacialLeader, MovementType "
        .. "FROM creature_template WHERE entry = " .. SqlNumber(entry) .. " LIMIT 1"

    local result, err = SafeQuery(sql)

    if err or not result then
        AIO.Handle(player, "QuestCreator", "ReceiveCreatureInfo",
            tostring(entry), "0", HexEncode(""), "0")
        return
    end

    local data = {
        result:GetUInt32(0),    -- [1]  entry
        result:GetString(1),    -- [2]  name
        result:GetString(2),    -- [3]  subname
        result:GetString(3),    -- [4]  IconName
        result:GetUInt32(4),    -- [5]  type_flags
        result:GetUInt32(5),    -- [6]  type
        result:GetUInt32(6),    -- [7]  family
        result:GetUInt32(7),    -- [8]  rank
        result:GetUInt32(8),    -- [9]  KillCredit1
        result:GetUInt32(9),    -- [10] KillCredit2
        0,                      -- [11] modelId1 (se llena abajo)
        0,                      -- [12] modelId2
        0,                      -- [13] modelId3
        0,                      -- [14] modelId4
        result:GetFloat(10),    -- [15] HealthModifier
        result:GetFloat(11),    -- [16] ManaModifier
        result:GetUInt32(12),   -- [17] RacialLeader
        result:GetUInt32(13),   -- [18] MovementType
    }

    local name = data[2]

    -- Consultar creature_template_model para los displayIds
    local modelSql = "SELECT Idx, CreatureDisplayID FROM creature_template_model "
        .. "WHERE CreatureID = " .. SqlNumber(entry) .. " ORDER BY Idx ASC LIMIT 4"

    local modelResult, modelErr = SafeQuery(modelSql)

    if not modelErr and modelResult then
        repeat
            local idx = modelResult:GetUInt32(0)  -- 0,1,2,3
            local displayId = modelResult:GetUInt32(1)
            if idx <= 3 then
                data[11 + idx] = displayId  -- modelId1..4
            end
        until not modelResult:NextRow()
    end

    -- Enviar SMSG_CREATURE_QUERY_RESPONSE (opcode 97) al cliente
    -- Esto registra la criatura en el caché nativo del cliente WoW
    -- para que SetCreature() funcione aunque no la haya visto en el mundo
    local packetOk, packetErr = pcall(function()
        SendCreatureQueryResponse(player, data)
    end)

    if not packetOk then
        Debug(player, "SendCreatureQueryResponse error: " .. tostring(packetErr))
    end

    -- También enviar por AIO el nombre y displayId para el texto del preview
    AIO.Handle(player, "QuestCreator", "ReceiveCreatureInfo",
        tostring(entry), "1", HexEncode(name), tostring(data[11]))
end

function QuestCreator.RequestGameObjectInfo(player, entry)
    if not HasPermission(player) then return end

    entry = ToNumber(entry, 0)

    -- entries from objectives use GO as negative, but caller may also pass abs value
    if entry < 0 then entry = -entry end

    if entry <= 0 then
        AIO.Handle(
            player,
            "QuestCreator",
            "ReceiveGameObjectInfo",
            tostring(entry),
            "0",
            HexEncode(""),
            "0"
        )
        return
    end

    -- gameobject_template: entry, displayId, name
    local sql = "SELECT name, displayId FROM gameobject_template WHERE entry = " ..
        SqlNumber(entry) .. " LIMIT 1"

    local result, err = SafeQuery(sql)

    if err or not result then
        AIO.Handle(
            player,
            "QuestCreator",
            "ReceiveGameObjectInfo",
            tostring(entry),
            "0",
            HexEncode(""),
            "0"
        )
        return
    end

    local name = result:GetString(0) or ""
    local displayId = result:GetUInt32(1) or 0

    AIO.Handle(
        player,
        "QuestCreator",
        "ReceiveGameObjectInfo",
        tostring(entry),
        "1",
        HexEncode(name),
        tostring(displayId)
    )
end

-- =========================================================
-- Command
-- =========================================================

local function OnCommand(event, player, command)
    if command == "qc schema" or command == "questcreator schema" then
        QuestCreator.DebugSchema(player)
        return false
    end

    if command == "qc" or command == "questcreator" then
        if not HasPermission(player) then
            player:SendBroadcastMessage("No tienes permisos para usar QuestCreator.")
            return false
        end

        player:SendBroadcastMessage("QuestCreator SERVER VERSION: QUESTCREATOR-V3-FULL-SCHEMA-2026-05-08")
        AIO.Handle(player, "QuestCreator", "ShowFrame")
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)