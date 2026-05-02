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
ShenLongTable - Client side
===========================

Renders the "Mesa de Invocacion del Dragon" two-phase summoning table
on the player UI. Layout:

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

Phase 1 collects the seven required items (the dragon balls) by drag
and drop or click. Phase 2 shows the five reward groups received from
the server; the player picks one item from each. When every slot is
filled and one reward per group is picked, the central Invocar button
sends the selection to the server for boss spawning.

The data driving the UI is fully server-driven via the
AIO.Handle("ShenLongTable", "ShowSummonTable", required, groups)
message - this client never hardcodes ids or group contents.
]]

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

-- ============================================================
-- VISUAL CONFIG
-- ============================================================

local UI = {
    frame = {width = 950, height = 720},
    colors = {
        title       = {r = 1.00, g = 0.82, b = 0.20},
        subtitle    = {r = 0.75, g = 0.75, b = 0.75},
        groupTitle  = {r = 1.00, g = 0.84, b = 0.00},
        normal      = {r = 1.00, g = 0.80, b = 0.00},
        hover       = {r = 1.00, g = 1.00, b = 0.00},
        selected    = {r = 0.00, g = 1.00, b = 1.00},
        filled      = {r = 0.00, g = 1.00, b = 0.00},
        emptyBg     = {r = 0.18, g = 0.18, b = 0.20, a = 0.85},
        filledBg    = {r = 0.05, g = 0.35, b = 0.05, a = 0.85},
        panelBg     = {r = 0.06, g = 0.06, b = 0.08, a = 0.75},
        panelBdr    = {r = 0.55, g = 0.45, b = 0.20},
    },
}

-- ============================================================
-- ADDON FRAME
-- ============================================================

local frame = CreateFrame("Frame", "ShenLongTableFrame", UIParent)
frame:SetSize(UI.frame.width, UI.frame.height)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile   = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = {left = 11, right = 12, top = 12, bottom = 11},
})
frame:Hide()

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetScript("OnHide", frame.StopMovingOrSizing)

AIO.SavePosition(frame)

-- Header bar for the title.
local headerBg = frame:CreateTexture(nil, "ARTWORK")
headerBg:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
headerBg:SetSize(360, 64)
headerBg:SetPoint("TOP", 0, 12)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", headerBg, "TOP", 0, -16)
title:SetText("Mesa de Invocacion del Dragon")
title:SetTextColor(UI.colors.title.r, UI.colors.title.g, UI.colors.title.b)

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- Container that gets cleared and rebuilt on every server update.
local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT",     20, -30)
content:SetPoint("BOTTOMRIGHT", -20, 20)

-- ============================================================
-- HELPERS
-- ============================================================

-- Releases every child created under `parent` so we can rebuild.
local function ClearChildren(parent)
    local kids = {parent:GetChildren()}
    for i = 1, #kids do
        local child = kids[i]
        child:Hide()
        child:ClearAllPoints()
        child:SetParent(nil)
    end
    if parent.fontStrings then
        for i = 1, #parent.fontStrings do
            parent.fontStrings[i]:Hide()
            parent.fontStrings[i]:SetText("")
        end
        parent.fontStrings = {}
    end
    if parent.textures then
        for i = 1, #parent.textures do
            parent.textures[i]:Hide()
        end
        parent.textures = {}
    end
end

-- Wrappers that remember every text/texture they create so we can hide
-- them when the panel is rebuilt.
local function NewText(parent, layer, template)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontNormal")
    parent.fontStrings = parent.fontStrings or {}
    table.insert(parent.fontStrings, fs)
    return fs
end

local function NewTexture(parent, layer)
    local tx = parent:CreateTexture(nil, layer or "ARTWORK")
    parent.textures = parent.textures or {}
    table.insert(parent.textures, tx)
    return tx
end

-- Builds a labeled bordered panel and returns its frame plus the inner
-- content area that callers can populate.
local function CreatePanel(parent, label)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = {left = 4, right = 4, top = 4, bottom = 4},
    })
    panel:SetBackdropColor(UI.colors.panelBg.r, UI.colors.panelBg.g, UI.colors.panelBg.b, UI.colors.panelBg.a)
    panel:SetBackdropBorderColor(UI.colors.panelBdr.r, UI.colors.panelBdr.g, UI.colors.panelBdr.b)

    local labelFs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    labelFs:SetPoint("TOPLEFT", 8, -6)
    labelFs:SetText(label or "")
    labelFs:SetTextColor(UI.colors.subtitle.r, UI.colors.subtitle.g, UI.colors.subtitle.b)
    panel.label = labelFs

    return panel
end

-- ============================================================
-- PHASE 1 - REQUIRED ITEM SLOTS
-- ============================================================

