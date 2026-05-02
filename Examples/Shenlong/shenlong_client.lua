--[[          
    Sistema de Invocación de Jefes - Interfaz de Cliente          
    Diseño: Mesa de Invocación del Dragon    
    - Ventana 1: Escudo central + 7 esferas en círculo + botón Invocar    
    - Ventana 2: 5 grupos de recompensas (layout 2+3) + botón Confirmar    
    Flujo secuencial: primero colocar esferas, luego elegir recompensas    
]]--          
          
local AIO = AIO or require("AIO")          
          
if AIO.AddAddon() then          
    return          
end          
          
-- ========================================          
-- CONFIGURACIÓN VISUAL          
-- ========================================          
          
local UI_CONFIG = {          
    window1_size = {width = 550, height = 530},    
    window2_size = {width = 1050, height = 460},    
    colors = {          
        title = {r = 1, g = 0.84, b = 0},          
        subtitle = {r = 0.7, g = 0.7, b = 0.7},          
        phase_label = {r = 0.9, g = 0.8, b = 0.6},    
        group_title = {r = 1, g = 0.843, b = 0},          
        selected = {r = 0, g = 1, b = 1},          
        normal = {r = 1, g = 0.8, b = 0},          
        hover = {r = 1, g = 1, b = 0},          
        filled = {r = 0, g = 0.5, b = 0, a = 0.8},          
        empty = {r = 0.3, g = 0.3, b = 0.3, a = 0.8}          
    }          
}          

-- ========================================          
-- BACKDROP COMPARTIDO    
-- ========================================          

local MAIN_BACKDROP = {          
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",          
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",          
    tile = true, tileSize = 32, edgeSize = 32,          
    insets = {left = 11, right = 12, top = 12, bottom = 11}          
}

local PANEL_BACKDROP = {    
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",    
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",    
    tile = true, tileSize = 32, edgeSize = 16,    
    insets = {left = 4, right = 4, top = 4, bottom = 4}    
}

-- ========================================          
-- VENTANA 1: ESFERAS (estático)    
-- ========================================          
          
local frame1 = CreateFrame("Frame", "BossSummonFrame", UIParent)          
frame1:SetSize(UI_CONFIG.window1_size.width, UI_CONFIG.window1_size.height)          
frame1:SetPoint("CENTER")          
frame1:SetBackdrop(MAIN_BACKDROP)          
frame1:SetBackdropColor(0.08, 0.08, 0.1, 0.97)    
frame1:EnableMouse(true)    
frame1:SetMovable(true)    
frame1:RegisterForDrag("LeftButton")    
frame1:SetScript("OnDragStart", frame1.StartMoving)    
frame1:SetScript("OnDragStop", frame1.StopMovingOrSizing)    
frame1:Hide()          
          
local title1 = frame1:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")          
title1:SetPoint("TOP", 0, -8)          
title1:SetText("|cffFFD700Mesa de Invocación del Dragon|r")          
          
local closeBtn1 = CreateFrame("Button", nil, frame1, "UIPanelCloseButton")          
closeBtn1:SetPoint("TOPRIGHT", -5, -5)          
    
local content1 = CreateFrame("Frame", nil, frame1)    
content1:SetAllPoints()    

-- ========================================          
-- VENTANA 2: RECOMPENSAS (estático)    
-- ========================================          

local frame2 = CreateFrame("Frame", "BossSummonRewardsFrame", UIParent)          
frame2:SetSize(UI_CONFIG.window2_size.width, UI_CONFIG.window2_size.height)          
frame2:SetPoint("CENTER")          
frame2:SetBackdrop(MAIN_BACKDROP)          
frame2:SetBackdropColor(0.08, 0.08, 0.1, 0.97)    
frame2:EnableMouse(true)    
frame2:SetMovable(true)    
frame2:RegisterForDrag("LeftButton")    
frame2:SetScript("OnDragStart", frame2.StartMoving)    
frame2:SetScript("OnDragStop", frame2.StopMovingOrSizing)    
frame2:Hide()          

local title2 = frame2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")          
title2:SetPoint("TOP", 0, -8)          
title2:SetText("|cffFFD700Recompensas del Dragon|r")          

