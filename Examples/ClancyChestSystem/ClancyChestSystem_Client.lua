-- ClancyChestSystem_Client.lua
-- Cliente AIO con interfaz visual ornamentada estilo WoW (oro + cofre).
-- Handler: ClancyChestSystem
-- Compatible con servidor PAYLOAD:
--   active <<CLANCYSEP>> activationId <<CLANCYSEP>> remaining
--     <<CLANCYSEP>> totalChests <<CLANCYSEP>> lootedChests <<CLANCYSEP>> itemsText

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

local HANDLER = "ClancyChestSystem"
local PAYLOAD_SEP = "<<CLANCYSEP>>"
local DEBUG = true

local FRAME_WIDTH = 920
local FRAME_HEIGHT = 660

local NUM_VISIBLE_ROWS = 5
local ROW_HEIGHT = 36

-- Paleta de colores del marco dorado.
local C_GOLD          = { r = 0.95, g = 0.74, b = 0.22 }
local C_GOLD_DARK     = { r = 0.70, g = 0.50, b = 0.10 }
local C_BG_DEEP       = { r = 0.04, g = 0.03, b = 0.02 }
local C_BG_PANEL      = { r = 0.06, g = 0.05, b = 0.03 }
local C_BG_INPUT      = { r = 0.02, g = 0.02, b = 0.02 }
local C_RED_BUTTON    = { r = 0.45, g = 0.06, b = 0.05 }
local C_RED_HIGHLIGHT = { r = 0.55, g = 0.04, b = 0.02 }
local C_GREEN_OK      = "|cff44dd33"
local C_RED_OFF       = "|cffff3333"
local C_GOLD_TEXT     = "|cffffcc66"
local C_GOLD_BRIGHT   = "|cffffd34a"

local function D(msg)
    if DEBUG then
        print("|cff00ccff[ClancyChestSystem CLIENT]|r " .. tostring(msg))
    end
end

D("Cliente visual ornamentado cargado.")

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
-- Parser de payload del servidor.
------------------------------------------------------------

local function FindPayload(...)
    local argCount = select("#", ...)

    for i = 1, argCount do
        local value = select(i, ...)
        local text = tostring(value or "")

        if string.find(text, PAYLOAD_SEP, 1, true) then
            return text
        end
    end

    D("No se encontró payload. Args recibidos=" .. tostring(argCount))

    for i = 1, argCount do
        D("Arg #" .. tostring(i) .. " = " .. tostring(select(i, ...)))
    end

    return nil
end

local function SplitPayload(payload)
    payload = tostring(payload or "")

    local parts = {}
    local startPos = 1

    while true do
        local sepStart, sepEnd = string.find(payload, PAYLOAD_SEP, startPos, true)

        if not sepStart then
            table.insert(parts, string.sub(payload, startPos))
            break
        end

        table.insert(parts, string.sub(payload, startPos, sepStart - 1))
        startPos = sepEnd + 1
    end

    return parts
end

local function SplitLines(text)
    text = tostring(text or "")
    local lines = {}

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
    local lines = SplitLines(itemsText)

    for _, line in ipairs(lines) do
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
                entry = tonumber(entry) or 0,
                amount = tonumber(amount) or 0,
                chance = tonumber(chance) or 100,
                name = tostring(name or ("Item " .. tostring(entry))),
                text = line
            })
        end
    end

    table.sort(result, function(a, b)
        return a.entry < b.entry
    end)

    return result
end

local function FormatRemaining(seconds)
    seconds = tonumber(seconds) or 0

    if seconds < 0 then
        seconds = 0
    end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    if h > 0 then
        return string.format("%02dh %02dm %02ds", h, m, s)
    end

    return string.format("%dm %02ds", m, s)
end

local function GetItemIconPath(itemEntry)
    itemEntry = tonumber(itemEntry) or 0

    if itemEntry > 0 then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemEntry)

        if texture then
            return texture
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetItemQualityColorCode(itemEntry)
    itemEntry = tonumber(itemEntry) or 0

    if itemEntry <= 0 then
        return "|cffffffff"
    end

    local _, _, quality = GetItemInfo(itemEntry)

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
-- Helpers visuales: backdrops, paneles, etiquetas, inputs.
------------------------------------------------------------

local function SolidTexture(parent, layer, r, g, b, a)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetVertexColor(r, g, b, a or 1)
    return tex
end

local function MakeOuterFrameBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 18,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    frame:SetBackdropColor(C_BG_DEEP.r, C_BG_DEEP.g, C_BG_DEEP.b, 0.97)
    frame:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)
end

