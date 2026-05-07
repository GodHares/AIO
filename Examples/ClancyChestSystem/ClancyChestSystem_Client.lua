-- ClancyChestSystem_Client.lua
-- Cliente AIO con un solo frame, sin doble borde, estilo dorado.
-- Handler: ClancyChestSystem
-- Compatible con servidor PAYLOAD:
--   active <<CLANCYSEP>> activationId <<CLANCYSEP>> remaining
--     <<CLANCYSEP>> totalChests <<CLANCYSEP>> lootedChests <<CLANCYSEP>> itemsText

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

------------------------------------------------------------
-- Configuración general.
------------------------------------------------------------

local HANDLER       = "ClancyChestSystem"
local PAYLOAD_SEP   = "<<CLANCYSEP>>"
local DEBUG         = true

local FRAME_WIDTH       = 920
local FRAME_HEIGHT      = 660
local NUM_VISIBLE_ROWS  = 5
local ROW_HEIGHT        = 36

-- Paleta dorada / oscura.
local C_GOLD        = { 0.95, 0.74, 0.22 }
local C_GOLD_DARK   = { 0.70, 0.50, 0.10 }
local C_BG_DEEP     = { 0.04, 0.03, 0.02 }
local C_BG_PANEL    = { 0.06, 0.05, 0.03 }
local C_BG_INPUT    = { 0.02, 0.02, 0.02 }
local C_RED_BTN     = { 0.45, 0.06, 0.05 }
local C_RED_HOVER   = { 0.60, 0.10, 0.06 }
local C_ROW_HL      = { 0.55, 0.04, 0.02 }

-- Códigos de color para fontstrings.
local CC_GOLD       = "|cffffd34a"
local CC_GOLD_SOFT  = "|cffffcc66"
local CC_GREEN_OK   = "|cff44dd33"
local CC_RED_OFF    = "|cffff3333"
local CC_GREEN_PCT  = "|cff66ff33"
local CC_RED_LIGHT  = "|cffff8888"

------------------------------------------------------------
-- Logging.
------------------------------------------------------------

local function D(msg)
    if DEBUG then
        print("|cff00ccff[ClancyChestSystem CLIENT]|r " .. tostring(msg))
    end
end

D("Cliente cargado.")

------------------------------------------------------------
-- Estado del cliente.
------------------------------------------------------------

local ClancyChestSystem = AIO.AddHandlers(HANDLER, {})

local UI = {}
local stockItems = {}
local selectedItemEntry = nil

local lastSnapshot = {
    active = false,
    activationId = 0,
    remaining = 0,
    totalChests = 0,
    lootedChests = 0,
    itemsText = ""
}

local lastSnapshotClientTime = 0
local lastStatusUpdate = 0

------------------------------------------------------------
-- Parsing del payload del servidor.
------------------------------------------------------------

local function FindPayload(...)
    for i = 1, select("#", ...) do
        local text = tostring(select(i, ...) or "")

        if string.find(text, PAYLOAD_SEP, 1, true) then
            return text
        end
    end

    return nil
end

local function SplitPayload(payload)
    payload = tostring(payload or "")

    local parts = {}
    local pos = 1

    while true do
        local sStart, sEnd = string.find(payload, PAYLOAD_SEP, pos, true)

        if not sStart then
            table.insert(parts, string.sub(payload, pos))
            break
        end

        table.insert(parts, string.sub(payload, pos, sStart - 1))
        pos = sEnd + 1
    end

    return parts
end

local function SplitLines(text)
    local lines = {}
    text = tostring(text or "")

    if text == "" then
        return lines
    end

    for line in string.gmatch(text, "([^\n]+)") do
        table.insert(lines, line)
    end

    return lines
end

local function ParseStockItems(itemsText)
    local result = {}

    for _, line in ipairs(SplitLines(itemsText)) do
        local entry, amount, chance, name = string.match(
            line,
            "^(%d+)%s+x(%d+)%s+%[(%d+)%%%]%s+%-%s+(.+)$"
        )

        if not entry then
            entry, amount = string.match(line, "^(%d+)%s+x(%d+)")
            chance = "100"
            name = line
        end

        if entry then
            table.insert(result, {
                entry  = tonumber(entry) or 0,
                amount = tonumber(amount) or 0,
                chance = tonumber(chance) or 100,
                name   = tostring(name or ("Item " .. tostring(entry))),
            })
        end
    end

    table.sort(result, function(a, b) return a.entry < b.entry end)

    return result
end

local function FormatRemaining(seconds)
    seconds = tonumber(seconds) or 0

    if seconds < 0 then seconds = 0 end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    if h > 0 then
        return string.format("%02dh %02dm %02ds", h, m, s)
    end

    return string.format("%dm %02ds", m, s)
end