local closeBtn2 = CreateFrame("Button", nil, frame2, "UIPanelCloseButton")          
closeBtn2:SetPoint("TOPRIGHT", -5, -5)          

local content2 = CreateFrame("Frame", nil, frame2)    
content2:SetAllPoints()    

-- ========================================          
-- ITEMS REQUERIDOS    
-- ========================================          
          
local itemSlots = {}          
local requiredItems = {          
    {id = 36786, name = "7 Estrellas"},          
    {id = 30809, name = "6 Estrellas"},          
    {id = 34057, name = "5 Estrellas"},          
    {id = 33470, name = "4 Estrellas"},          
    {id = 22573, name = "3 Estrellas"},          
    {id = 22445, name = "2 Estrellas"},          
    {id = 14344, name = "1 Estrella"}          
}          
    
-- ========================================          
-- FUNCIONES AUXILIARES    
-- ========================================          
    
local function ClearFrame(container)    
    for i = 1, container:GetNumChildren() do    
        local child = select(i, container:GetChildren())    
        if child then child:Hide() end    
    end    
end    

local function ClearContent()    
    ClearFrame(content1)    
    ClearFrame(content2)    
    itemSlots = {}    
end    
    
-- ========================================          
-- CREACIÓN DE ELEMENTOS UI    
-- ========================================          
    
local function CreateItemSlot(parent, itemData, index)          
    local container = CreateFrame("Frame", "BossSummonSlot"..index, parent)          
    container:SetSize(50, 50)    
    container.itemData = itemData          
    container.index = index          
    container.filled = false      
              
    local bg = container:CreateTexture(nil, "BACKGROUND")          
    bg:SetAllPoints()          
    bg:SetTexture("Interface/Buttons/UI-EmptySlot-White")          
    bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)          
    container.bg = bg      
              
    local border = container:CreateTexture(nil, "BORDER")          
    border:SetAllPoints()          
    border:SetTexture("Interface/Buttons/UI-EmptySlot")          
    border:SetVertexColor(0.6, 0.6, 0.6)          
    container.border = border      
              
    local icon = container:CreateTexture(nil, "OVERLAY")          
    icon:SetSize(42, 42)          
    icon:SetPoint("CENTER")    
    local itemIcon = GetItemIcon(itemData.id)
    if itemIcon then
        icon:SetTexture(itemIcon)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        icon:Show()
    else
        icon:Hide()
    end
    container.icon = icon

    -- Detectar si el jugador tiene el item
    local hasItem = (GetItemCount(itemData.id) or 0) > 0
    if hasItem then
        icon:SetVertexColor(1, 1, 1, 1)
        border:SetVertexColor(1, 0.84, 0)
    else
        icon:SetVertexColor(0.3, 0.3, 0.3, 0.6)
        icon:SetDesaturated(true)
        border:SetVertexColor(0.4, 0.4, 0.4)
    end      
              
    local button = CreateFrame("Button", nil, container)          
    button:SetAllPoints()    
    button:SetFrameLevel(container:GetFrameLevel() + 1)          
    container.button = button      
              
    container:SetFrameStrata("DIALOG")          
    container:SetFrameLevel(20)          
              
    button:RegisterForDrag("LeftButton")          
    button:SetScript("OnDragStart", function()          
        if container.filled then          
            PickupItem(itemData.id)          
            container.filled = false          
            icon:SetVertexColor(0.3, 0.3, 0.3, 0.6)
            icon:SetDesaturated(true)
            bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)          
            border:SetVertexColor(0.4, 0.4, 0.4)          
        end          
    end)          
              
    button:SetScript("OnReceiveDrag", function()          
        local cursorType, cursorItem = GetCursorInfo()          
        if cursorType == "item" then      
            for i, slot in ipairs(itemSlots) do      
                if not slot.filled and slot.itemData.id == cursorItem then      
                    slot.filled = true      
                    slot.icon:SetTexture(GetItemIcon(cursorItem))      
                    slot.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)      
                    slot.icon:SetVertexColor(1, 1, 1, 1)
                    slot.icon:SetDesaturated(false)
                    slot.icon:Show()      
                    slot.bg:SetVertexColor(0, 0.5, 0, 0.8)      
                    slot.border:SetVertexColor(0, 1, 0)      
                    ClearCursor()      
                    return      
                end      
            end      
        end          
    end)          
              
    button:SetScript("OnEnter", function()          
        GameTooltip:SetOwner(container, "ANCHOR_RIGHT")          
        GameTooltip:SetHyperlink("item:" .. itemData.id .. ":0:0:0:0:0:0:0")
        local hasItem = (GetItemCount(itemData.id) or 0) > 0
        if container.filled then          
            border:SetVertexColor(0, 1, 0)          
        elseif hasItem then
            border:SetVertexColor(1, 0.84, 0)
        else          
            border:SetVertexColor(0.4, 0.4, 0.4)          
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFFFF4444No tienes este item|r")
        end          
        GameTooltip:Show()          
    end)          
              
    button:SetScript("OnLeave", function()          
        if container.filled then    
            border:SetVertexColor(0, 0.8, 0)    
        else    
            border:SetVertexColor(0.4, 0.4, 0.4)    
        end    
        GameTooltip:Hide()          
    end)          
              
    return container          