local function MakePanelBackdrop(frame, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    frame:SetBackdropColor(C_BG_PANEL.r, C_BG_PANEL.g, C_BG_PANEL.b, alpha or 0.78)
    frame:SetBackdropBorderColor(C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 1)
end

local function MakeInputBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    frame:SetBackdropColor(C_BG_INPUT.r, C_BG_INPUT.g, C_BG_INPUT.b, 0.95)
    frame:SetBackdropBorderColor(C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 1)
end

local function MakeRedButtonBackdrop(frame, hovered)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    if hovered then
        frame:SetBackdropColor(0.55, 0.10, 0.06, 0.95)
    else
        frame:SetBackdropColor(C_RED_BUTTON.r, C_RED_BUTTON.g, C_RED_BUTTON.b, 0.95)
    end

    frame:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)
end

local function MakePanel(parent, x, y, width, height, alpha)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(width)
    panel:SetHeight(height)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    MakePanelBackdrop(panel, alpha)
    return panel
end

local function MakeLabel(parent, text, x, y, width, template, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    if width then
        fs:SetWidth(width)
    end

    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")

    return fs
end

local function MakeSectionTitle(panel, text)
    local stripe = panel:CreateTexture(nil, "BORDER")
    stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
    stripe:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
    stripe:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -22)
    stripe:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -22)
    stripe:SetHeight(1)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -8)
    title:SetText(C_GOLD_TEXT .. text .. "|r")
    return title
end

local function MakeStatusSeparator(parent, x)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -2)
    sep:SetWidth(1)
    sep:SetHeight(28)
    return sep
end

------------------------------------------------------------
-- EditBox con flechas (spinner) y opcional botón lupa.
------------------------------------------------------------

local function MakeSpinnerArrow(parent, isUp)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(16)
    btn:SetHeight(11)

    local up = isUp and "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
        or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"

    btn:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
    local nt = btn:GetNormalTexture()
    nt:SetVertexColor(0, 0, 0, 0)

    local arrow = btn:CreateTexture(nil, "ARTWORK")
    arrow:SetAllPoints(btn)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")

    if not isUp then
        arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    end

    btn:SetScript("OnEnter", function(self)
        if isUp then
            arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Down")
        else
            arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Down")
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if isUp then
            arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        else
            arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
        end
    end)

    return btn
end

local function MakeSpinnerEditBox(parent, labelText, x, y, width, defaultText, withSearch)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(C_GOLD_BRIGHT .. labelText .. "|r")

    local boxBg = CreateFrame("Frame", nil, parent)
    boxBg:SetWidth(width + 28)
    boxBg:SetHeight(32)
    boxBg:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 4, y - 22)
    MakeInputBackdrop(boxBg)

    local box = CreateFrame("EditBox", nil, parent)
    box:SetWidth(width - 6)
    box:SetHeight(22)
    box:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 8, -5)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightLarge")
    box:SetTextInsets(2, 2, 0, 0)
    box:SetText(defaultText or "")

    if box.SetNumeric then
        box:SetNumeric(true)
    end

    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Botón opcional con lupa para Item ID.
    if withSearch then
        local search = CreateFrame("Button", nil, parent)
        search:SetWidth(20)
        search:SetHeight(20)
        search:SetPoint("RIGHT", boxBg, "RIGHT", -6, 0)

        local searchTex = search:CreateTexture(nil, "ARTWORK")
        searchTex:SetAllPoints(search)
        searchTex:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
        searchTex:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95)

        search:SetScript("OnEnter", function(self)
            searchTex:SetVertexColor(1, 1, 0.4, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Inspeccionar item", 1, 1, 1)
            GameTooltip:Show()
        end)

        search:SetScript("OnLeave", function()
            searchTex:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95)
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

        box:SetWidth(width - 28)
    else
        -- Si no es search, el editbox usa flechas spinner a la derecha.
        local upBtn = MakeSpinnerArrow(parent, true)
        upBtn:SetPoint("TOPRIGHT", boxBg, "TOPRIGHT", -6, -4)

        local downBtn = MakeSpinnerArrow(parent, false)
        downBtn:SetPoint("BOTTOMRIGHT", boxBg, "BOTTOMRIGHT", -6, 4)

        local function adjust(delta)
            local n = tonumber(box:GetText()) or 0
            n = n + delta

            if n < 0 then
                n = 0
            end

            box:SetText(tostring(n))
        end

        upBtn:SetScript("OnClick", function() adjust(1) end)
        downBtn:SetScript("OnClick", function() adjust(-1) end)

        box:SetWidth(width - 28)
    end

    return box
end

------------------------------------------------------------
-- Botones de acción rojo/dorado con icono.
------------------------------------------------------------

local function MakeIconActionButton(parent, label, iconTexture, iconColor, x, y, width, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 110)
    btn:SetHeight(36)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    MakeRedButtonBackdrop(btn, false)

    -- Icono.
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(18)
    icon:SetHeight(18)
    icon:SetPoint("LEFT", btn, "LEFT", 8, 0)

    if iconTexture then
        icon:SetTexture(iconTexture)
    end

    if iconColor then
        icon:SetVertexColor(iconColor.r or 1, iconColor.g or 1, iconColor.b or 1, 1)
    end

    -- Texto.
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", btn, "LEFT", 30, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    text:SetJustifyH("CENTER")
    text:SetText(C_GOLD_BRIGHT .. label .. "|r")

    btn:SetScript("OnEnter", function(self)
        MakeRedButtonBackdrop(self, true)
        text:SetText("|cffffffff" .. label .. "|r")
    end)

    btn:SetScript("OnLeave", function(self)
        MakeRedButtonBackdrop(self, false)
        text:SetText(C_GOLD_BRIGHT .. label .. "|r")
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

local function MakeRefreshButton(parent, label, x, y, width, onClick)
    -- Estilo gris para "Refrescar".
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 110)
    btn:SetHeight(36)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    btn:SetBackdropColor(0.13, 0.10, 0.07, 0.95)
    btn:SetBackdropBorderColor(C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 1)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(18)
    icon:SetHeight(18)
    icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
    icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", btn, "LEFT", 30, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    text:SetJustifyH("CENTER")
    text:SetText("|cffcccccc" .. label .. "|r")

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.15, 0.10, 0.95)
        text:SetText("|cffffffff" .. label .. "|r")
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.13, 0.10, 0.07, 0.95)
        text:SetText("|cffcccccc" .. label .. "|r")
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