local function GetItemIconPath(entry)
    entry = tonumber(entry) or 0

    if entry > 0 then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(entry)

        if texture then return texture end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetItemQualityColorCode(entry)
    entry = tonumber(entry) or 0

    if entry <= 0 then return "|cffffffff" end

    local _, _, quality = GetItemInfo(entry)

    if quality and _G.GetItemQualityColor then
        local r, g, b = _G.GetItemQualityColor(quality)

        r = tonumber(r) or 1
        g = tonumber(g) or 1
        b = tonumber(b) or 1

        return string.format(
            "|cff%02x%02x%02x",
            math.floor(r * 255),
            math.floor(g * 255),
            math.floor(b * 255)
        )
    end

    return "|cffffffff"
end

------------------------------------------------------------
-- Helpers visuales (ligeros, sin sub-frames innecesarios).
------------------------------------------------------------

local function SolidTexture(parent, layer, color, alpha)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetVertexColor(color[1], color[2], color[3], alpha or 1)
    return tex
end

local function ApplyBackdrop(frame, bgColor, alpha, borderColor, edgeSize)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = edgeSize or 14,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], alpha or 1)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
end

local function MakePanel(parent, x, y, w, h)
    local p = CreateFrame("Frame", nil, parent)
    p:SetWidth(w)
    p:SetHeight(h)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    ApplyBackdrop(p, C_BG_PANEL, 0.78, C_GOLD_DARK, 14)
    return p
end

local function MakeLabel(parent, text, x, y, width, template, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    if width then fs:SetWidth(width) end

    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

local function MakeSectionTitle(panel, text)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -8)
    title:SetText(CC_GOLD_SOFT .. text .. "|r")

    local stripe = SolidTexture(panel, "BORDER", C_GOLD, 0.55)
    stripe:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -22)
    stripe:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -22)
    stripe:SetHeight(1)

    return title
end

------------------------------------------------------------
-- Edit box con flechas spinner y opcional botón lupa.
------------------------------------------------------------

local function MakeArrowButton(parent, isUp)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(16)
    btn:SetHeight(11)

    local normal = isUp and "Interface\\Buttons\\Arrow-Up-Up"
                         or "Interface\\Buttons\\Arrow-Down-Up"

    local pressed = isUp and "Interface\\Buttons\\Arrow-Up-Down"
                          or "Interface\\Buttons\\Arrow-Down-Down"

    local arrow = btn:CreateTexture(nil, "ARTWORK")
    arrow:SetAllPoints(btn)
    arrow:SetTexture(normal)

    btn:SetScript("OnEnter", function() arrow:SetTexture(pressed) end)
    btn:SetScript("OnLeave", function() arrow:SetTexture(normal) end)

    return btn
end

local function MakeSpinnerEdit(parent, labelText, x, y, width, defaultText, withSearch)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(CC_GOLD .. labelText .. "|r")

    local boxBg = CreateFrame("Frame", nil, parent)
    boxBg:SetWidth(width + 28)
    boxBg:SetHeight(32)
    boxBg:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 4, y - 22)
    ApplyBackdrop(boxBg, C_BG_INPUT, 0.95, C_GOLD_DARK, 12)

    local box = CreateFrame("EditBox", nil, parent)
    box:SetWidth(width - 28)
    box:SetHeight(22)
    box:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 8, -5)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightLarge")
    box:SetTextInsets(2, 2, 0, 0)
    box:SetText(defaultText or "")

    if box.SetNumeric then box:SetNumeric(true) end

    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    if withSearch then
        local search = CreateFrame("Button", nil, parent)
        search:SetWidth(20)
        search:SetHeight(20)
        search:SetPoint("RIGHT", boxBg, "RIGHT", -6, 0)

        local tex = search:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(search)
        tex:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
        tex:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.95)

        search:SetScript("OnEnter", function(self)
            tex:SetVertexColor(1, 1, 0.4, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Inspeccionar item", 1, 1, 1)
            GameTooltip:Show()
        end)
        search:SetScript("OnLeave", function()
            tex:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.95)
            GameTooltip:Hide()
        end)
        search:SetScript("OnClick", function()
            local entry = tonumber(box:GetText())
            if entry and entry > 0 then
                GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. tostring(entry))
                GameTooltip:Show()
            end
        end)
    else
        local up = MakeArrowButton(parent, true)
        up:SetPoint("TOPRIGHT", boxBg, "TOPRIGHT", -6, -4)

        local down = MakeArrowButton(parent, false)
        down:SetPoint("BOTTOMRIGHT", boxBg, "BOTTOMRIGHT", -6, 4)

        local function adjust(delta)
            local n = (tonumber(box:GetText()) or 0) + delta
            if n < 0 then n = 0 end
            box:SetText(tostring(n))
        end

        up:SetScript("OnClick", function() adjust(1) end)
        down:SetScript("OnClick", function() adjust(-1) end)
    end

    return box
