--[[          
    Sistema de Invocación de Jefes - Interfaz de Cliente          
    Diseño: Mesa de Invocación del Dragon    
    - Phase 1: Escudo central + 7 esferas en círculo + botón Invocar    
    - Phase 2: 5 grupos de recompensas (layout 2+3)    
]]--          
          
local AIO = AIO or require("AIO")          
          
if AIO.AddAddon() then          
    return          
end          
          
-- ========================================          
-- CONFIGURACIÓN VISUAL          
-- ========================================          
          
local UI_CONFIG = {          
    frame_size = {width = 1200, height = 800},    
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
-- FRAME PRINCIPAL (estático)    
-- ========================================          
          
local frame = CreateFrame("Frame", "BossSummonFrame", UIParent)          
frame:SetSize(UI_CONFIG.frame_size.width, UI_CONFIG.frame_size.height)          
frame:SetPoint("CENTER")          
frame:SetBackdrop({          
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",          
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",          
    tile = true, tileSize = 32, edgeSize = 32,          
    insets = {left = 11, right = 12, top = 12, bottom = 11}          
})          
frame:SetBackdropColor(0.08, 0.08, 0.1, 0.97)    
frame:EnableMouse(true)    
frame:SetMovable(true)    
frame:RegisterForDrag("LeftButton")    
frame:SetScript("OnDragStart", frame.StartMoving)    
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)    
frame:Hide()          
          
-- Título principal    
local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")          
titleText:SetPoint("TOP", 0, -8)          
titleText:SetText("|cffFFD700Mesa de Invocación del Dragon|r")          
          
-- Botón de cerrar          
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")          
closeBtn:SetPoint("TOPRIGHT", -5, -5)          
    
-- Contenedor dinámico    
local content = CreateFrame("Frame", nil, frame)    
content:SetAllPoints()    
    
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
    
local function ClearContent()    
    for i = 1, content:GetNumChildren() do    
        local child = select(i, content:GetChildren())    
        if child then child:Hide() end    
    end    
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
    icon:Hide()          
    container.icon = icon      
              
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
            icon:Hide()          
            bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)          
            border:SetVertexColor(0.6, 0.6, 0.6)          
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
                    slot.icon:Show()      
                    slot.bg:SetVertexColor(0, 0.5, 0, 0.8)      
                    slot.border:SetVertexColor(0, 1, 0)      
                    ClearCursor()      
                    return      
                end      
            end      
        end          
    end)          
              
    container:SetScript("OnEnter", function()          
        GameTooltip:SetOwner(container, "ANCHOR_RIGHT")          
        if container.filled then          
            border:SetVertexColor(0, 1, 0)          
            GameTooltip:SetText("|cFF00FF00" .. itemData.name .. "|r\nItem colocado correctamente")          
        else          
            border:SetVertexColor(1, 0.8, 0)          
            GameTooltip:SetText("|cFFFFCC00" .. itemData.name .. "|r\nArrastra el item aquí")          
        end          
        GameTooltip:Show()          
    end)          
              
    container:SetScript("OnLeave", function()          
        if container.filled then    
            border:SetVertexColor(0, 0.8, 0)    
        else    
            border:SetVertexColor(0.6, 0.6, 0.6)    
        end    
        GameTooltip:Hide()          
    end)          
              
    return container          
end          
    
local function CreateRewardCircle(parent, rewardData, index, onClick)    
    local circle = CreateFrame("Button", nil, parent)    
    circle:SetSize(42, 42)    
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
        local name = rewardData.name or ("Item " .. (rewardData.id or "?"))    
        if circle.selected then    
            GameTooltip:SetText("|cFF00FFFF" .. name .. "|r\n|cFF00FF00Seleccionado|r")    
        else    
            GameTooltip:SetText("|cFFFFCC00" .. name .. "|r\nClick para seleccionar")    
        end    
        if rewardData.count and rewardData.count > 1 then    
            GameTooltip:AddLine("Cantidad: " .. rewardData.count, 1, 1, 1)    
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
    
    local msg = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")    
    msg:SetPoint("CENTER", 0, 20)    
    msg:SetText("|cffFF4444Un jefe ya ha sido invocado|r")    
    
    local sub = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    sub:SetPoint("CENTER", 0, -10)    
    if summonerName then    
        sub:SetText("Invocado por: |cffFFD700" .. summonerName .. "|r")    
    else    
        sub:SetText("Espera a que sea derrotado.")    
    end    
    
    frame:Show()    