------------------------------------------------------------
-- Emblema circular del cofre (esquina superior izquierda).
------------------------------------------------------------

local function CreateChestEmblem(parent)
    local emblem = CreateFrame("Frame", nil, parent)
    emblem:SetWidth(96)
    emblem:SetHeight(96)
    emblem:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, 14)

    -- Disco dorado (círculo de fondo).
    local ring = emblem:CreateTexture(nil, "BACKGROUND")
    ring:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    ring:SetAllPoints(emblem)
    ring:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.90)

    -- Disco oscuro interno.
    local disk = emblem:CreateTexture(nil, "BORDER")
    disk:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    disk:SetPoint("CENTER", emblem, "CENTER", 0, 0)
    disk:SetWidth(74)
    disk:SetHeight(74)
    disk:SetVertexColor(0.10, 0.07, 0.04, 1)

    -- Estrella de rayos detrás (simulando el "sol" del marco).
    local rays = emblem:CreateTexture(nil, "BACKGROUND")
    rays:SetTexture("Interface\\AchievementFrame\\UI-Achievement-TinyStar")
    rays:SetPoint("CENTER", emblem, "CENTER", 0, 0)
    rays:SetWidth(112)
    rays:SetHeight(112)
    rays:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)

    -- Icono del cofre al centro.
    local chestIcon = emblem:CreateTexture(nil, "ARTWORK")
    chestIcon:SetTexture("Interface\\Icons\\INV_Crate_04")
    chestIcon:SetPoint("CENTER", emblem, "CENTER", 0, 0)
    chestIcon:SetWidth(46)
    chestIcon:SetHeight(46)
    chestIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    return emblem
end

------------------------------------------------------------
-- Status bar con indicador y separadores verticales.
------------------------------------------------------------

local function MakeStatusItem(parent, label, defaultValue, anchorPoint, anchorRel, x, y)
    local box = CreateFrame("Frame", nil, parent)
    box:SetWidth(220)
    box:SetHeight(28)
    box:SetPoint(anchorPoint or "TOPLEFT", parent, anchorRel or "TOPLEFT", x or 0, y or 0)

    local labelText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", box, "LEFT", 0, 0)
    labelText:SetText(C_GOLD_BRIGHT .. label .. ":|r")

    local valueText = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    valueText:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
    valueText:SetText(defaultValue or "-")

    return box, valueText, labelText
end

local function UpdateHeaderStatus()
    if not UI.frame then
        return
    end

    local active = lastSnapshot.active
    local activationId = tonumber(lastSnapshot.activationId) or 0
    local totalChests = tonumber(lastSnapshot.totalChests) or 0
    local lootedChests = tonumber(lastSnapshot.lootedChests) or 0

    if active then
        local elapsed = GetTime() - lastSnapshotClientTime
        local liveRemaining = (tonumber(lastSnapshot.remaining) or 0) - elapsed

        if liveRemaining < 0 then
            liveRemaining = 0
        end

        UI.statusValue:SetText(C_GREEN_OK .. "ACTIVO|r")
        UI.timerValue:SetText(C_GOLD_BRIGHT .. FormatRemaining(liveRemaining) .. "|r")

        if UI.statusDot then
            UI.statusDot:SetVertexColor(0.20, 0.95, 0.30, 1)
        end
    else
        UI.statusValue:SetText(C_RED_OFF .. "INACTIVO|r")
        UI.timerValue:SetText("|cffaaaaaa--:--|r")

        if UI.statusDot then
            UI.statusDot:SetVertexColor(0.95, 0.20, 0.20, 1)
        end
    end

    UI.chestValue:SetText(C_GOLD_BRIGHT .. tostring(lootedChests) .. "/" .. tostring(totalChests) .. "|r")
    UI.activationValue:SetText(C_GOLD_BRIGHT .. "#" .. tostring(activationId) .. "|r")
