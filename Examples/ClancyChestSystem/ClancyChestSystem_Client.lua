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
-- 716 = 686 anterior + 30 px que se añaden al configPanel para meter
-- la fila del selector de tipo (item / honor / arena / gold).
local FRAME_HEIGHT      = 716
local NUM_VISIBLE_ROWS  = 5
local ROW_HEIGHT        = 36
local ROW_GAP           = 2
local ROW_STRIDE        = ROW_HEIGHT + ROW_GAP

-- Ancho que ocupa la pista de scroll dentro del list panel (padding
-- derecho + ancho del track + separación con las filas). Lo usan tanto
-- el header como el rowsContainer para que las columnas siempre cuadren.
local LIST_RIGHT_INSET  = 44

-- Definición única de columnas de la lista. Header y filas comparten
-- estos valores para que cualquier ajuste solo se haga en un sitio.
local LIST_ICON_X       = 50
local LIST_ICON_SIZE    = 24
local LIST_COLS = {
    index    = { x = 12,  w = 28,  justify = "CENTER" },
    itemId   = { x = 90,  w = 90,  justify = "LEFT"   },
    name     = { x = 195, w = 280, justify = "LEFT"   },
    amount   = { x = 490, w = 80,  justify = "CENTER" },
    chance   = { x = 580, w = 90,  justify = "CENTER" },
    duration = { x = 680, w = 100, justify = "CENTER" },
}

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

-- Ids "mágicos" reservados para premios que no son items reales.
-- Deben coincidir con los del server: REWARD_HONOR_ID / REWARD_ARENA_ID
-- / REWARD_GOLD_ID. Son uint32 fuera del rango de items reales de WoW
-- 3.3.5 (max ~80000).
local REWARD_HONOR_ID = 4000000001
local REWARD_ARENA_ID = 4000000002
local REWARD_GOLD_ID  = 4000000003

local function GetRewardKindFromEntry(entry)
    entry = tonumber(entry) or 0
    if entry == REWARD_HONOR_ID then return "honor" end
    if entry == REWARD_ARENA_ID then return "arena" end
    if entry == REWARD_GOLD_ID  then return "gold"  end
    return "item"
end

local function NormalizeKind(kind)
    kind = tostring(kind or "item"):lower()
    if kind ~= "item" and kind ~= "honor" and kind ~= "arena" and kind ~= "gold" then
        kind = "item"
    end
    return kind
end

local function GetKindIcon(kind)
    if kind == "honor" then
        return "Interface\\Icons\\Achievement_PVP_A_A"
    elseif kind == "arena" then
        return "Interface\\Icons\\Achievement_arena_5v5_2"
    elseif kind == "gold" then
        return "Interface\\Icons\\INV_Misc_Coin_01"
    end
    return nil
end

local function GetKindLabel(kind)
    if kind == "honor" then return "Puntos de honor" end
    if kind == "arena" then return "Puntos de arena" end
    if kind == "gold"  then return "Oro"             end
    return nil
end