end          
    
local function CreateRewardCircle(parent, rewardData, index, onClick)    
    local circle = CreateFrame("Button", nil, parent)    
    circle:SetSize(42, 42)    
    circle:RegisterForClicks("LeftButtonUp")
    circle.selected = false    
    
    local bg = circle:CreateTexture(nil, "BACKGROUND")    
    bg:SetAllPoints()    
    bg:SetTexture("Interface/Buttons/UI-EmptySlot-White")    
    bg:SetVertexColor(0.15, 0.15, 0.18, 0.9)    
    circle.bg = bg    
    
    local border = circle:CreateTexture(nil, "BORDER")    
    border:SetAllPoints()    
    border:SetTexture("Interface/Buttons/UI-EmptySlot")    
    border:SetVertexColor(UI_CONFIG.colors.normal.r, UI_CONFIG.colors.normal.g, UI_CONFIG.colors.normal.b)    
    circle.border = border    
    
    local icon = circle:CreateTexture(nil, "OVERLAY")    
    icon:SetSize(36, 36)    
    icon:SetPoint("CENTER")    
    circle.icon = icon    
    
    if rewardData.icon then    
        icon:SetTexture(rewardData.icon)    
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)    
    elseif rewardData.id then    
        local itemIcon = GetItemIcon(rewardData.id)    
        if itemIcon then    
            icon:SetTexture(itemIcon)    
            icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)    
        end    
    end    
    
    circle:SetScript("OnClick", function(self)    
        if onClick then onClick(self) end    
    end)    
    
    circle:SetScript("OnEnter", function()    
        GameTooltip:SetOwner(circle, "ANCHOR_RIGHT")    
        if rewardData.id then
            GameTooltip:SetHyperlink("item:" .. rewardData.id .. ":0:0:0:0:0:0:0")
        else
            local name = rewardData.name or ("Item ?")
            GameTooltip:SetText("|cFFFFCC00" .. name .. "|r")
        end
        if rewardData.count and rewardData.count > 1 then    
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Cantidad: " .. rewardData.count, 1, 1, 1)    
        end    
        if circle.selected then    
            GameTooltip:AddLine("|cFF00FF00Seleccionado|r")
        else    
            GameTooltip:AddLine("|cFFFFCC00Click para seleccionar|r")
        end    
        GameTooltip:Show()    
        if not circle.selected then    
            border:SetVertexColor(UI_CONFIG.colors.hover.r, UI_CONFIG.colors.hover.g, UI_CONFIG.colors.hover.b)    
        end    
    end)    
    
    circle:SetScript("OnLeave", function()    
        GameTooltip:Hide()    
        if not circle.selected then    
            border:SetVertexColor(UI_CONFIG.colors.normal.r, UI_CONFIG.colors.normal.g, UI_CONFIG.colors.normal.b)    
        end    
    end)    
    
    return circle    
end    
    