end    
    
-- ========================================          
-- HANDLER: SELECCIÓN DE RECOMPENSAS    
-- ========================================          
    
local function ShowRewardSelection(player, groupedRewards, hasItems, missingItems)    
    ClearContent()    
    
    -- ============================    
    -- PHASE 1: PREPARACIÓN    
    -- ============================    
    local phase1 = CreateFrame("Frame", nil, content)    
    phase1:SetSize(1160, 360)    
    phase1:SetPoint("TOP", frame, "TOP", 0, -30)    
    phase1:SetBackdrop({    
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",    
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",    
        tile = true, tileSize = 32, edgeSize = 16,    
        insets = {left = 4, right = 4, top = 4, bottom = 4}    
    })    
    phase1:SetBackdropColor(0.04, 0.04, 0.06, 0.75)    
    phase1:SetBackdropBorderColor(0.5, 0.45, 0.3, 0.8)    
    
    -- Phase 1 label    
    local p1Label = phase1:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    p1Label:SetPoint("TOPLEFT", 15, -8)    
    p1Label:SetText("|cffDDCC99Phase 1: Preparation|r")    
    
    -- Contenedor del círculo de esferas    
    local circleContainer = CreateFrame("Frame", nil, phase1)    
    circleContainer:SetSize(300, 300)    
    circleContainer:SetPoint("CENTER", 0, 10)    
    
    -- Escudo central    
    local shield = circleContainer:CreateTexture(nil, "ARTWORK")    
    shield:SetSize(120, 140)    
    shield:SetPoint("CENTER", 0, 0)    
    shield:SetTexture("Interface/Icons/INV_Shield_06")    
    shield:SetTexCoord(0.08, 0.92, 0.08, 0.92)    
    
    -- 7 esferas en círculo (ángulo corregido: empieza arriba-izquierda, sentido horario)    
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
    
    -- Botón Invocar    
    local invokeBtn = CreateFrame("Button", nil, phase1, "UIPanelButtonTemplate")    
    invokeBtn:SetSize(200, 35)    
    invokeBtn:SetPoint("BOTTOM", 0, 15)    
    invokeBtn:SetText("Invocar")    
    
    -- ============================    
    -- PHASE 2: RECOMPENSAS    
    -- ============================    
    local phase2 = CreateFrame("Frame", nil, content)    
    phase2:SetSize(1160, 380)    
    phase2:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)    
    phase2:SetBackdrop({    
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",    
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",    
        tile = true, tileSize = 32, edgeSize = 16,    
        insets = {left = 4, right = 4, top = 4, bottom = 4}    
    })    
    phase2:SetBackdropColor(0.04, 0.04, 0.06, 0.75)    
    phase2:SetBackdropBorderColor(0.5, 0.45, 0.3, 0.8)    
    
    -- Phase 2 label    
    local p2Label = phase2:CreateFontString(nil, "OVERLAY", "GameFontNormal")    
    p2Label:SetPoint("TOPLEFT", 15, -8)    
    p2Label:SetText("|cffDDCC99Phase 2: Post-Invocation (Dragon Presence)|r")    
    
    -- ============================    
    -- GRUPOS DE RECOMPENSAS    
    -- ============================    
    local selectedRewards = {}    
    local rewardCircles = {}    
    local originalIndices = {}    
    
    -- Posiciones explícitas para 5 grupos (layout 2+3)    
    local panelW, panelH = 310, 130    
    local groupPositions = {    
        {anchor = "TOPLEFT",  parent = phase2, x = 20,   y = -32},    
        {anchor = "TOPRIGHT", parent = phase2, x = -20,  y = -32},    
        {anchor = "TOPLEFT",  parent = phase2, x = 20,   y = -175},    
        {anchor = "TOP",      parent = phase2, x = 0,    y = -175},    
        {anchor = "TOPRIGHT", parent = phase2, x = -20,  y = -175},    
    }    
    
    -- FIX Bug 5: ordenar keys para orden determinístico    
    local sortedKeys = {}    
    for k in pairs(groupedRewards) do    
        table.insert(sortedKeys, k)    
    end    
    table.sort(sortedKeys)    
    
    -- FIX Bug 3: contar grupos manualmente    
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
            -- FIX Bug 2: guardar el itemIndex original del servidor    
            local origIdx = item.itemIndex or itemIdx    
            originalIndices[groupKey][itemIdx] = origIdx    
    
            local circleX = startX + (itemIdx - 1) * spacing    
    
            local circle = CreateRewardCircle(panel.iconArea, item, itemIdx, function(self)    
                -- Deseleccionar si ya estaba seleccionado    
                if selectedRewards[groupKey] == origIdx then    
                    selectedRewards[groupKey] = nil    
                    self.selected = false    
                    self.border:SetVertexColor(UI_CONFIG.colors.normal.r, UI_CONFIG.colors.normal.g, UI_CONFIG.colors.normal.b)    
                    return    
                end    
    
                -- Deseleccionar el anterior de este grupo    
                if selectedRewards[groupKey] then    
                    for vi, oi in pairs(originalIndices[groupKey]) do    
                        if oi == selectedRewards[groupKey] and rewardCircles[groupKey][vi] then    
                            rewardCircles[groupKey][vi].selected = false    
                            rewardCircles[groupKey][vi].border:SetVertexColor(    
                                UI_CONFIG.colors.normal.r,    
                                UI_CONFIG.colors.normal.g,    
                                UI_CONFIG.colors.normal.b    
                            )    
                            break    
                        end    
                    end    
                end    
    
                -- Seleccionar este    
                selectedRewards[groupKey] = origIdx    
                self.selected = true    
                self.border:SetVertexColor(UI_CONFIG.colors.selected.r, UI_CONFIG.colors.selected.g, UI_CONFIG.colors.selected.b)    
            end)    
            circle:SetPoint("CENTER", panel.iconArea, "CENTER", circleX, 0)    
            rewardCircles[groupKey][itemIdx] = circle    
        end    
    end    
    
    -- ============================    
    -- LÓGICA DEL BOTÓN INVOCAR    
    -- ============================    
    invokeBtn:SetScript("OnClick", function()    
        -- Auto-llenar slots vacíos    
        for _, slot in ipairs(itemSlots) do    
            if not slot.filled and GetItemCount(slot.itemData.id) > 0 then    
                slot.filled = true    
                slot.icon:SetTexture(GetItemIcon(slot.itemData.id))    
                slot.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)    
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
    
        -- Verificar que se seleccionó una recompensa de cada grupo    
        local selCount = 0    
        for _ in pairs(selectedRewards) do selCount = selCount + 1 end    
    
        if selCount < totalGroups then    
            print("[BossClancyGood] Debes seleccionar una recompensa de cada grupo.")    
            return    
        end    
    
        -- Enviar al servidor    
        AIO.Handle("BossClancyGood", "SelectReward", selectedRewards)    
        frame:Hide()    
    end)    
    
    -- Deshabilitar botón si no tiene items    
    if not hasItems then    
        invokeBtn:Disable()    
    end    
    
    frame:Show()    
end    
    
-- ========================================          
-- REGISTRO DE HANDLERS    
-- ========================================          
    
AIO.AddHandlers("BossClancyGood", {    
    ShowBossSpawned = ShowBossSpawned,    
    ShowRewardSelection = ShowRewardSelection    
})    
    
print("[BossClancyGood] Cliente cargado.")