local function ParseStockItems(itemsText)
    local result = {}

    for _, line in ipairs(SplitLines(itemsText)) do
        -- Formato nuevo: <entry>|<kind>|<amount>|<chance>|<name>
        local entry, kind, amount, chance, name = string.match(
            line,
            "^(%d+)|(%w+)|(%d+)|(%d+)|(.+)$"
        )

        if not entry then
            -- Compatibilidad con el formato antiguo:
            -- "<entry> x<amount> [<chance>%] - <name>".
            entry, amount, chance, name = string.match(
                line,
                "^(%d+)%s+x(%d+)%s+%[(%d+)%%%]%s+%-%s+(.+)$"
            )
            kind = "item"
        end

        if not entry then
            entry, amount = string.match(line, "^(%d+)%s+x(%d+)")
            kind = "item"
            chance = "100"
            name = line
        end

        if entry then
            local entryNum = tonumber(entry) or 0
            local resolvedKind = NormalizeKind(kind)

            -- Si el server (un cliente viejo) solo nos manda el entry
            -- pero la entry coincide con un id mágico, deducimos el kind.
            if resolvedKind == "item" then
                local deduced = GetRewardKindFromEntry(entryNum)
                if deduced ~= "item" then
                    resolvedKind = deduced
                    if not name or name == "" then
                        name = GetKindLabel(deduced)
                    end
                end
            end

            table.insert(result, {
                entry  = entryNum,
                kind   = resolvedKind,
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

    -- Para premios que no son items reales (honor / arena / gold) usamos
    -- iconos PVP / dinero en lugar de buscar en GetItemInfo.
    local kindIcon = GetKindIcon(GetRewardKindFromEntry(entry))
    if kindIcon then return kindIcon end

    if entry > 0 then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(entry)

        if texture then return texture end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetItemQualityColorCode(entry)
    entry = tonumber(entry) or 0

    if entry <= 0 then return "|cffffffff" end

    -- Honor / arena / gold no tienen "quality"; les damos un color fijo
    -- coherente con sus iconos.
    local kind = GetRewardKindFromEntry(entry)
    if kind == "honor" then return "|cffff8888" end
    if kind == "arena" then return "|cff66aaff" end
    if kind == "gold"  then return "|cffffd34a" end

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
-- Pill button: pastilla horizontal usada para el selector de tipo
-- de premio (item / honor / arena / gold). Plana, sin edgeFile, para
-- que su contorno NO pueda salirse del frame contenedor.
------------------------------------------------------------

local function MakeTypePill(parent, label, x, y, width, kind)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    btn:SetBackdropColor(C_BG_INPUT[1], C_BG_INPUT[2], C_BG_INPUT[3], 0.9)

    local function MakeEdge(side)
        local tex = SolidTexture(btn, "OVERLAY", C_GOLD_DARK, 1)
        if side == "top" then
            tex:SetPoint("TOPLEFT",  btn, "TOPLEFT",  0, 0)
            tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
            tex:SetHeight(1)
        elseif side == "bottom" then
            tex:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
            tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            tex:SetHeight(1)
        elseif side == "left" then
            tex:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
            tex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
            tex:SetWidth(1)
        elseif side == "right" then
            tex:SetPoint("TOPRIGHT",    btn, "TOPRIGHT",    0, 0)
            tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            tex:SetWidth(1)
        end
        return tex
    end

    btn.borderTop    = MakeEdge("top")
    btn.borderBottom = MakeEdge("bottom")
    btn.borderLeft   = MakeEdge("left")
    btn.borderRight  = MakeEdge("right")

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.label:SetText(label)
    btn.label:SetTextColor(0.85, 0.65, 0.18)

    btn.kind = kind
    btn.selected = false

    btn.SetSelected = function(self, value)
        self.selected = value and true or false

        if self.selected then
            self:SetBackdropColor(C_GOLD_DARK[1] * 0.55, C_GOLD_DARK[2] * 0.55, C_GOLD_DARK[3] * 0.55, 0.95)
            self.borderTop:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
            self.borderBottom:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
            self.borderLeft:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
            self.borderRight:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
            self.label:SetTextColor(1, 1, 1)
        else
            self:SetBackdropColor(C_BG_INPUT[1], C_BG_INPUT[2], C_BG_INPUT[3], 0.9)
            self.borderTop:SetVertexColor(C_GOLD_DARK[1], C_GOLD_DARK[2], C_GOLD_DARK[3], 1)
            self.borderBottom:SetVertexColor(C_GOLD_DARK[1], C_GOLD_DARK[2], C_GOLD_DARK[3], 1)
            self.borderLeft:SetVertexColor(C_GOLD_DARK[1], C_GOLD_DARK[2], C_GOLD_DARK[3], 1)
            self.borderRight:SetVertexColor(C_GOLD_DARK[1], C_GOLD_DARK[2], C_GOLD_DARK[3], 1)
            self.label:SetTextColor(0.85, 0.65, 0.18)
        end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.selected then
            self.label:SetTextColor(1, 0.95, 0.55)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.selected then
            self.label:SetTextColor(0.85, 0.65, 0.18)
        end
    end)

    return btn
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
        icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Buttons\\UI-PaintBrush-Up")
        icon:SetWidth(18)
        icon:SetHeight(18)
        icon:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)
    elseif kind == "play" then
        icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon:SetText(CC_GOLD .. ">|r")
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
        icon:SetPoint("LEFT", btn, "LEFT", 14, 0)
    elseif kind == "play" then
        icon:SetPoint("LEFT", btn, "LEFT", 14, 0)
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

    local kind   = item.kind or GetRewardKindFromEntry(item.entry)
    local color  = GetItemQualityColorCode(item.entry)
    local label  = item.name

    if kind ~= "item" then
        label = GetKindLabel(kind) or label
    end

    UI.selectedIcon:SetTexture(GetItemIconPath(item.entry))
    if kind == "item" then
        UI.selectedItemId:SetText(tostring(item.entry))
    else
        UI.selectedItemId:SetText("—")
    end
    UI.selectedName:SetText(color .. tostring(label) .. "|r")

    if kind == "gold" then
        UI.selectedAmount:SetText(tostring(item.amount) .. "g")
    else
        UI.selectedAmount:SetText(tostring(item.amount))
    end

    UI.selectedChance:SetText(CC_GREEN_PCT .. tostring(item.chance) .. "%|r")
    UI.selectedDuration:SetText(
        tostring(UI.durationBox and UI.durationBox:GetText() or "-") .. " min."
    )