local function CreateGroupPanel(parent, groupName, width, height)    
    local panel = CreateFrame("Frame", nil, parent)    
    panel:SetSize(width, height)    
    panel:SetBackdrop({    
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",    
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",    
        tile = true, tileSize = 32, edgeSize = 16,    
        insets = {left = 4, right = 4, top = 4, bottom = 4}    
    })    
    panel:SetBackdropColor(0.06, 0.06, 0.08, 0.85)    
    panel:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.9)    
    
    local titleBar = panel:CreateTexture(nil, "ARTWORK")    
    titleBar:SetHeight(24)    
    titleBar:SetPoint("TOPLEFT", 4, -4)    
    titleBar:SetPoint("TOPRIGHT", -4, -4)    
    titleBar:SetTexture("Interface/DialogFrame/UI-DialogBox-Background-Dark")    
    titleBar:SetVertexColor(0.35, 0.28, 0.12, 0.95)    
    
    local titleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    titleLabel:SetPoint("TOP", 0, -8)    
    titleLabel:SetText("|cffFFD700" .. groupName .. "|r")    
    
    local line = panel:CreateTexture(nil, "ARTWORK")    
    line:SetHeight(1)    
    line:SetPoint("TOPLEFT", 8, -30)    
    line:SetPoint("TOPRIGHT", -8, -30)    
    line:SetTexture(1, 0.84, 0, 0.4)    
    
    local subLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")    
    subLabel:SetPoint("TOP", 0, -34)    
    subLabel:SetText("|cffAAAAAAElige una recompensa de cada grupo:|r")    
    
    local iconArea = CreateFrame("Frame", nil, panel)    
    iconArea:SetSize(width - 20, 50)    
    iconArea:SetPoint("BOTTOM", 0, 8)    
    panel.iconArea = iconArea    
    
    return panel    
end    
    
-- ========================================          
-- HANDLER: BOSS YA INVOCADO    
-- ========================================          
    
local function ShowBossSpawned(player, summonerName)    
    ClearContent()    
    frame2:Hide()    
    
    local msg = content1:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")    
    msg:SetPoint("CENTER", 0, 20)    
    msg:SetText("|cffFF4444Un jefe ya ha sido invocado|r")    
    
    local sub = content1:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    sub:SetPoint("CENTER", 0, -10)    
    if summonerName then    
        sub:SetText("Invocado por: |cffFFD700" .. summonerName .. "|r")    
    else    
        sub:SetText("Espera a que sea derrotado.")    
    end    
    
    frame1:Show()    
end    
    
-- ========================================          
-- HANDLER: SELECCIÓN DE RECOMPENSAS    
-- ========================================          
    