end

------------------------------------------------------------
-- Selección de item y refresco de filas.
------------------------------------------------------------

local function FindSelectedItem()
    if not selectedItemEntry then
        return nil
    end

    for _, item in ipairs(stockItems) do
        if item.entry == selectedItemEntry then
            return item
        end
    end

    return nil
end

local function UpdateSelectedCard()
    if not UI.selectedPanel then
        return
    end

    local item = FindSelectedItem()

    if not item then
        UI.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        UI.selectedItemId:SetText("-")
        UI.selectedName:SetText(C_GOLD_BRIGHT .. "Ningún item seleccionado|r")
        UI.selectedAmount:SetText("-")
        UI.selectedChance:SetText("-")
        UI.selectedDuration:SetText("-")
        return
    end

    local color = GetItemQualityColorCode(item.entry)

    UI.selectedIcon:SetTexture(GetItemIconPath(item.entry))
    UI.selectedItemId:SetText(tostring(item.entry))
    UI.selectedName:SetText(color .. tostring(item.name or ("Item " .. tostring(item.entry))) .. "|r")
    UI.selectedAmount:SetText(tostring(item.amount))
    UI.selectedChance:SetText("|cff66ff33" .. tostring(item.chance) .. "%|r")
    UI.selectedDuration:SetText(tostring(UI.durationBox and UI.durationBox:GetText() or "-") .. " min.")
end

local function SelectItem(item)
    if not item or not item.entry or item.entry <= 0 then
        return
    end

    selectedItemEntry = item.entry

    if UI.itemBox then
        UI.itemBox:SetText(tostring(item.entry))
    end

    if UI.countBox then
        UI.countBox:SetText(tostring(item.amount))
    end

    if UI.chanceBox then
        UI.chanceBox:SetText(tostring(item.chance))
    end

    UpdateSelectedCard()

    if UI.scrollFrame and UI.scrollFrame.update then
        UI.scrollFrame.update()
    end
end

local function RefreshRows()
    if not UI.rows or not UI.scrollFrame then
        return
    end

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
            row.nameText:SetText(color .. tostring(item.name or ("Item " .. tostring(item.entry))) .. "|r")
            row.amountText:SetText(tostring(item.amount))
            row.chanceText:SetText("|cff66ff33" .. tostring(item.chance) .. "%|r")
            row.durationText:SetText(tostring(UI.durationBox and UI.durationBox:GetText() or "-"))

            if selectedItemEntry and selectedItemEntry == item.entry then
                row.highlight:Show()
                row.selectedBorder:Show()
            else
                row.highlight:Hide()
                row.selectedBorder:Hide()
            end
        else
            row.item = nil
            row:Hide()
        end
    end

    if UI.emptyText then
        if #stockItems <= 0 then
            UI.emptyText:Show()
        else
            UI.emptyText:Hide()
        end
    end
end