end

------------------------------------------------------------
-- Botones de acción.
------------------------------------------------------------

local function StyleButton(btn, hovered)
    if hovered then
        btn:SetBackdropColor(C_RED_HOVER[1], C_RED_HOVER[2], C_RED_HOVER[3], 0.95)
    else
        btn:SetBackdropColor(C_RED_BTN[1], C_RED_BTN[2], C_RED_BTN[3], 0.95)
    end
    btn:SetBackdropBorderColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
end

-- Crea el "icono" del botón. Recibe una de las claves: "plus", "minus",
-- "trash", "broom", "play", "stop", "refresh".
local function CreateButtonIcon(btn, kind)
    local icon

    if kind == "plus" then
        icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon:SetText(CC_GREEN_PCT .. "+|r")
    elseif kind == "minus" then
        icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon:SetText(CC_RED_LIGHT .. "-|r")
    elseif kind == "trash" then
        icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        icon:SetWidth(16)
        icon:SetHeight(16)
        icon:SetVertexColor(1, 0.5, 0.4, 1)
    elseif kind == "broom" then
        -- Ícono ad-hoc: 3 cerdas sobre una base.
        local base = btn:CreateTexture(nil, "ARTWORK")
        base:SetTexture("Interface\\Buttons\\WHITE8x8")
        base:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        base:SetWidth(14)
        base:SetHeight(3)

        local b1 = btn:CreateTexture(nil, "ARTWORK")
        b1:SetTexture("Interface\\Buttons\\WHITE8x8")
        b1:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        b1:SetWidth(2)
        b1:SetHeight(8)

        local b2 = btn:CreateTexture(nil, "ARTWORK")
        b2:SetTexture("Interface\\Buttons\\WHITE8x8")
        b2:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        b2:SetWidth(2)
        b2:SetHeight(8)

        local b3 = btn:CreateTexture(nil, "ARTWORK")
        b3:SetTexture("Interface\\Buttons\\WHITE8x8")
        b3:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        b3:SetWidth(2)
        b3:SetHeight(8)

        icon = base
        icon._extra = { b1, b2, b3 }
    elseif kind == "play" then
        -- Triángulo play simulado con 3 capas verticales.
        local p1 = btn:CreateTexture(nil, "ARTWORK")
        p1:SetTexture("Interface\\Buttons\\WHITE8x8")
        p1:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        p1:SetWidth(3)
        p1:SetHeight(12)

        local p2 = btn:CreateTexture(nil, "ARTWORK")
        p2:SetTexture("Interface\\Buttons\\WHITE8x8")
        p2:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        p2:SetWidth(3)
        p2:SetHeight(8)

        local p3 = btn:CreateTexture(nil, "ARTWORK")
        p3:SetTexture("Interface\\Buttons\\WHITE8x8")
        p3:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        p3:SetWidth(3)
        p3:SetHeight(4)

        icon = p1
        icon._extra = { p2, p3 }
    elseif kind == "stop" then
        icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Buttons\\WHITE8x8")
        icon:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
        icon:SetWidth(12)
        icon:SetHeight(12)
    elseif kind == "refresh" then
        icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
        icon:SetWidth(18)
        icon:SetHeight(18)
    end

    return icon
end

local function PositionIcon(btn, kind, icon)
    if kind == "plus" or kind == "minus" then
        icon:SetPoint("LEFT", btn, "LEFT", 12, 0)
    elseif kind == "stop" then
        icon:SetPoint("LEFT", btn, "LEFT", 12, 0)
    elseif kind == "broom" then
        -- base centrada abajo, cerdas encima.
        icon:SetPoint("LEFT", btn, "LEFT", 8, -4)
        local b = icon._extra
        b[1]:SetPoint("BOTTOM", icon, "TOP", -4, 0)
        b[2]:SetPoint("BOTTOM", icon, "TOP", 0, 0)
        b[3]:SetPoint("BOTTOM", icon, "TOP", 4, 0)
    elseif kind == "play" then
        icon:SetPoint("LEFT", btn, "LEFT", 12, 0)
        icon._extra[1]:SetPoint("LEFT", icon, "RIGHT", 0, 0)
        icon._extra[2]:SetPoint("LEFT", icon._extra[1], "RIGHT", 0, 0)
    else
        icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
    end
end