end

local function SyncTypePillsForKind(kind)
    if not UI.typePills then return end
    UI.selectedType = kind
    for _, pill in ipairs(UI.typePills) do
        pill:SetSelected(pill.kind == kind)
    end

    if UI.itemBox then
        if kind == "item" then
            UI.itemBox:EnableMouse(true)
            UI.itemBox:EnableKeyboard(true)
            UI.itemBox:SetTextColor(1, 1, 1)
        else
            UI.itemBox:ClearFocus()
            UI.itemBox:EnableMouse(false)
            UI.itemBox:EnableKeyboard(false)
            UI.itemBox:SetTextColor(0.4, 0.4, 0.4)
        end
    end
end

local function SelectItem(item)
    if not item or not item.entry or item.entry <= 0 then return end

    selectedItemEntry = item.entry

    local kind = item.kind or GetRewardKindFromEntry(item.entry)
    SyncTypePillsForKind(kind)

    if UI.itemBox then
        if kind == "item" then
            UI.itemBox:SetText(tostring(item.entry))
        else
            UI.itemBox:SetText("")
        end
    end
    if UI.countBox then UI.countBox:SetText(tostring(item.amount)) end
    if UI.chanceBox then UI.chanceBox:SetText(tostring(item.chance)) end

    UpdateSelectedCard()

    if UI.scrollFrame and UI.scrollFrame.update then
        UI.scrollFrame.update()
    end
end