local function RebuildStockData(itemsText)
    stockItems = ParseStockItems(itemsText)

    local selectedStillExists = false

    if selectedItemEntry then
        for _, item in ipairs(stockItems) do
            if item.entry == selectedItemEntry then
                selectedStillExists = true
                break
            end
        end
    end

    if not selectedStillExists then
        selectedItemEntry = nil
    end

    if UI.listTitle then
        UI.listTitle:SetText(C_GOLD_TEXT .. "ITEMS CONFIGURADOS (" .. tostring(#stockItems) .. ")|r")
    end

    RefreshRows()
    UpdateSelectedCard()
end

------------------------------------------------------------
-- Construcción de la fila de la lista de items.
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

    -- Fondo sutil alterno.
    local bgTex = SolidTexture(row, "BACKGROUND",
        C_BG_INPUT.r + 0.01, C_BG_INPUT.g + 0.01, C_BG_INPUT.b + 0.01, 0.55)
    bgTex:SetAllPoints(row)

    -- Highlight rojizo cuando está seleccionada.
    row.highlight = SolidTexture(row, "ARTWORK",
        C_RED_HIGHLIGHT.r, C_RED_HIGHLIGHT.g, C_RED_HIGHLIGHT.b, 0.78)
    row.highlight:SetAllPoints(row)
    row.highlight:Hide()

    -- Borde dorado fino al estar seleccionada.
    row.selectedBorder = CreateFrame("Frame", nil, row)
    row.selectedBorder:SetAllPoints(row)
    row.selectedBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row.selectedBorder:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
    row.selectedBorder:Hide()

    -- Línea inferior dorada sutil.
    local underline = SolidTexture(row, "BORDER",
        C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 0.30)
    underline:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
    underline:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
    underline:SetHeight(1)

    -- Columna #.
    row.indexText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.indexText:SetPoint("LEFT", row, "LEFT", 12, 0)
    row.indexText:SetWidth(28)
    row.indexText:SetJustifyH("CENTER")

    -- Marco del icono.
    local iconBg = CreateFrame("Frame", nil, row)
    iconBg:SetWidth(28)
    iconBg:SetHeight(28)
    iconBg:SetPoint("LEFT", row, "LEFT", 50, 0)
    MakeInputBackdrop(iconBg)

    row.icon = iconBg:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(22)
    row.icon:SetHeight(22)
    row.icon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Item ID.
    row.entryText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.entryText:SetPoint("LEFT", row, "LEFT", 95, 0)
    row.entryText:SetWidth(100)
    row.entryText:SetJustifyH("LEFT")

    -- Nombre.
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetPoint("LEFT", row, "LEFT", 210, 0)
    row.nameText:SetWidth(280)
    row.nameText:SetJustifyH("LEFT")

    -- Cantidad.
    row.amountText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.amountText:SetPoint("LEFT", row, "LEFT", 510, 0)
    row.amountText:SetWidth(80)
    row.amountText:SetJustifyH("CENTER")

    -- Chance.
    row.chanceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.chanceText:SetPoint("LEFT", row, "LEFT", 605, 0)
    row.chanceText:SetWidth(90)
    row.chanceText:SetJustifyH("CENTER")

    -- Duración.
    row.durationText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.durationText:SetPoint("LEFT", row, "LEFT", 705, 0)
    row.durationText:SetWidth(60)
    row.durationText:SetJustifyH("CENTER")

    -- Botón de engranaje (acciones rápidas).
    local gear = CreateFrame("Button", nil, row)
    gear:SetWidth(22)
    gear:SetHeight(22)
    gear:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    local gearTex = gear:CreateTexture(nil, "ARTWORK")
    gearTex:SetAllPoints(gear)
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearTex:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)

    gear:SetScript("OnEnter", function(self)
        gearTex:SetVertexColor(1, 1, 0.4, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Editar este item", 1, 1, 1)
        GameTooltip:AddLine("Click para seleccionar y cargar valores en el editor.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    gear:SetScript("OnLeave", function()
        gearTex:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
        GameTooltip:Hide()
    end)

    gear:SetScript("OnClick", function()
        if row.item then
            SelectItem(row.item)
        end
    end)

    row.gear = gear

    row:SetScript("OnClick", function(self)
        if self.item then
            SelectItem(self.item)
        end
    end)

    row:SetScript("OnEnter", function(self)
        if self.item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. tostring(self.item.entry))
            GameTooltip:Show()
        end
    end)

    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return row
end

local function ApplySnapshotData(active, activationId, remaining, totalChests, lootedChests, itemsText)
    lastSnapshot = {
        active = active == true or active == 1 or active == "1",
        activationId = tonumber(activationId) or 0,
        remaining = tonumber(remaining) or 0,
        totalChests = tonumber(totalChests) or 0,
        lootedChests = tonumber(lootedChests) or 0,
        itemsText = tostring(itemsText or "")
    }

    lastSnapshotClientTime = GetTime()

    UpdateHeaderStatus()
    RebuildStockData(lastSnapshot.itemsText)
end

------------------------------------------------------------
-- Construcción completa de la ventana.
------------------------------------------------------------

local function CreateWindow()
    if UI.frame then
        return
    end

    -- Marco principal con borde dorado.
    local frame = CreateFrame("Frame", "ClancyChestSystemFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    MakeOuterFrameBackdrop(frame)
    UI.frame = frame

    -- Borde dorado interno (segunda línea para efecto "ornamentado").
    local innerBorder = CreateFrame("Frame", nil, frame)
    innerBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    innerBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    innerBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    innerBorder:SetBackdropBorderColor(C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 0.85)

    -- Esquinas decorativas (estrellas).
    local function AddCornerStar(point, dx, dy)
        local star = frame:CreateTexture(nil, "OVERLAY")
        star:SetTexture("Interface\\AchievementFrame\\UI-Achievement-TinyStar")
        star:SetWidth(28)
        star:SetHeight(28)
        star:SetPoint(point, frame, point, dx, dy)
        star:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
        return star
    end

    AddCornerStar("TOPLEFT", 4, -4)
    AddCornerStar("TOPRIGHT", -4, -4)
    AddCornerStar("BOTTOMLEFT", 4, 4)
    AddCornerStar("BOTTOMRIGHT", -4, 4)

    -- Gema central inferior.
    local gem = frame:CreateTexture(nil, "OVERLAY")
    gem:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    gem:SetWidth(20)
    gem:SetHeight(20)
    gem:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    gem:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95)

    -- Emblema circular del cofre.
    CreateChestEmblem(frame)

    -- Título principal.
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", frame, "TOP", 0, -22)
    title:SetText(C_GOLD_BRIGHT .. "Clancy Chest System|r")

    -- Subrayado dorado bajo el título.
    local titleUnderline = SolidTexture(frame, "ARTWORK",
        C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65)
    titleUnderline:SetPoint("TOP", title, "BOTTOM", 0, -4)
    titleUnderline:SetWidth(360)
    titleUnderline:SetHeight(1)

    -- Botón de cerrar rojo decorado.
    local close = CreateFrame("Button", nil, frame)
    close:SetWidth(36)
    close:SetHeight(36)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    MakeRedButtonBackdrop(close, false)

    local closeX = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeX:SetPoint("CENTER", close, "CENTER", 0, 0)
    closeX:SetText("|cffff5050X|r")

    close:SetScript("OnEnter", function(self)
        MakeRedButtonBackdrop(self, true)
    end)

    close:SetScript("OnLeave", function(self)
        MakeRedButtonBackdrop(self, false)
    end)

    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Línea separadora bajo header.
    local headerSep = SolidTexture(frame, "ARTWORK",
        C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
    headerSep:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -116)
    headerSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -116)
    headerSep:SetHeight(1)

    ------------------------------------------------------------
    -- Status bar (Estado / Cofres / Tiempo / Activación).
    ------------------------------------------------------------

    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 130, -78)
    statusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -78)
    statusBar:SetHeight(36)

    -- Indicador circular de estado.
    UI.statusDot = statusBar:CreateTexture(nil, "ARTWORK")
    UI.statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    UI.statusDot:SetWidth(14)
    UI.statusDot:SetHeight(14)
    UI.statusDot:SetPoint("LEFT", statusBar, "LEFT", 0, 0)

    local _, statusVal = MakeStatusItem(statusBar, "Estado", "INACTIVO", "LEFT", "LEFT", 22, 0)
    UI.statusValue = statusVal

    MakeStatusSeparator(statusBar, 230)

    local _, chestVal = MakeStatusItem(statusBar, "Cofres", "0/0", "LEFT", "LEFT", 250, 0)
    UI.chestValue = chestVal

    MakeStatusSeparator(statusBar, 410)

    -- Hourglass icon.
    local hourglass = statusBar:CreateTexture(nil, "ARTWORK")
    hourglass:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    hourglass:SetWidth(18)
    hourglass:SetHeight(18)
    hourglass:SetPoint("LEFT", statusBar, "LEFT", 430, 0)
    hourglass:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    hourglass:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)

    local timerLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("LEFT", statusBar, "LEFT", 452, 0)
    timerLabel:SetText(C_GOLD_BRIGHT .. "Tiempo restante:|r")

    UI.timerValue = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    UI.timerValue:SetPoint("LEFT", timerLabel, "RIGHT", 8, 0)
    UI.timerValue:SetText("--:--")

    MakeStatusSeparator(statusBar, 660)

    local _, activationVal = MakeStatusItem(statusBar, "Activación", "#0", "LEFT", "LEFT", 680, 0)
    UI.activationValue = activationVal

    ------------------------------------------------------------
    -- Panel de configuración.
    ------------------------------------------------------------

    local configPanel = MakePanel(frame, 24, -130, FRAME_WIDTH - 48, 158, 0.82)
    UI.configPanel = configPanel

    MakeSectionTitle(configPanel, "CONFIGURACIÓN")

    local inputPanel = CreateFrame("Frame", nil, configPanel)
    inputPanel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 14, -32)
    inputPanel:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -14, -32)
    inputPanel:SetHeight(60)
    MakeInputBackdrop(inputPanel)

    UI.itemBox = MakeSpinnerEditBox(inputPanel, "Item ID", 18, -8, 200, "", true)
    UI.countBox = MakeSpinnerEditBox(inputPanel, "Cantidad", 230, -8, 180, "1", false)
    UI.chanceBox = MakeSpinnerEditBox(inputPanel, "Chance %", 430, -8, 200, "100", false)
    UI.durationBox = MakeSpinnerEditBox(inputPanel, "Duración min.", 650, -8, 200, "10", false)

    -- Fila de botones de acción.
    local btnRowY = -100
    local btnWidth = 116

    UI.addButton = MakeIconActionButton(
        configPanel,
        "Añadir",
        "Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent",
        { r = 0.55, g = 1.0, b = 0.45 },
        14, btnRowY, btnWidth,
        function()
            local itemEntry = tonumber(UI.itemBox:GetText()) or 0
            local amount = tonumber(UI.countBox:GetText()) or 0
            local chance = tonumber(UI.chanceBox:GetText()) or 100

            AIO.Handle(HANDLER, "AddItem", itemEntry, amount, chance)
        end
    )

    -- Override Añadir icon to a "+" rendered via fontstring (no native + texture).
    do
        local plus = UI.addButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        plus:SetPoint("LEFT", UI.addButton, "LEFT", 10, 0)
        plus:SetText("|cff66ff33+|r")
    end

    UI.removeButton = MakeIconActionButton(
        configPanel,
        "Quitar",
        nil,
        nil,
        14 + (btnWidth + 6), btnRowY, btnWidth,
        function()
            local itemEntry = tonumber(UI.itemBox:GetText()) or selectedItemEntry or 0
            local amount = tonumber(UI.countBox:GetText()) or 0

            AIO.Handle(HANDLER, "RemoveItem", itemEntry, amount)
        end
    )

    do
        local minus = UI.removeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        minus:SetPoint("LEFT", UI.removeButton, "LEFT", 12, 0)
        minus:SetText("|cffff8888—|r")
    end

    UI.deleteButton = MakeIconActionButton(
        configPanel,
        "Eliminar",
        "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        { r = 1.0, g = 0.45, b = 0.30 },
        14 + 2 * (btnWidth + 6), btnRowY, btnWidth,
        function()
            local itemEntry = tonumber(UI.itemBox:GetText()) or selectedItemEntry or 0

            AIO.Handle(HANDLER, "RemoveItem", itemEntry, 0)
        end
    )

    UI.clearButton = MakeIconActionButton(
        configPanel,
        "Limpiar",
        nil,
        nil,
        14 + 3 * (btnWidth + 6), btnRowY, btnWidth,
        function()
            AIO.Handle(HANDLER, "ClearStock")
        end
    )

    do
        local broom = UI.clearButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        broom:SetPoint("LEFT", UI.clearButton, "LEFT", 10, 0)
        broom:SetText(C_GOLD_BRIGHT .. "✦|r")
    end

    UI.startButton = MakeIconActionButton(
        configPanel,
        "Activar",
        nil,
        nil,
        14 + 4 * (btnWidth + 6), btnRowY, btnWidth,
        function()
            local duration = tonumber(UI.durationBox:GetText()) or 10

            AIO.Handle(HANDLER, "Start", duration)
        end
    )

    do
        local play = UI.startButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        play:SetPoint("LEFT", UI.startButton, "LEFT", 12, 0)
        play:SetText(C_GOLD_BRIGHT .. "▶|r")
    end

    UI.stopButton = MakeIconActionButton(
        configPanel,
        "Parar",
        nil,
        nil,
        14 + 5 * (btnWidth + 6), btnRowY, btnWidth,
        function()
            AIO.Handle(HANDLER, "Stop")
        end
    )

    do
        local stop = UI.stopButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        stop:SetPoint("LEFT", UI.stopButton, "LEFT", 12, 0)
        stop:SetText(C_GOLD_BRIGHT .. "■|r")
    end

    UI.refreshButton = MakeRefreshButton(
        configPanel,
        "Refrescar",
        14 + 6 * (btnWidth + 6), btnRowY, btnWidth,
        function()
            AIO.Handle(HANDLER, "RequestOpen")
        end
    )

    ------------------------------------------------------------
    -- Panel de item seleccionado.
    ------------------------------------------------------------

    local selectedPanel = MakePanel(frame, 24, -296, FRAME_WIDTH - 48, 108, 0.78)
    UI.selectedPanel = selectedPanel

    MakeSectionTitle(selectedPanel, "ITEM SELECCIONADO")

    local cardPanel = CreateFrame("Frame", nil, selectedPanel)
    cardPanel:SetPoint("TOPLEFT", selectedPanel, "TOPLEFT", 14, -34)
    cardPanel:SetPoint("TOPRIGHT", selectedPanel, "TOPRIGHT", -14, -34)
    cardPanel:SetHeight(60)
    MakeInputBackdrop(cardPanel)

    -- Marco del icono grande.
    local iconBg = CreateFrame("Frame", nil, cardPanel)
    iconBg:SetWidth(50)
    iconBg:SetHeight(50)
    iconBg:SetPoint("LEFT", cardPanel, "LEFT", 12, 0)
    MakeInputBackdrop(iconBg)
    iconBg:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)

    UI.selectedIcon = iconBg:CreateTexture(nil, "ARTWORK")
    UI.selectedIcon:SetWidth(42)
    UI.selectedIcon:SetHeight(42)
    UI.selectedIcon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    UI.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    UI.selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local function MakeCardField(label, x, valueWidth, justify)
        local lbl = cardPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", cardPanel, "TOPLEFT", x, -8)
        lbl:SetWidth(valueWidth)
        lbl:SetJustifyH(justify or "LEFT")
        lbl:SetText(C_GOLD_BRIGHT .. label .. "|r")

        local val = cardPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        val:SetPoint("TOPLEFT", cardPanel, "TOPLEFT", x, -32)
        val:SetWidth(valueWidth)
        val:SetJustifyH(justify or "LEFT")

        return val
    end

    UI.selectedItemId = MakeCardField("Item ID", 78, 100, "LEFT")
    UI.selectedItemId:SetText("-")

    UI.selectedName = MakeCardField("Nombre", 200, 240, "LEFT")
    UI.selectedName:SetText(C_GOLD_BRIGHT .. "Ningún item seleccionado|r")

    UI.selectedAmount = MakeCardField("Cantidad", 480, 90, "CENTER")
    UI.selectedAmount:SetText("-")

    UI.selectedChance = MakeCardField("Chance", 590, 90, "CENTER")
    UI.selectedChance:SetText("-")

    UI.selectedDuration = MakeCardField("Duración", 700, 110, "CENTER")
    UI.selectedDuration:SetText("-")

    ------------------------------------------------------------
    -- Panel de items configurados (lista con scrollbar).
    ------------------------------------------------------------

    local listPanel = MakePanel(frame, 24, -410, FRAME_WIDTH - 48, 232, 0.78)
    UI.listPanel = listPanel

    UI.listTitle = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.listTitle:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 16, -8)
    UI.listTitle:SetText(C_GOLD_TEXT .. "ITEMS CONFIGURADOS (0)|r")

    local titleStripe = listPanel:CreateTexture(nil, "BORDER")
    titleStripe:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleStripe:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
    titleStripe:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -22)
    titleStripe:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -22)
    titleStripe:SetHeight(1)

    -- Cabecera de columnas.
    local headerPanel = CreateFrame("Frame", nil, listPanel)
    headerPanel:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -32)
    headerPanel:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -32)
    headerPanel:SetHeight(28)

    local function MakeHeaderLabel(text, x, width, justify)
        local fs = headerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", headerPanel, "LEFT", x, 0)
        fs:SetWidth(width)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(C_GOLD_BRIGHT .. text .. "|r")
        return fs
    end

    MakeHeaderLabel("#", 12, 28, "CENTER")
    MakeHeaderLabel("Item ID", 95, 100, "LEFT")
    MakeHeaderLabel("Nombre", 210, 280, "LEFT")
    MakeHeaderLabel("Cantidad", 510, 80, "CENTER")
    MakeHeaderLabel("Chance %", 605, 90, "CENTER")
    MakeHeaderLabel("Duración (min.)", 695, 110, "CENTER")

    -- Línea bajo el header.
    local headerLine = SolidTexture(listPanel, "ARTWORK",
        C_GOLD_DARK.r, C_GOLD_DARK.g, C_GOLD_DARK.b, 0.7)
    headerLine:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -62)
    headerLine:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -62)
    headerLine:SetHeight(1)

    -- Contenedor de filas.
    local rowsContainer = CreateFrame("Frame", nil, listPanel)
    rowsContainer:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -68)
    rowsContainer:SetWidth(800)
    rowsContainer:SetHeight((ROW_HEIGHT + 2) * NUM_VISIBLE_ROWS)
    UI.rowsContainer = rowsContainer

    UI.emptyText = rowsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    UI.emptyText:SetPoint("CENTER", rowsContainer, "CENTER", 0, 0)
    UI.emptyText:SetText("No hay items configurados.")

    UI.scrollFrame = CreateFrame("ScrollFrame", "ClancyChestSystemScrollFrame", listPanel, "FauxScrollFrameTemplate")
    UI.scrollFrame:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -22, -68)
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

    -- Tick visual del status bar (refresco del timer).
    frame:SetScript("OnUpdate", function()
        local now = GetTime()

        if now - lastStatusUpdate >= 1 then
            lastStatusUpdate = now
            UpdateHeaderStatus()
        end
    end)

    frame:Hide()

    D("Ventana ornamentada (Clancy Chest System) creada correctamente.")
end

------------------------------------------------------------
-- AIO handlers (recepción de payload del servidor).
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

    local active = parts[1] or 0
    local activationId = parts[2] or 0
    local remaining = parts[3] or 0
    local totalChests = parts[4] or 0
    local lootedChests = parts[5] or 0
    local itemsText = parts[6] or ""

    ApplySnapshotData(
        active,
        activationId,
        remaining,
        totalChests,
        lootedChests,
        itemsText
    )

    if UI.frame then
        UI.frame:Show()
    end
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