local function MakeButton(parent, label, iconKind, x, y, width, isRefresh, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(36)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    if isRefresh then
        btn:SetBackdropColor(0.13, 0.10, 0.07, 0.95)
        btn:SetBackdropBorderColor(C_GOLD_DARK[1], C_GOLD_DARK[2], C_GOLD_DARK[3], 1)
    else
        StyleButton(btn, false)
    end

    local icon = CreateButtonIcon(btn, iconKind)
    if icon then PositionIcon(btn, iconKind, icon) end

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", btn, "LEFT", 32, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    text:SetJustifyH("CENTER")

    local idleColor = isRefresh and "|cffcccccc" or CC_GOLD
    text:SetText(idleColor .. label .. "|r")

    btn:SetScript("OnEnter", function(self)
        if isRefresh then
            self:SetBackdropColor(0.20, 0.15, 0.10, 0.95)
        else
            StyleButton(self, true)
        end
        text:SetText("|cffffffff" .. label .. "|r")
    end)

    btn:SetScript("OnLeave", function(self)
        if isRefresh then
            self:SetBackdropColor(0.13, 0.10, 0.07, 0.95)
        else
            StyleButton(self, false)
        end
        text:SetText(idleColor .. label .. "|r")
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

------------------------------------------------------------
-- Status bar.
------------------------------------------------------------

local function StatusVerticalSep(parent, x)
    local sep = SolidTexture(parent, "ARTWORK", C_GOLD, 0.45)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -2)
    sep:SetWidth(1)
    sep:SetHeight(28)
    return sep
end

local function MakeStatusItem(parent, label, defaultValue, x)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", parent, "LEFT", x, 0)
    lbl:SetText(CC_GOLD .. label .. ":|r")

    local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    val:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    val:SetText(defaultValue or "-")

    return val
end

local function UpdateHeaderStatus()
    if not UI.frame then return end

    local active        = lastSnapshot.active
    local activationId  = tonumber(lastSnapshot.activationId) or 0
    local totalChests   = tonumber(lastSnapshot.totalChests) or 0
    local lootedChests  = tonumber(lastSnapshot.lootedChests) or 0

    if active then
        local liveRemaining = (tonumber(lastSnapshot.remaining) or 0)
            - (GetTime() - lastSnapshotClientTime)
        if liveRemaining < 0 then liveRemaining = 0 end

        UI.statusValue:SetText(CC_GREEN_OK .. "ACTIVO|r")
        UI.timerValue:SetText(CC_GOLD .. FormatRemaining(liveRemaining) .. "|r")
        UI.statusDot:SetVertexColor(0.20, 0.95, 0.30, 1)
    else
        UI.statusValue:SetText(CC_RED_OFF .. "INACTIVO|r")
        UI.timerValue:SetText("|cffaaaaaa--:--|r")
        UI.statusDot:SetVertexColor(0.95, 0.20, 0.20, 1)
    end

    UI.chestValue:SetText(CC_GOLD .. lootedChests .. "/" .. totalChests .. "|r")
    UI.activationValue:SetText(CC_GOLD .. "#" .. activationId .. "|r")
end

------------------------------------------------------------
-- Selección y refresco de la lista.
------------------------------------------------------------

local function FindSelectedItem()
    if not selectedItemEntry then return nil end

    for _, item in ipairs(stockItems) do
        if item.entry == selectedItemEntry then return item end
    end

    return nil
end

local function UpdateSelectedCard()
    if not UI.selectedPanel then return end

    local item = FindSelectedItem()

    if not item then
        UI.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        UI.selectedItemId:SetText("-")
        UI.selectedName:SetText(CC_GOLD .. "Ningún item seleccionado|r")
        UI.selectedAmount:SetText("-")
        UI.selectedChance:SetText("-")
        UI.selectedDuration:SetText("-")
        return
    end

    local color = GetItemQualityColorCode(item.entry)

    UI.selectedIcon:SetTexture(GetItemIconPath(item.entry))
    UI.selectedItemId:SetText(tostring(item.entry))
    UI.selectedName:SetText(color .. tostring(item.name) .. "|r")
    UI.selectedAmount:SetText(tostring(item.amount))
    UI.selectedChance:SetText(CC_GREEN_PCT .. tostring(item.chance) .. "%|r")
    UI.selectedDuration:SetText(
        tostring(UI.durationBox and UI.durationBox:GetText() or "-") .. " min."
    )
end

local function SelectItem(item)
    if not item or not item.entry or item.entry <= 0 then return end

    selectedItemEntry = item.entry

    if UI.itemBox then UI.itemBox:SetText(tostring(item.entry)) end
    if UI.countBox then UI.countBox:SetText(tostring(item.amount)) end
    if UI.chanceBox then UI.chanceBox:SetText(tostring(item.chance)) end

    UpdateSelectedCard()

    if UI.scrollFrame and UI.scrollFrame.update then
        UI.scrollFrame.update()
    end
end

local function RefreshRows()
    if not UI.rows or not UI.scrollFrame then return end

    FauxScrollFrame_Update(UI.scrollFrame, #stockItems, NUM_VISIBLE_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(UI.scrollFrame)

    for i = 1, NUM_VISIBLE_ROWS do
        local row = UI.rows[i]
        local itemIndex = offset + i
        local item = stockItems[itemIndex]

        if item then
            row.item = item
            row:Show()

            local color = GetItemQualityColorCode(item.entry)

            row.indexText:SetText(tostring(itemIndex))
            row.icon:SetTexture(GetItemIconPath(item.entry))
            row.entryText:SetText(tostring(item.entry))
            row.nameText:SetText(color .. tostring(item.name) .. "|r")
            row.amountText:SetText(tostring(item.amount))
            row.chanceText:SetText(CC_GREEN_PCT .. tostring(item.chance) .. "%|r")
            row.durationText:SetText(
                tostring(UI.durationBox and UI.durationBox:GetText() or "-")
            )

            if selectedItemEntry == item.entry then
                row.highlight:Show()
                row:SetBackdropBorderColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)
            else
                row.highlight:Hide()
                row:SetBackdropBorderColor(0, 0, 0, 0)
            end
        else
            row.item = nil
            row:Hide()
        end
    end

    if UI.emptyText then
        if #stockItems <= 0 then UI.emptyText:Show() else UI.emptyText:Hide() end
    end
end

local function RebuildStockData(itemsText)
    stockItems = ParseStockItems(itemsText)

    local stillExists = false

    if selectedItemEntry then
        for _, it in ipairs(stockItems) do
            if it.entry == selectedItemEntry then
                stillExists = true
                break
            end
        end
    end

    if not stillExists then selectedItemEntry = nil end

    if UI.listTitle then
        UI.listTitle:SetText(
            CC_GOLD_SOFT .. "ITEMS CONFIGURADOS (" .. #stockItems .. ")|r"
        )
    end

    RefreshRows()
    UpdateSelectedCard()
end

local function ApplySnapshotData(active, activationId, remaining,
                                 totalChests, lootedChests, itemsText)
    lastSnapshot = {
        active        = active == true or active == 1 or active == "1",
        activationId  = tonumber(activationId) or 0,
        remaining     = tonumber(remaining) or 0,
        totalChests   = tonumber(totalChests) or 0,
        lootedChests  = tonumber(lootedChests) or 0,
        itemsText     = tostring(itemsText or "")
    }

    lastSnapshotClientTime = GetTime()

    UpdateHeaderStatus()
    RebuildStockData(lastSnapshot.itemsText)
end

------------------------------------------------------------
-- Filas de la lista (sin sub-frame para el borde).
------------------------------------------------------------

local function CreateListRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(800)
    row:SetHeight(ROW_HEIGHT)

    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", UI.rows[index - 1], "BOTTOMLEFT", 0, -2)
    end

    -- Backdrop solo con borde transparente; se vuelve dorado al seleccionar.
    row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row:SetBackdropColor(C_BG_INPUT[1] + 0.01, C_BG_INPUT[2] + 0.01, C_BG_INPUT[3] + 0.01, 0.55)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    row.highlight = SolidTexture(row, "ARTWORK", C_ROW_HL, 0.78)
    row.highlight:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -3)
    row.highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -3, 3)
    row.highlight:Hide()

    row.indexText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.indexText:SetPoint("LEFT", row, "LEFT", 12, 0)
    row.indexText:SetWidth(28)
    row.indexText:SetJustifyH("CENTER")

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetWidth(24)
    row.icon:SetHeight(24)
    row.icon:SetPoint("LEFT", row, "LEFT", 52, 0)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.entryText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.entryText:SetPoint("LEFT", row, "LEFT", 95, 0)
    row.entryText:SetWidth(100)
    row.entryText:SetJustifyH("LEFT")

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetPoint("LEFT", row, "LEFT", 210, 0)
    row.nameText:SetWidth(280)
    row.nameText:SetJustifyH("LEFT")

    row.amountText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.amountText:SetPoint("LEFT", row, "LEFT", 510, 0)
    row.amountText:SetWidth(80)
    row.amountText:SetJustifyH("CENTER")

    row.chanceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.chanceText:SetPoint("LEFT", row, "LEFT", 605, 0)
    row.chanceText:SetWidth(90)
    row.chanceText:SetJustifyH("CENTER")

    row.durationText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.durationText:SetPoint("LEFT", row, "LEFT", 705, 0)
    row.durationText:SetWidth(60)
    row.durationText:SetJustifyH("CENTER")

    -- Botón de engranaje para edición rápida.
    local gear = CreateFrame("Button", nil, row)
    gear:SetWidth(22)
    gear:SetHeight(22)
    gear:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    local gearTex = gear:CreateTexture(nil, "ARTWORK")
    gearTex:SetAllPoints(gear)
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearTex:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)

    gear:SetScript("OnEnter", function(self)
        gearTex:SetVertexColor(1, 1, 0.4, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Editar este item", 1, 1, 1)
        GameTooltip:AddLine("Click para seleccionar y cargar valores en el editor.",
                            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    gear:SetScript("OnLeave", function()
        gearTex:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)
        GameTooltip:Hide()
    end)
    gear:SetScript("OnClick", function()
        if row.item then SelectItem(row.item) end
    end)

    row:SetScript("OnClick", function(self)
        if self.item then SelectItem(self.item) end
    end)
    row:SetScript("OnEnter", function(self)
        if self.item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. tostring(self.item.entry))
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

------------------------------------------------------------
-- Construcción de la ventana (un solo frame).
------------------------------------------------------------

local function CreateWindow()
    if UI.frame then return end

    local frame = CreateFrame("Frame", "ClancyChestSystemFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    ApplyBackdrop(frame, C_BG_DEEP, 0.97, C_GOLD, 18)
    UI.frame = frame

    -- Emblema del cofre (icono enmarcado, esquina superior izquierda).
    local emblemBg = CreateFrame("Frame", nil, frame)
    emblemBg:SetWidth(64)
    emblemBg:SetHeight(64)
    emblemBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    ApplyBackdrop(emblemBg, C_BG_PANEL, 0.95, C_GOLD, 12)

    local chestIcon = emblemBg:CreateTexture(nil, "ARTWORK")
    chestIcon:SetTexture("Interface\\Icons\\INV_Crate_04")
    chestIcon:SetPoint("CENTER", emblemBg, "CENTER", 0, 0)
    chestIcon:SetWidth(48)
    chestIcon:SetHeight(48)
    chestIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Título.
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", frame, "TOP", 0, -22)
    title:SetText(CC_GOLD .. "Clancy Chest System|r")

    local titleUL = SolidTexture(frame, "ARTWORK", C_GOLD, 0.65)
    titleUL:SetPoint("TOP", title, "BOTTOM", 0, -4)
    titleUL:SetWidth(360)
    titleUL:SetHeight(1)

    -- Botón de cierre rojo.
    local close = CreateFrame("Button", nil, frame)
    close:SetWidth(36)
    close:SetHeight(36)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -16)

    close:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    StyleButton(close, false)

    local closeX = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeX:SetPoint("CENTER", close, "CENTER", 0, 0)
    closeX:SetText("|cffff5050X|r")

    close:SetScript("OnEnter", function(self) StyleButton(self, true) end)
    close:SetScript("OnLeave", function(self) StyleButton(self, false) end)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Línea separadora bajo el header.
    local headerSep = SolidTexture(frame, "ARTWORK", C_GOLD, 0.55)
    headerSep:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -106)
    headerSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -106)
    headerSep:SetHeight(1)

    ------------------------------------------------------------
    -- Status bar.
    ------------------------------------------------------------

    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 130, -76)
    statusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -76)
    statusBar:SetHeight(28)

    UI.statusDot = statusBar:CreateTexture(nil, "ARTWORK")
    UI.statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    UI.statusDot:SetWidth(14)
    UI.statusDot:SetHeight(14)
    UI.statusDot:SetPoint("LEFT", statusBar, "LEFT", 0, 0)

    UI.statusValue = MakeStatusItem(statusBar, "Estado", "INACTIVO", 22)

    StatusVerticalSep(statusBar, 230)

    UI.chestValue = MakeStatusItem(statusBar, "Cofres", "0/0", 250)

    StatusVerticalSep(statusBar, 410)

    local hourglass = statusBar:CreateTexture(nil, "ARTWORK")
    hourglass:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    hourglass:SetWidth(18)
    hourglass:SetHeight(18)
    hourglass:SetPoint("LEFT", statusBar, "LEFT", 430, 0)
    hourglass:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    hourglass:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)

    local timerLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("LEFT", statusBar, "LEFT", 452, 0)
    timerLabel:SetText(CC_GOLD .. "Tiempo restante:|r")

    UI.timerValue = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    UI.timerValue:SetPoint("LEFT", timerLabel, "RIGHT", 8, 0)
    UI.timerValue:SetText("--:--")

    StatusVerticalSep(statusBar, 660)

    UI.activationValue = MakeStatusItem(statusBar, "Activación", "#0", 680)

    ------------------------------------------------------------
    -- Configuración.
    ------------------------------------------------------------

    local configPanel = MakePanel(frame, 24, -120, FRAME_WIDTH - 48, 158)
    UI.configPanel = configPanel

    MakeSectionTitle(configPanel, "CONFIGURACIÓN")

    local inputPanel = CreateFrame("Frame", nil, configPanel)
    inputPanel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 14, -32)
    inputPanel:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -14, -32)
    inputPanel:SetHeight(60)
    ApplyBackdrop(inputPanel, C_BG_INPUT, 0.95, C_GOLD_DARK, 12)

    UI.itemBox     = MakeSpinnerEdit(inputPanel, "Item ID",      18,  -8, 200, "",   true)
    UI.countBox    = MakeSpinnerEdit(inputPanel, "Cantidad",    230,  -8, 180, "1",  false)
    UI.chanceBox   = MakeSpinnerEdit(inputPanel, "Chance %",    430,  -8, 200, "100", false)
    UI.durationBox = MakeSpinnerEdit(inputPanel, "Duración min.", 650, -8, 200, "10",  false)

    -- Botones de acción.
    local btnY = -100
    local btnW = 116
    local function btnX(idx) return 14 + idx * (btnW + 6) end

    UI.addButton = MakeButton(configPanel, "Añadir", "plus", btnX(0), btnY, btnW, false, function()
        local entry  = tonumber(UI.itemBox:GetText()) or 0
        local amount = tonumber(UI.countBox:GetText()) or 0
        local chance = tonumber(UI.chanceBox:GetText()) or 100
        AIO.Handle(HANDLER, "AddItem", entry, amount, chance)
    end)

    UI.removeButton = MakeButton(configPanel, "Quitar", "minus", btnX(1), btnY, btnW, false, function()
        local entry  = tonumber(UI.itemBox:GetText()) or selectedItemEntry or 0
        local amount = tonumber(UI.countBox:GetText()) or 0
        AIO.Handle(HANDLER, "RemoveItem", entry, amount)
    end)

    UI.deleteButton = MakeButton(configPanel, "Eliminar", "trash", btnX(2), btnY, btnW, false, function()
        local entry = tonumber(UI.itemBox:GetText()) or selectedItemEntry or 0
        AIO.Handle(HANDLER, "RemoveItem", entry, 0)
    end)

    UI.clearButton = MakeButton(configPanel, "Limpiar", "broom", btnX(3), btnY, btnW, false, function()
        AIO.Handle(HANDLER, "ClearStock")
    end)

    UI.startButton = MakeButton(configPanel, "Activar", "play", btnX(4), btnY, btnW, false, function()
        local duration = tonumber(UI.durationBox:GetText()) or 10
        AIO.Handle(HANDLER, "Start", duration)
    end)

    UI.stopButton = MakeButton(configPanel, "Parar", "stop", btnX(5), btnY, btnW, false, function()
        AIO.Handle(HANDLER, "Stop")
    end)

    UI.refreshButton = MakeButton(configPanel, "Refrescar", "refresh", btnX(6), btnY, btnW, true, function()
        AIO.Handle(HANDLER, "RequestOpen")
    end)

    ------------------------------------------------------------
    -- Item seleccionado.
    ------------------------------------------------------------

    local selectedPanel = MakePanel(frame, 24, -286, FRAME_WIDTH - 48, 108)
    UI.selectedPanel = selectedPanel

    MakeSectionTitle(selectedPanel, "ITEM SELECCIONADO")

    local card = CreateFrame("Frame", nil, selectedPanel)
    card:SetPoint("TOPLEFT", selectedPanel, "TOPLEFT", 14, -34)
    card:SetPoint("TOPRIGHT", selectedPanel, "TOPRIGHT", -14, -34)
    card:SetHeight(60)
    ApplyBackdrop(card, C_BG_INPUT, 0.95, C_GOLD_DARK, 12)

    UI.selectedIcon = card:CreateTexture(nil, "OVERLAY")
    UI.selectedIcon:SetWidth(46)
    UI.selectedIcon:SetHeight(46)
    UI.selectedIcon:SetPoint("LEFT", card, "LEFT", 14, 0)
    UI.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    UI.selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local function MakeCardField(label, x, w, justify)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", x, -8)
        lbl:SetWidth(w)
        lbl:SetJustifyH(justify or "LEFT")
        lbl:SetText(CC_GOLD .. label .. "|r")

        local val = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        val:SetPoint("TOPLEFT", card, "TOPLEFT", x, -32)
        val:SetWidth(w)
        val:SetJustifyH(justify or "LEFT")
        return val
    end

    UI.selectedItemId   = MakeCardField("Item ID",  78,  100, "LEFT")
    UI.selectedItemId:SetText("-")

    UI.selectedName     = MakeCardField("Nombre",   200, 240, "LEFT")
    UI.selectedName:SetText(CC_GOLD .. "Ningún item seleccionado|r")

    UI.selectedAmount   = MakeCardField("Cantidad", 480, 90,  "CENTER")
    UI.selectedAmount:SetText("-")

    UI.selectedChance   = MakeCardField("Chance",   590, 90,  "CENTER")
    UI.selectedChance:SetText("-")

    UI.selectedDuration = MakeCardField("Duración", 700, 110, "CENTER")
    UI.selectedDuration:SetText("-")

    ------------------------------------------------------------
    -- Lista de items configurados.
    ------------------------------------------------------------

    local listPanel = MakePanel(frame, 24, -400, FRAME_WIDTH - 48, 232)
    UI.listPanel = listPanel

    UI.listTitle = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.listTitle:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 16, -8)
    UI.listTitle:SetText(CC_GOLD_SOFT .. "ITEMS CONFIGURADOS (0)|r")

    local stripe = SolidTexture(listPanel, "BORDER", C_GOLD, 0.55)
    stripe:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -22)
    stripe:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -22)
    stripe:SetHeight(1)

    local headerRow = CreateFrame("Frame", nil, listPanel)
    headerRow:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -32)
    headerRow:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -32)
    headerRow:SetHeight(28)

    local function MakeHeaderLabel(text, x, w, justify)
        local fs = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", headerRow, "LEFT", x, 0)
        fs:SetWidth(w)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(CC_GOLD .. text .. "|r")
    end

    MakeHeaderLabel("#",                12,  28,  "CENTER")
    MakeHeaderLabel("Item ID",          95,  100, "LEFT")
    MakeHeaderLabel("Nombre",           210, 280, "LEFT")
    MakeHeaderLabel("Cantidad",         510, 80,  "CENTER")
    MakeHeaderLabel("Chance %",         605, 90,  "CENTER")
    MakeHeaderLabel("Duración (min.)",  695, 110, "CENTER")

    local headerLine = SolidTexture(listPanel, "ARTWORK", C_GOLD_DARK, 0.7)
    headerLine:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -62)
    headerLine:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -62)
    headerLine:SetHeight(1)

    local rowsContainer = CreateFrame("Frame", nil, listPanel)
    rowsContainer:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -68)
    rowsContainer:SetWidth(800)
    rowsContainer:SetHeight((ROW_HEIGHT + 2) * NUM_VISIBLE_ROWS)
    UI.rowsContainer = rowsContainer

    UI.emptyText = rowsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    UI.emptyText:SetPoint("CENTER", rowsContainer, "CENTER", 0, 0)
    UI.emptyText:SetText("No hay items configurados.")

    UI.scrollFrame = CreateFrame("ScrollFrame", "ClancyChestSystemScrollFrame",
                                 listPanel, "FauxScrollFrameTemplate")
    UI.scrollFrame:SetPoint("TOPRIGHT",    listPanel, "TOPRIGHT",    -22, -68)
    UI.scrollFrame:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -22, 14)
    UI.scrollFrame:SetWidth(20)

    UI.rows = {}

    for i = 1, NUM_VISIBLE_ROWS do
        UI.rows[i] = CreateListRow(rowsContainer, i)
    end

    UI.scrollFrame.update = RefreshRows

    UI.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT + 2, self.update)
    end)

    -- Tick para refrescar el timer cada segundo.
    frame:SetScript("OnUpdate", function()
        local now = GetTime()

        if now - lastStatusUpdate >= 1 then
            lastStatusUpdate = now
            UpdateHeaderStatus()
        end
    end)

    frame:Hide()

    D("Ventana creada (single-frame).")