local function RefreshRows()
    if not UI.rows or not UI.scrollFrame then return end

    FauxScrollFrame_Update(UI.scrollFrame, #stockItems, NUM_VISIBLE_ROWS, ROW_STRIDE)
    local offset = FauxScrollFrame_GetOffset(UI.scrollFrame)

    for i = 1, NUM_VISIBLE_ROWS do
        local row = UI.rows[i]
        local itemIndex = offset + i
        local item = stockItems[itemIndex]

        if item then
            row.item = item
            row:Show()

            local kind  = item.kind or GetRewardKindFromEntry(item.entry)
            local color = GetItemQualityColorCode(item.entry)
            local label = item.name

            if kind ~= "item" then
                label = GetKindLabel(kind) or label
            end

            row.indexText:SetText(tostring(itemIndex))
            row.icon:SetTexture(GetItemIconPath(item.entry))

            if kind == "item" then
                row.entryText:SetText(tostring(item.entry))
            else
                row.entryText:SetText("—")
            end

            row.nameText:SetText(color .. tostring(label) .. "|r")

            if kind == "gold" then
                row.amountText:SetText(tostring(item.amount) .. "g")
            else
                row.amountText:SetText(tostring(item.amount))
            end

            row.chanceText:SetText(CC_GREEN_PCT .. tostring(item.chance) .. "%|r")
            row.durationText:SetText(
                tostring(UI.durationBox and UI.durationBox:GetText() or "-")
            )

            if selectedItemEntry == item.entry then
                row.highlight:Show()
                row.borderTop:Show()
                row.borderBottom:Show()
                row.borderLeft:Show()
                row.borderRight:Show()
            else
                row.highlight:Hide()
                row.borderTop:Hide()
                row.borderBottom:Hide()
                row.borderLeft:Hide()
                row.borderRight:Hide()
            end
        else
            row.item = nil
            row:Hide()
        end
    end

    if UI.emptyText then
        if #stockItems <= 0 then UI.emptyText:Show() else UI.emptyText:Hide() end
    end

    if UI.UpdateScrollThumb then UI.UpdateScrollThumb() end
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
    row:SetHeight(ROW_HEIGHT)

    if index == 1 then
        row:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    else
        row:SetPoint("TOPLEFT",  UI.rows[index - 1], "BOTTOMLEFT",  0, -ROW_GAP)
        row:SetPoint("TOPRIGHT", UI.rows[index - 1], "BOTTOMRIGHT", 0, -ROW_GAP)
    end

    -- Backdrop SIN edgeFile: la textura de borde "UI-Tooltip-Border" con
    -- edgeSize=10 se dibuja por fuera del frame y empuja la fila hacia el
    -- track de scroll/borde del panel. Usamos solo bgFile y dibujamos el
    -- "borde dorado del seleccionado" con 4 texturas hijas (top/bottom/
    -- left/right) ancladas al ras de la fila. Por construcción, el borde
    -- queda SIEMPRE dentro de los límites de la fila.
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    row:SetBackdropColor(C_BG_INPUT[1] + 0.01, C_BG_INPUT[2] + 0.01, C_BG_INPUT[3] + 0.01, 0.55)

    row.highlight = SolidTexture(row, "ARTWORK", C_ROW_HL, 0.78)
    row.highlight:SetPoint("TOPLEFT",     row, "TOPLEFT",     1, -1)
    row.highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
    row.highlight:Hide()

    local function MakeBorderEdge(side)
        local tex = SolidTexture(row, "OVERLAY", C_GOLD, 0.85)
        tex:Hide()
        if side == "top" then
            tex:SetPoint("TOPLEFT",  row, "TOPLEFT",  0, 0)
            tex:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
            tex:SetHeight(1)
        elseif side == "bottom" then
            tex:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
            tex:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            tex:SetHeight(1)
        elseif side == "left" then
            tex:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
            tex:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
            tex:SetWidth(1)
        elseif side == "right" then
            tex:SetPoint("TOPRIGHT",    row, "TOPRIGHT",    0, 0)
            tex:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            tex:SetWidth(1)
        end
        return tex
    end

    row.borderTop    = MakeBorderEdge("top")
    row.borderBottom = MakeBorderEdge("bottom")
    row.borderLeft   = MakeBorderEdge("left")
    row.borderRight  = MakeBorderEdge("right")

    local function MakeRowText(col)
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", row, "LEFT", col.x, 0)
        fs:SetWidth(col.w)
        fs:SetJustifyH(col.justify)
        return fs
    end

    row.indexText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.indexText:SetPoint("LEFT", row, "LEFT", LIST_COLS.index.x, 0)
    row.indexText:SetWidth(LIST_COLS.index.w)
    row.indexText:SetJustifyH(LIST_COLS.index.justify)

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetWidth(LIST_ICON_SIZE)
    row.icon:SetHeight(LIST_ICON_SIZE)
    row.icon:SetPoint("LEFT", row, "LEFT", LIST_ICON_X, 0)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.entryText    = MakeRowText(LIST_COLS.itemId)
    row.nameText     = MakeRowText(LIST_COLS.name)
    row.amountText   = MakeRowText(LIST_COLS.amount)
    row.chanceText   = MakeRowText(LIST_COLS.chance)
    row.durationText = MakeRowText(LIST_COLS.duration)

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
        if not self.item then return end

        local kind = self.item.kind or GetRewardKindFromEntry(self.item.entry)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if kind == "item" then
            GameTooltip:SetHyperlink("item:" .. tostring(self.item.entry))
        else
            local label = GetKindLabel(kind) or "Premio"
            GameTooltip:SetText(label, 1, 1, 1)
            if kind == "gold" then
                GameTooltip:AddLine(tostring(self.item.amount) .. "g", 1, 0.85, 0.2, true)
            else
                GameTooltip:AddLine(tostring(self.item.amount) .. " puntos", 0.85, 0.85, 0.85, true)
            end
            GameTooltip:AddLine("Chance: " .. tostring(self.item.chance) .. "%", 0.7, 0.95, 0.6, true)
        end

        GameTooltip:Show()
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

    -- Status bar: ampliamos el ancho disponible y redistribuimos las
    -- 4 columnas para que 'Activación: #N' nunca se corte (antes
    -- terminaba a 74 px del borde y los valores grandes se comían al final).
    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  130, -76)
    statusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -76)
    statusBar:SetHeight(28)

    UI.statusDot = statusBar:CreateTexture(nil, "ARTWORK")
    UI.statusDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    UI.statusDot:SetWidth(14)
    UI.statusDot:SetHeight(14)
    UI.statusDot:SetPoint("LEFT", statusBar, "LEFT", 0, 0)

    UI.statusValue = MakeStatusItem(statusBar, "Estado", "INACTIVO", 22)

    StatusVerticalSep(statusBar, 200)

    UI.chestValue = MakeStatusItem(statusBar, "Cofres", "0/0", 220)

    StatusVerticalSep(statusBar, 390)

    local hourglass = statusBar:CreateTexture(nil, "ARTWORK")
    hourglass:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    hourglass:SetWidth(18)
    hourglass:SetHeight(18)
    hourglass:SetPoint("LEFT", statusBar, "LEFT", 410, 0)
    hourglass:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    hourglass:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 1)

    local timerLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("LEFT", statusBar, "LEFT", 432, 0)
    timerLabel:SetText(CC_GOLD .. "Tiempo restante:|r")

    UI.timerValue = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    UI.timerValue:SetPoint("LEFT", timerLabel, "RIGHT", 8, 0)
    UI.timerValue:SetText("--:--")

    StatusVerticalSep(statusBar, 600)

    UI.activationValue = MakeStatusItem(statusBar, "Activación", "#0", 620)

    ------------------------------------------------------------
    -- Configuración.
    ------------------------------------------------------------

    -- 188 = 158 anterior + 30 px que se añaden por la fila del selector
    -- de tipo (item / honor / arena / gold). Todo lo que está dentro
    -- (inputPanel, botones) se baja 30 px respecto al diseño anterior.
    local configPanel = MakePanel(frame, 24, -120, FRAME_WIDTH - 48, 188)
    UI.configPanel = configPanel

    MakeSectionTitle(configPanel, "CONFIGURACIÓN")

    -- Selector de tipo de premio. Las 4 pastillas se reparten de forma
    -- uniforme entre los bordes interiores del configPanel.
    UI.selectedType = "item"
    UI.typePills    = {}

    local pillKinds = {
        { kind = "item",  label = "Item"  },
        { kind = "honor", label = "Honor" },
        { kind = "arena", label = "Arena" },
        { kind = "gold",  label = "Oro"   },
    }

    local pillRowLeft  = 14
    local pillRowRight = (FRAME_WIDTH - 48) - 14
    local pillRowWidth = pillRowRight - pillRowLeft
    local pillGap      = 8
    local pillW        = math.floor((pillRowWidth - pillGap * (#pillKinds - 1)) / #pillKinds)

    local function SelectType(kind)
        UI.selectedType = kind
        for _, pill in ipairs(UI.typePills) do
            pill:SetSelected(pill.kind == kind)
        end

        -- Cuando el tipo no es "item", el editbox de Item ID se vuelve
        -- inerte (lo bloqueamos a teclado/ratón y lo grisamos) porque
        -- el id mágico lo gestiona el server por tipo.
        if UI.itemBox then
            if kind == "item" then
                UI.itemBox:EnableMouse(true)
                UI.itemBox:EnableKeyboard(true)
                UI.itemBox:SetTextColor(1, 1, 1)
            else
                UI.itemBox:ClearFocus()
                UI.itemBox:SetText("")
                UI.itemBox:EnableMouse(false)
                UI.itemBox:EnableKeyboard(false)
                UI.itemBox:SetTextColor(0.4, 0.4, 0.4)
            end
        end
    end

    for i, info in ipairs(pillKinds) do
        local x = pillRowLeft + (i - 1) * (pillW + pillGap)
        local pill = MakeTypePill(configPanel, info.label, x, -30, pillW, info.kind)
        pill:SetScript("OnClick", function()
            SelectType(info.kind)
        end)
        pill:SetSelected(info.kind == UI.selectedType)
        UI.typePills[i] = pill
    end

    local inputPanel = CreateFrame("Frame", nil, configPanel)
    inputPanel:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 14, -62)
    inputPanel:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -14, -62)
    inputPanel:SetHeight(60)
    ApplyBackdrop(inputPanel, C_BG_INPUT, 0.95, C_GOLD_DARK, 12)

    -- Cuatro columnas iguales (sin solape entre el editbox y la
    -- etiqueta de la columna siguiente).
    local INPUT_X = { 14, 222, 430, 638 }
    local BOX_W   = 172  -- boxBg = BOX_W + 28 = 200; columnas de 208 px.

    UI.itemBox     = MakeSpinnerEdit(inputPanel, "Item ID",       INPUT_X[1], -8, BOX_W, "",    true)
    UI.countBox    = MakeSpinnerEdit(inputPanel, "Cantidad",      INPUT_X[2], -8, BOX_W, "1",   false)
    UI.chanceBox   = MakeSpinnerEdit(inputPanel, "Chance %",      INPUT_X[3], -8, BOX_W, "100", false)
    UI.durationBox = MakeSpinnerEdit(inputPanel, "Duración min.", INPUT_X[4], -8, BOX_W, "10",  false)

    -- Botones de acción: 7 botones de 110 px con 6 px de gap caben
    -- limpios dentro del configPanel sin desbordarse.
    local btnY = -130
    local btnW = 110
    local function btnX(idx) return 14 + idx * (btnW + 6) end

    -- Resuelve la entry a usar al añadir un premio. Para tipos
    -- distintos de item, el server espera el id mágico correspondiente.
    local function ResolveEntryForAdd()
        local kind = UI.selectedType or "item"
        if kind == "honor" then return REWARD_HONOR_ID end
        if kind == "arena" then return REWARD_ARENA_ID end
        if kind == "gold"  then return REWARD_GOLD_ID  end
        return tonumber(UI.itemBox:GetText()) or 0
    end

    UI.addButton = MakeButton(configPanel, "Añadir", "plus", btnX(0), btnY, btnW, false, function()
        local entry  = ResolveEntryForAdd()
        local amount = tonumber(UI.countBox:GetText()) or 0
        local chance = tonumber(UI.chanceBox:GetText()) or 100
        local kind   = UI.selectedType or "item"
        AIO.Handle(HANDLER, "AddItem", entry, amount, chance, kind)
    end)

    UI.removeButton = MakeButton(configPanel, "Quitar", "minus", btnX(1), btnY, btnW, false, function()
        local entry  = ResolveEntryForAdd()
        if entry <= 0 then entry = selectedItemEntry or 0 end
        local amount = tonumber(UI.countBox:GetText()) or 0
        AIO.Handle(HANDLER, "RemoveItem", entry, amount)
    end)

    UI.deleteButton = MakeButton(configPanel, "Eliminar", "trash", btnX(2), btnY, btnW, false, function()
        local entry = ResolveEntryForAdd()
        if entry <= 0 then entry = selectedItemEntry or 0 end
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

    local selectedPanel = MakePanel(frame, 24, -316, FRAME_WIDTH - 48, 108)
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

    -- listPanel: alto suficiente para 5 filas de ROW_HEIGHT con sus gaps
    -- más el header (~68 px arriba) y un padding inferior real (~14 px).
    -- Cálculo: 5*36 + 4*2 = 188 px de filas + 68 (header) + 18 (bottom
    -- padding) = 274 px. Antes era 248 y la última fila se salía 22 px
    -- por debajo del borde dorado del panel (lo que el usuario veía como
    -- 'el limite se está saliendo' en la fila seleccionada).
    local listPanel = MakePanel(frame, 24, -430, FRAME_WIDTH - 48, 274)
    UI.listPanel = listPanel

    UI.listTitle = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.listTitle:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 16, -8)
    UI.listTitle:SetText(CC_GOLD_SOFT .. "ITEMS CONFIGURADOS (0)|r")

    local stripe = SolidTexture(listPanel, "BORDER", C_GOLD, 0.55)
    stripe:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 14, -22)
    stripe:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -14, -22)
    stripe:SetHeight(1)

    -- header y headerLine paran ANTES del scrollbar para que las columnas
    -- coincidan exactamente con el ancho real de las filas (que también
    -- paran antes del scrollbar). Sin esto, el header está corrido a la
    -- derecha respecto a las celdas.
    local headerRow = CreateFrame("Frame", nil, listPanel)
    headerRow:SetPoint("TOPLEFT",  listPanel, "TOPLEFT",  14, -32)
    headerRow:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -LIST_RIGHT_INSET, -32)
    headerRow:SetHeight(28)

    local function MakeHeaderLabel(text, col)
        local fs = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", headerRow, "LEFT", col.x, 0)
        fs:SetWidth(col.w)
        fs:SetJustifyH(col.justify)
        fs:SetText(CC_GOLD .. text .. "|r")
    end

    MakeHeaderLabel("#",                LIST_COLS.index)
    MakeHeaderLabel("Item ID",          LIST_COLS.itemId)
    MakeHeaderLabel("Nombre",           LIST_COLS.name)
    MakeHeaderLabel("Cantidad",         LIST_COLS.amount)
    MakeHeaderLabel("Chance %",         LIST_COLS.chance)
    MakeHeaderLabel("Duración (min.)",  LIST_COLS.duration)

    local headerLine = SolidTexture(listPanel, "ARTWORK", C_GOLD_DARK, 0.7)
    headerLine:SetPoint("TOPLEFT",  listPanel, "TOPLEFT",  14, -62)
    headerLine:SetPoint("TOPRIGHT", listPanel, "TOPRIGHT", -LIST_RIGHT_INSET, -62)
    headerLine:SetHeight(1)

    -- Pista (track) sutil para la barra de scroll, dentro del panel.
    local scrollTrack = CreateFrame("Frame", nil, listPanel)
    scrollTrack:SetPoint("TOPRIGHT",    listPanel, "TOPRIGHT",    -16, -66)
    scrollTrack:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -16, 16)
    scrollTrack:SetWidth(16)
    ApplyBackdrop(scrollTrack, C_BG_INPUT, 0.85, C_GOLD_DARK, 10)

    local rowsContainer = CreateFrame("Frame", nil, listPanel)
    rowsContainer:SetPoint("TOPLEFT",    listPanel, "TOPLEFT",    14, -68)
    rowsContainer:SetPoint("BOTTOMLEFT", listPanel, "BOTTOMLEFT", 14, 14)
    rowsContainer:SetPoint("TOPRIGHT",   scrollTrack, "TOPLEFT",  -8, 0)
    UI.rowsContainer = rowsContainer

    UI.emptyText = rowsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    UI.emptyText:SetPoint("CENTER", rowsContainer, "CENTER", 0, 0)
    UI.emptyText:SetText("No hay items configurados.")

    UI.scrollFrame = CreateFrame("ScrollFrame", "ClancyChestSystemScrollFrame",
                                 scrollTrack, "FauxScrollFrameTemplate")
    UI.scrollFrame:SetPoint("TOPLEFT",     scrollTrack, "TOPLEFT",     2, -2)
    UI.scrollFrame:SetPoint("BOTTOMRIGHT", scrollTrack, "BOTTOMRIGHT", -2, 2)

    -- La plantilla FauxScrollFrameTemplate trae un slider con texturas
    -- (knob y botones up/down) que arrastran tamaños fijos y se ven mal
    -- al achicarlos. Las ocultamos y dibujamos nuestro propio thumb dorado
    -- de tamaño exacto para que SIEMPRE quede dentro del track.
    local sbName = UI.scrollFrame:GetName() .. "ScrollBar"
    local upBtn   = _G[sbName .. "ScrollUpButton"]
    local downBtn = _G[sbName .. "ScrollDownButton"]
    local sb      = _G[sbName]

    if upBtn   then upBtn:Hide();   upBtn:SetWidth(0);   upBtn:SetHeight(0)   end
    if downBtn then downBtn:Hide(); downBtn:SetWidth(0); downBtn:SetHeight(0) end

    if sb then
        sb:Hide()
        sb:EnableMouse(false)
        for i = 1, sb:GetNumRegions() do
            local region = select(i, sb:GetRegions())
            if region and region.Hide then region:Hide() end
        end
    end

    -- Thumb custom (no interactivo) que indica la posición del scroll.
    local thumb = scrollTrack:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)
    thumb:SetWidth(8)
    thumb:SetHeight(20)
    thumb:SetPoint("TOP", scrollTrack, "TOP", 0, -3)
    UI.scrollThumb = thumb

    local function UpdateScrollThumb()
        local total   = #stockItems
        local visible = NUM_VISIBLE_ROWS

        if total <= visible then
            thumb:Hide()
            return
        end

        thumb:Show()

        local trackH = scrollTrack:GetHeight() - 6
        if trackH <= 0 then return end

        local thumbH = math.max(20, math.floor(trackH * (visible / total)))
        if thumbH > trackH then thumbH = trackH end

        local maxOff = total - visible
        local off    = FauxScrollFrame_GetOffset(UI.scrollFrame) or 0
        local pct    = (maxOff > 0) and (off / maxOff) or 0
        local maxY   = trackH - thumbH
        local y      = -3 - math.floor(pct * maxY)

        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", scrollTrack, "TOP", 0, y)
    end
    UI.UpdateScrollThumb = UpdateScrollThumb

    UI.rows = {}

    for i = 1, NUM_VISIBLE_ROWS do
        UI.rows[i] = CreateListRow(rowsContainer, i)
    end

    -- RefreshRows ya llama a UpdateScrollThumb al final, así que con
    -- usarlo como update de FauxScrollFrame basta.
    UI.scrollFrame.update = RefreshRows

    UI.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_STRIDE, self.update)
    end)

    -- Mouse wheel sobre el list panel desplaza la lista; también en el
    -- scrollTrack y el rowsContainer para que el evento no se pierda.
    local function OnWheel(_, delta)
        local total   = #stockItems
        local visible = NUM_VISIBLE_ROWS

        if total <= visible then return end

        local maxOff = total - visible
        local cur    = FauxScrollFrame_GetOffset(UI.scrollFrame) or 0
        local newOff = cur - delta

        if newOff < 0      then newOff = 0      end
        if newOff > maxOff then newOff = maxOff end

        FauxScrollFrame_SetOffset(UI.scrollFrame, newOff)
        RefreshRows()
    end

    listPanel:EnableMouseWheel(true)
    listPanel:SetScript("OnMouseWheel", OnWheel)
    rowsContainer:EnableMouseWheel(true)
    rowsContainer:SetScript("OnMouseWheel", OnWheel)
    scrollTrack:EnableMouseWheel(true)
    scrollTrack:SetScript("OnMouseWheel", OnWheel)

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

-- Alerta tipo "raid warning" enviada por el server. Recibe un título y
-- un subtítulo opcional y los pinta en el banner amarillo central.
function ClancyChestSystem.ShowAlert(title, subtitle)
    title    = tostring(title or "")
    subtitle = subtitle and tostring(subtitle) or ""

    D("ShowAlert title=" .. title .. " subtitle=" .. subtitle)

    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        local info = ChatTypeInfo["RAID_WARNING"]
        RaidNotice_AddMessage(RaidWarningFrame, title, info)

        if subtitle ~= "" then
            RaidNotice_AddMessage(RaidWarningFrame, subtitle, info)
        end
    end

    if PlaySound then
        -- "RaidWarning" es el sonido del banner amarillo de WoW.
        PlaySound("RaidWarning")
    end
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