-- itemSlots[i] = { container, filled, itemData, ... }
local itemSlots = {}

local function CreateRequiredSlot(parent, itemData, index)
    local slot = CreateFrame("Button", nil, parent)
    slot:SetSize(50, 50)
    slot.itemData = itemData
    slot.index    = index
    slot.filled   = false

    local bg = slot:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface/Buttons/UI-EmptySlot-White")
    bg:SetVertexColor(UI.colors.emptyBg.r, UI.colors.emptyBg.g, UI.colors.emptyBg.b, UI.colors.emptyBg.a)
    slot.bg = bg

    local border = slot:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetTexture("Interface/Buttons/UI-EmptySlot")
    border:SetVertexColor(0.6, 0.6, 0.6)
    slot.border = border

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38)
    icon:SetPoint("CENTER")
    icon:SetTexture(GetItemIcon(itemData.id))
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDesaturated(true)
    icon:SetAlpha(0.4)
    slot.icon = icon

    local count = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", 2, 2)
    count:SetText("0/1")
    count:SetTextColor(1, 0.8, 0.2)
    slot.count = count

    local label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", slot, "TOP", 0, 2)
    label:SetText(itemData.name or "")
    label:SetTextColor(1, 1, 1)
    slot.label = label

    local function fill()
        slot.filled = true
        slot.icon:SetDesaturated(false)
        slot.icon:SetAlpha(1)
        slot.bg:SetVertexColor(UI.colors.filledBg.r, UI.colors.filledBg.g, UI.colors.filledBg.b, UI.colors.filledBg.a)
        slot.border:SetVertexColor(UI.colors.filled.r, UI.colors.filled.g, UI.colors.filled.b)
        slot.count:SetText("1/1")
    end

    local function unfill()
        slot.filled = false
        slot.icon:SetDesaturated(true)
        slot.icon:SetAlpha(0.4)
        slot.bg:SetVertexColor(UI.colors.emptyBg.r, UI.colors.emptyBg.g, UI.colors.emptyBg.b, UI.colors.emptyBg.a)
        slot.border:SetVertexColor(0.6, 0.6, 0.6)
        slot.count:SetText("0/1")
    end

    slot.Fill   = fill
    slot.Unfill = unfill

    slot:RegisterForDrag("LeftButton")
    slot:SetScript("OnDragStart", function()
        if slot.filled then
            PickupItem(itemData.id)
            unfill()
        end
    end)

    slot:SetScript("OnReceiveDrag", function()
        local cursorType, cursorItem = GetCursorInfo()
        if cursorType == "item" then
            for i = 1, #itemSlots do
                local s = itemSlots[i]
                if not s.filled and s.itemData.id == cursorItem then
                    s.Fill()
                    ClearCursor()
                    return
                end
            end
        end
    end)

    slot:SetScript("OnClick", function()
        if not slot.filled and GetItemCount(itemData.id) > 0 then
            fill()
        end
    end)

    slot:SetScript("OnEnter", function()
        GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. itemData.id)
        if not slot.filled then
            GameTooltip:AddLine("Arrastra o haz clic para colocar", 1, 0.82, 0)
        else
            GameTooltip:AddLine("Colocado", 0, 1, 0)
        end
        GameTooltip:Show()
    end)

    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return slot
end

-- ============================================================
-- PHASE 2 - REWARD CIRCLES + GROUP PANELS
-- ============================================================

local selectedRewards = {}                 -- groupKey -> itemIndex
local rewardCircles   = {}                 -- groupKey -> { itemIndex -> button }

local function CreateRewardCircle(parent, rewardData, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(48, 48)
    btn.selected = false

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface/Buttons/UI-EmptySlot-White")
    bg:SetVertexColor(UI.colors.emptyBg.r, UI.colors.emptyBg.g, UI.colors.emptyBg.b, UI.colors.emptyBg.a)
    btn.bg = bg

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38)
    icon:SetPoint("CENTER")
    icon:SetTexture(GetItemIcon(rewardData.id))
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(UI.colors.normal.r, UI.colors.normal.g, UI.colors.normal.b)
    border:Hide()
    btn.border = border

    if rewardData.count and rewardData.count > 1 then
        local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", -2, 2)
        count:SetText(rewardData.count)
        count:SetTextColor(1, 1, 1)
        btn.count = count
    end

    btn:SetScript("OnEnter", function()
        if not btn.selected then
            border:Show()
            border:SetVertexColor(UI.colors.hover.r, UI.colors.hover.g, UI.colors.hover.b)
        end
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. rewardData.id)
        if rewardData.count and rewardData.count > 1 then
            GameTooltip:AddLine("Cantidad: " .. rewardData.count, 1, 1, 1)
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if not btn.selected then border:Hide() end
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