end

------------------------------------------------------------
-- Handlers AIO.
------------------------------------------------------------

function ClancyChestSystem.OpenAdminPayload(...)
    D("OpenAdminPayload recibido.")

    local payload = FindPayload(...)

    if not payload then
        D("OpenAdminPayload cancelado: payload nil.")
        return
    end

    CreateWindow()

    local parts = SplitPayload(payload)

    ApplySnapshotData(
        parts[1] or 0,
        parts[2] or 0,
        parts[3] or 0,
        parts[4] or 0,
        parts[5] or 0,
        parts[6] or ""
    )

    if UI.frame then UI.frame:Show() end
end

function ClancyChestSystem.OpenAdmin(...)
    D("OpenAdmin viejo recibido. Ignorado. Usa OpenAdminPayload.")
end

function ClancyChestSystem.Refresh(...)
    D("Refresh viejo recibido. Ignorado. Usa OpenAdminPayload.")
end

------------------------------------------------------------
-- Slash commands.
------------------------------------------------------------

SLASH_CLANCYCHESTSYSTEM1 = "/clancychest"
SLASH_CLANCYCHESTSYSTEM2 = "/cofreclancy"

SlashCmdList["CLANCYCHESTSYSTEM"] = function()
    D("Slash usado. Enviando RequestOpen al servidor.")
    AIO.Handle(HANDLER, "RequestOpen")
end