local function ShowRewardSelection(player, groupedRewards, hasItems, missingItems)    
    ClearContent()    
    frame2:Hide()    
    
    -- ============================    
    -- VENTANA 1: PREPARACIÓN (Esferas)    
    -- ============================    
    local phase1 = CreateFrame("Frame", nil, content1)    
    phase1:SetSize(UI_CONFIG.window1_size.width - 40, UI_CONFIG.window1_size.height - 40)    
    phase1:SetPoint("CENTER", frame1, "CENTER", 0, -5)    
    phase1:SetBackdrop(PANEL_BACKDROP)    
    phase1:SetBackdropColor(0.04, 0.04, 0.06, 0.75)    
    phase1:SetBackdropBorderColor(0.5, 0.45, 0.3, 0.8)    
    
    local p1Label = phase1:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    p1Label:SetPoint("TOPLEFT", 15, -8)    
    p1Label:SetText("|cffDDCC99Phase 1: Preparation|r")    
    
    -- Contenedor del círculo de esferas    
    local circleContainer = CreateFrame("Frame", nil, phase1)    
    circleContainer:SetSize(300, 300)    
    circleContainer:SetPoint("CENTER", 0, 20)    
    
    -- Escudo central    
    local shield = circleContainer:CreateTexture(nil, "ARTWORK")    
    shield:SetSize(120, 140)    
    shield:SetPoint("CENTER", 0, 0)    
    shield:SetTexture("Interface/Icons/INV_Shield_06")    
    shield:SetTexCoord(0.08, 0.92, 0.08, 0.92)    
    
    -- 7 esferas en círculo    
    local radius = 110    
    local startAngle = -3 * math.pi / 14    
    for i = 1, 7 do    
        local angle = startAngle + (2 * math.pi * (i - 1)) / 7    
        local x = radius * math.sin(angle)    
        local y = radius * math.cos(angle)    
    
        local slot = CreateItemSlot(circleContainer, requiredItems[i], i)    
        slot:SetPoint("CENTER", circleContainer, "CENTER", x, y)    
        table.insert(itemSlots, slot)    
    end    
    
    -- Texto de preparación    
    local prepText = phase1:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    prepText:SetPoint("BOTTOM", 0, 52)    
    prepText:SetText("|cffCCCCCCPreparación: Reúne las 7 Esferas|r")    
    
    -- Botón Invocar (Ventana 1)    
    local invokeBtn = CreateFrame("Button", nil, phase1, "UIPanelButtonTemplate")    
    invokeBtn:SetSize(200, 35)    
    invokeBtn:SetPoint("BOTTOM", 0, 15)    
    invokeBtn:SetText("Invocar")    
    
    -- ============================    
    -- VENTANA 2: RECOMPENSAS (se construye pero se oculta)    
    -- ============================    
    local phase2 = CreateFrame("Frame", nil, content2)    
    phase2:SetSize(UI_CONFIG.window2_size.width - 40, UI_CONFIG.window2_size.height - 40)    
    phase2:SetPoint("CENTER", frame2, "CENTER", 0, -5)    
    phase2:SetBackdrop(PANEL_BACKDROP)    
    phase2:SetBackdropColor(0.04, 0.04, 0.06, 0.75)    
    phase2:SetBackdropBorderColor(0.5, 0.45, 0.3, 0.8)    
    
    local p2Label = phase2:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    p2Label:SetPoint("TOPLEFT", 15, -8)    
    p2Label:SetText("|cffDDCC99Phase 2: Post-Invocation (Dragon Presence)|r")    
    
    -- Grupos de recompensas    
    local selectedRewards = {}    
    local rewardCircles = {}    
    local originalIndices = {}    
    
    local panelW, panelH = 310, 130    
    local groupPositions = {    
        {anchor = "TOPLEFT",  parent = phase2, x = 20,   y = -32},    
        {anchor = "TOPRIGHT", parent = phase2, x = -20,  y = -32},    
        {anchor = "TOPLEFT",  parent = phase2, x = 20,   y = -175},    
        {anchor = "TOP",      parent = phase2, x = 0,    y = -175},    
        {anchor = "TOPRIGHT", parent = phase2, x = -20,  y = -175},    
    }    
    
    local sortedKeys = {}    
    for k in pairs(groupedRewards) do    
        table.insert(sortedKeys, k)    
    end    
    table.sort(sortedKeys)    
    
    local totalGroups = #sortedKeys    
    
    local groupIdx = 0    
    for _, groupKey in ipairs(sortedKeys) do    
        local group = groupedRewards[groupKey]    
        groupIdx = groupIdx + 1    
    
        if groupIdx > 5 then break end    
    
        local pos = groupPositions[groupIdx]    
        if not pos then break end    
    
        local panel = CreateGroupPanel(phase2, group.name, panelW, panelH)    
        panel:SetPoint(pos.anchor, pos.parent, pos.anchor, pos.x, pos.y)    
    
        rewardCircles[groupKey] = {}    
        originalIndices[groupKey] = {}    
    
        local numItems = #group.items    
        local spacing = 48    
        local totalW = numItems * 42 + (numItems - 1) * (spacing - 42)    
        local startX = -(totalW / 2) + 21    
    
        for itemIdx, item in ipairs(group.items) do    
            local origIdx = item.itemIndex or itemIdx    
            originalIndices[groupKey][itemIdx] = origIdx    
    
            local circleX = startX + (itemIdx - 1) * spacing    
    
            local circle = CreateRewardCircle(panel.iconArea, item, itemIdx, function(self)    
                if selectedRewards[groupKey] == origIdx then    
                    -- Deseleccionar: restaurar todos los del grupo a normal    
                    selectedRewards[groupKey] = nil    
                    self.selected = false    
                    for vi, rc in pairs(rewardCircles[groupKey]) do    
                        rc.selected = false    
                        rc.icon:SetVertexColor(1, 1, 1, 1)    
                        rc.icon:SetDesaturated(false)    
                        rc.border:SetVertexColor(UI_CONFIG.colors.normal.r, UI_CONFIG.colors.normal.g, UI_CONFIG.colors.normal.b)    
                    end    
                    return    
                end    
    
                -- Seleccionar este, opacar los demás del grupo    
                selectedRewards[groupKey] = origIdx    
                for vi, rc in pairs(rewardCircles[groupKey]) do    
                    local oi = originalIndices[groupKey][vi]    
                    if oi == origIdx then    
                        rc.selected = true    
                        rc.icon:SetVertexColor(1, 1, 1, 1)    
                        rc.icon:SetDesaturated(false)    
                        rc.border:SetVertexColor(UI_CONFIG.colors.selected.r, UI_CONFIG.colors.selected.g, UI_CONFIG.colors.selected.b)    
                    else    
                        rc.selected = false    
                        rc.icon:SetVertexColor(0.3, 0.3, 0.3, 0.7)    
                        rc.icon:SetDesaturated(true)    
                        rc.border:SetVertexColor(0.3, 0.3, 0.3)    
                    end    
                end    
            end)    
            circle:SetPoint("CENTER", panel.iconArea, "CENTER", circleX, 0)    
            rewardCircles[groupKey][itemIdx] = circle    
        end    
    end    
    
    -- Botón Confirmar Invocación (Ventana 2)    
    local confirmBtn = CreateFrame("Button", nil, phase2, "UIPanelButtonTemplate")    
    confirmBtn:SetSize(220, 35)    
    confirmBtn:SetPoint("BOTTOM", 0, 10)    
    confirmBtn:SetText("Confirmar Invocación")    
    
    confirmBtn:SetScript("OnClick", function()    
        local selCount = 0    
        for _ in pairs(selectedRewards) do selCount = selCount + 1 end    
    
        if selCount < totalGroups then    
            print("[BossClancyGood] Debes seleccionar una recompensa de cada grupo.")    
            return    
        end    
    
        AIO.Handle("BossClancyGood", "SelectReward", selectedRewards)    
        frame2:Hide()    
        frame1:Hide()    
    end)    
    
    -- ============================    
    -- LÓGICA DEL BOTÓN INVOCAR (Ventana 1)    
    -- ============================    
    invokeBtn:SetScript("OnClick", function()    
        -- Auto-llenar slots vacíos    
        for _, slot in ipairs(itemSlots) do    
            if not slot.filled and GetItemCount(slot.itemData.id) > 0 then    
                slot.filled = true    
                slot.icon:SetTexture(GetItemIcon(slot.itemData.id))    
                slot.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)    
                slot.icon:SetVertexColor(1, 1, 1, 1)
                slot.icon:SetDesaturated(false)
                slot.icon:Show()    
                slot.bg:SetVertexColor(0, 0.5, 0, 0.8)    
                slot.border:SetVertexColor(0, 1, 0)    
            end    
        end    
    
        -- Verificar que todos los slots estén llenos    
        for _, slot in ipairs(itemSlots) do    
            if not slot.filled then    
                print("[BossClancyGood] Faltan esferas por colocar.")    
                return    
            end    
        end    
    
        -- Esferas completas: ocultar Ventana 1, mostrar Ventana 2    
        frame1:Hide()    
        frame2:Show()    
    end)    
    
    -- Deshabilitar botón si no tiene items    
    if not hasItems then    
        invokeBtn:Disable()    
    end    
    
    frame1:Show()    
end    
    
-- ========================================          
-- REGISTRO DE HANDLERS    
-- ========================================          
    
AIO.AddHandlers("BossClancyGood", {    
    ShowBossSpawned = ShowBossSpawned,    
    ShowRewardSelection = ShowRewardSelection    
})    
    
print("[BossClancyGood] Cliente cargado.")