-- Selects (or unselects) a reward circle, updating the highlight state
-- and the shared `selectedRewards` map.
local function SelectReward(groupKey, itemIndex)
    if selectedRewards[groupKey] then
        local prev = rewardCircles[groupKey][selectedRewards[groupKey]]
        if prev then
            prev.selected = false
            prev.border:Hide()
        end
    end

    if selectedRewards[groupKey] == itemIndex then
        selectedRewards[groupKey] = nil
        return
    end

    selectedRewards[groupKey] = itemIndex
    local btn = rewardCircles[groupKey][itemIndex]
    if btn then
        btn.selected = true
        btn.border:Show()
        btn.border:SetVertexColor(UI.colors.selected.r, UI.colors.selected.g, UI.colors.selected.b)
    end
end

local function CreateRewardGroupPanel(parent, groupKey, group, width, height)
    local panel = CreatePanel(parent, group.name or ("Grupo " .. tostring(groupKey)))
    panel:SetSize(width, height)
    panel.label:SetText(group.name or "")
    panel.label:SetTextColor(UI.colors.groupTitle.r, UI.colors.groupTitle.g, UI.colors.groupTitle.b)

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", 0, -22)
    subtitle:SetText("Elige una recompensa de cada grupo:")
    subtitle:SetTextColor(UI.colors.subtitle.r, UI.colors.subtitle.g, UI.colors.subtitle.b)

    rewardCircles[groupKey] = {}

    local items   = group.items or {}
    local n       = math.min(#items, 4)
    local spacing = 12
    local btnSize = 48
    local total   = n * btnSize + (n - 1) * spacing
    local startX  = -total / 2 + btnSize / 2

    for itemIndex = 1, n do
        local item = items[itemIndex]
        local circle = CreateRewardCircle(panel, item, function()
            SelectReward(groupKey, itemIndex)
        end)
        circle:SetPoint("BOTTOM", panel, "BOTTOM", startX + (itemIndex - 1) * (btnSize + spacing), 12)
        rewardCircles[groupKey][itemIndex] = circle
    end

    return panel
end

-- ============================================================
-- HANDLERS
-- ============================================================

local handlers = AIO.AddHandlers("ShenLongTable", {})

-- Show the "boss already summoned" panel.
function handlers.ShowBossSpawned(player, summonerName)
    ClearChildren(content)
    itemSlots       = {}
    selectedRewards = {}
    rewardCircles   = {}

    local msg = NewText(content, "OVERLAY", "GameFontNormalLarge")
    msg:SetPoint("CENTER", 0, 30)
    msg:SetText("|cFFFF4040El jefe ya ha sido invocado|r")

    local who = NewText(content, "OVERLAY", "GameFontNormal")
    who:SetPoint("CENTER", 0, 0)
    who:SetText("Invocador: " .. (summonerName or "Desconocido"))
    who:SetTextColor(0.9, 0.9, 0.9)

    local exitBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exitBtn:SetSize(120, 28)
    exitBtn:SetPoint("CENTER", 0, -50)
    exitBtn:SetText("Salir")
    exitBtn:SetScript("OnClick", function() frame:Hide() end)

    frame:Show()
end

-- Build the full two-phase summoning table from server-provided data.
function handlers.ShowSummonTable(player, requiredItems, groupedRewards)
    ClearChildren(content)
    itemSlots       = {}
    selectedRewards = {}
    rewardCircles   = {}

    local cw, ch = content:GetWidth(), content:GetHeight()

    -- ---------- Phase 1 panel ----------
    local phase1 = CreatePanel(content, "Phase 1: Preparation")
    phase1:SetSize(cw, 300)
    phase1:SetPoint("TOP", 0, 0)

    local subtitle = phase1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("BOTTOM", 0, 12)
    subtitle:SetText("Preparacion: Reune las 7 Esferas")
    subtitle:SetTextColor(UI.colors.subtitle.r, UI.colors.subtitle.g, UI.colors.subtitle.b)

    -- Central shield art.
    local shield = phase1:CreateTexture(nil, "ARTWORK")
    shield:SetTexture("Interface/Buttons/UI-Quickslot2")
    shield:SetSize(96, 96)
    shield:SetPoint("CENTER", 0, 10)
    shield:SetVertexColor(0.85, 0.7, 0.4)

    -- 7 dragon ball slots arranged in a circle around the shield.
    local n      = #requiredItems
    local radius = 110
    for i = 1, n do
        local angle = (i - 1) * (2 * math.pi / n) - math.pi / 2
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius + 10
        local slot = CreateRequiredSlot(phase1, requiredItems[i], i)
        slot:SetPoint("CENTER", phase1, "CENTER", x, y)
        itemSlots[i] = slot
    end

    -- Auto-fill helper that drops one of each missing required item from
    -- the player's bags into the matching slot.
    local autoBtn = CreateFrame("Button", nil, phase1, "UIPanelButtonTemplate")
    autoBtn:SetSize(110, 24)
    autoBtn:SetPoint("BOTTOM", 0, 36)
    autoBtn:SetText("Posicionar")
    autoBtn:SetScript("OnClick", function()
        local missing = 0
        for i = 1, #itemSlots do
            local s = itemSlots[i]
            if not s.filled then
                if GetItemCount(s.itemData.id) > 0 then
                    s.Fill()
                else
                    missing = missing + 1
                end
            end
        end
        if missing > 0 then
            print("|cFFFFAA00[ShenLongTable]|r Te faltan " .. missing .. " esferas en tu inventario.")
        end
    end)

    -- ---------- Center divider + Invocar button ----------
    local divider = NewTexture(content, "ARTWORK")
    divider:SetTexture("Interface/Common/UI-TooltipDivider-Transparent")
    divider:SetSize(cw - 40, 8)
    divider:SetPoint("TOP", phase1, "BOTTOM", 0, -2)

    local invocarBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    invocarBtn:SetSize(160, 30)
    invocarBtn:SetPoint("TOP", divider, "BOTTOM", 0, 0)
    invocarBtn:SetText("Invocar")

    -- ---------- Phase 2 panel ----------
    local phase2 = CreatePanel(content, "Phase 2: Post-Invocation (Dragon Presence)")
    phase2:SetSize(cw, ch - 300 - 40)
    phase2:SetPoint("TOP", invocarBtn, "BOTTOM", 0, -4)

    -- Dragon image art behind the reward grid.
    local dragon = phase2:CreateTexture(nil, "BACKGROUND")
    dragon:SetTexture("Interface/Glues/Models/UI_Draenei/Genericglow64")
    dragon:SetPoint("CENTER", phase2, "CENTER", 0, 0)
    dragon:SetSize(220, 220)
    dragon:SetAlpha(0.15)
    dragon:SetBlendMode("ADD")

    -- Grid layout: 3 columns x 2 rows. Slot (top, center) is left empty
    -- on purpose so the central area below the divider stays clear.
    --   row 1: Armas        |  (empty)   |  Materiales
    --   row 2: Joyas        |  Pociones  |  Miscelaneos
    local panelW, panelH = 270, 110
    local hSpacing       = 16
    local vSpacing       = 10

    local layout = {
        {col = 1, row = 1, key = 1}, -- Armas de los Heroes
        {col = 3, row = 1, key = 4}, -- Materiales Legendarios
        {col = 1, row = 2, key = 2}, -- Joyas Runicas
        {col = 2, row = 2, key = 3}, -- Pociones Alquimicas
        {col = 3, row = 2, key = 5}, -- Miscelaneos de Poder
    }

    local totalW    = 3 * panelW + 2 * hSpacing
    local startX    = -(totalW / 2) + (panelW / 2)
    local row1Y     = -34
    local row2Y     = row1Y - panelH - vSpacing

    for _, slot in ipairs(layout) do
        local group = groupedRewards[slot.key]
        if group then
            local panel = CreateRewardGroupPanel(phase2, slot.key, group, panelW, panelH)
            local x = startX + (slot.col - 1) * (panelW + hSpacing)
            local y = (slot.row == 1) and row1Y or row2Y
            panel:SetPoint("TOP", phase2, "TOP", x, y)
        end
    end

    -- ---------- Invocar / Salir button behaviour ----------
    invocarBtn:SetScript("OnClick", function()
        for i = 1, #itemSlots do
            if not itemSlots[i].filled then
                print("|cFFFFAA00[ShenLongTable]|r Coloca las 7 esferas antes de invocar.")
                return
            end
        end

        local picked = 0
        for _ in pairs(selectedRewards) do picked = picked + 1 end

        local needed = 0
        for _ in pairs(groupedRewards) do needed = needed + 1 end

        if picked < needed then
            print("|cFFFFAA00[ShenLongTable]|r Elige una recompensa de cada grupo.")
            return
        end

        AIO.Handle("ShenLongTable", "SubmitSummon", selectedRewards)
        frame:Hide()
    end)

    local exitBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exitBtn:SetSize(110, 24)
    exitBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    exitBtn:SetText("Salir")
    exitBtn:SetScript("OnClick", function() frame:Hide() end)

    frame:Show()
end

-- Slash command for quick local testing without an NPC. The player can
-- type /shenlong to ask the server to (re)open the table.
SLASH_SHENLONG1 = "/shenlong"
SlashCmdList["SHENLONG"] = function()
    AIO.Handle("ShenLongTable", "OpenTable")
end
