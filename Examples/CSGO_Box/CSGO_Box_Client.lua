local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

-- ============================================================
-- CONSTANTES
-- ============================================================
local BG_TEXTURE = "Interface\\ChatFrame\\ChatFrameBackground"

local RARITY_COLORS = {
    white     = {r = 0.9,  g = 0.9,  b = 0.9},
    lightblue = {r = 0.6,  g = 0.8,  b = 1.0},
    blue      = {r = 0.0,  g = 0.4,  b = 1.0},
    purple    = {r = 0.6,  g = 0.2,  b = 0.8},
    pink      = {r = 0.9,  g = 0.3,  b = 0.6},
    red       = {r = 0.9,  g = 0.1,  b = 0.1},
    gold      = {r = 1.0,  g = 0.8,  b = 0.0},
}

local RARITY_HEX = {
    white     = "e6e6e6",
    lightblue = "99ccff",
    blue      = "0066ff",
    purple    = "9933cc",
    pink      = "e64d99",
    red       = "e61a1a",
    gold      = "ffcc00",
}

local RARITY_ORDER = {"white", "lightblue", "blue", "purple", "pink", "red", "gold"}

-- Reel constants
local CARD_WIDTH = 130
local CARD_HEIGHT = 100
local CARD_SPACING = 6
local CARD_TOTAL = CARD_WIDTH + CARD_SPACING
local RARITY_BAR_HEIGHT = 5
local VIEWPORT_WIDTH = 548
local VIEWPORT_HEIGHT = CARD_HEIGHT + 10

-- Animation constants
local ANIM_DURATION = 10
local FAST_DURATION = 3
local SLOW_DURATION = 7
local FAST_RATIO = FAST_DURATION / (FAST_DURATION + SLOW_DURATION / 2)
local SLOW_RATIO = 1 - FAST_RATIO
local CACHE_WAIT_FRAMES = 30

-- ============================================================
-- CREATURE ADJUSTMENTS (mismo patron que FelStormStore)
-- ============================================================
local CREATURE_ADJUSTMENTS = {
    -- [creatureId] = {scale, facing, x, y, z}
    -- Monturas del Cofre de Monturas - ajusta segun tu DB
    [32481]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Mimiron's Head
    [36597]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Invincible
    [28060]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Time-Lost Proto-Drake
    [26711]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Blue Proto-Drake
    [27796]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Twilight Drake
    [25831]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Black Drake
    [28670]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Onyxian Drake
    [31752]  = {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Grand Ice Mammoth
    [31857]  = {scale = 0.3, facing = 0.3, x = 0, y = 0, z = -0.3},  -- Grand Black War Mammoth
}

local function GetCreatureAdjustment(creatureId)
    local adj = CREATURE_ADJUSTMENTS[creatureId]
    if adj then
        return adj
    end
    -- Default values for unknown creatures
    return {scale = 0.4, facing = 0.3, x = 0, y = 0, z = -0.3}
end

-- ============================================================
-- COST HELPERS (gold o item)
-- ============================================================
-- Devuelve siempre {type, amount, [itemId]}, soportando caseInfo legacy con costGold.
local function NormalizeCaseCost(caseInfo)
    if type(caseInfo.cost) == "table" then
        return caseInfo.cost
    end
    if caseInfo.costGold then
        return { type = "gold", amount = caseInfo.costGold }
    end
    return { type = "gold", amount = 0 }
end

-- Render compacto del costo, listo para concatenar dentro de un FontString.
--   gold -> "|cffFFD700500 gold|r"
--   item -> "|TIcon:14|t |cffFFFFFF25 Emblema de Escarcha|r" (icono inline + cantidad + nombre)
local function FormatCostText(cost)
    if not cost then return "" end
    if cost.type == "gold" then
        local gold = math.ceil((cost.amount or 0) / 10000)
        return "|cffFFD700" .. gold .. " gold|r"
    end
    if cost.type == "item" and cost.itemId then
        local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(cost.itemId)
        local iconStr = "|T" .. (tex or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":14|t"
        local label = name or ("item #" .. cost.itemId)
        return iconStr .. " |cffFFFFFF" .. (cost.amount or 0) .. " " .. label .. "|r"
    end
    return ""
end

-- Variante corta para tarjetas pequenas:
--   gold -> "Costo: 500 Oro"
--   item -> "Costo: [icono] x25"
local function FormatCostShort(cost)
    if not cost then return "" end
    if cost.type == "gold" then
        local gold = math.ceil((cost.amount or 0) / 10000)
        return "|cffFFFFFFCosto:|r |cffFFD700" .. gold .. " Oro|r"
    end
    if cost.type == "item" and cost.itemId then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(cost.itemId)
        -- Icono mas grande (24px) para que se distinga bien en la tarjeta.
        local iconStr = "|T" .. (tex or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":24|t"
        return "|cffFFFFFFCosto:|r " .. iconStr .. " |cffFFFFFFx" .. (cost.amount or 0) .. "|r"
    end
    return ""
end

-- Para la cabecera del detalle: devuelve (texturaIcono, textoCantidad) por separado,
-- de modo que el icono se dibuje como Texture real (no inline) junto al texto.
--   gold -> "Interface\\MoneyFrame\\UI-GoldIcon", "500 Oro"
--   item -> textura del item, "x25"
local function GetCostIconAndText(cost)
    if cost and cost.type == "gold" then
        local gold = math.ceil((cost.amount or 0) / 10000)
        return "Interface\\MoneyFrame\\UI-GoldIcon", "|cffFFD200" .. gold .. " Oro|r"
    end
    if cost and cost.type == "item" and cost.itemId then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(cost.itemId)
        return (tex or "Interface\\Icons\\INV_Misc_QuestionMark"), "|cffFFFFFFx" .. (cost.amount or 0) .. "|r"
    end
    return "Interface\\MoneyFrame\\UI-GoldIcon", ""
end

-- ============================================================
-- STATE
-- ============================================================
local cachedCasesInfo = nil
local currentCaseId = nil
local currentCaseInfo = nil
local currentWinEntry = nil
local currentWinRarity = nil
local currentWinRarityName = nil
local currentWinCreatureId = nil
local spinning = false
local animElapsed = 0
local spinPosition = 0
local targetPosition = 0
local lastCardIndex = -1
local reelIcons = {}

local ShowCaseDetail
local _itemGridRetryFrame  -- frame de retry compartido entre llamadas a BuildItemGrid
local _reelRetryFrame      -- frame de retry compartido entre llamadas a BuildReelCards
local selectFrame          -- frame con la lista de cofres (asignado en SCREEN 4)

-- ============================================================
-- PRE-CACHE ITEMS
-- ============================================================
-- Tooltip oculto reutilizable para precachear items y poder consultarlos
-- con GetItemInfo despues. Crear un GameTooltip por item filtraba frames
-- (los frames en WoW no se pueden destruir).
local _scratchTooltip
local function GetScratchTooltip()
    if not _scratchTooltip then
        _scratchTooltip = CreateFrame("GameTooltip", "StrikeChestScratchTip", nil, "GameTooltipTemplate")
        _scratchTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return _scratchTooltip
end

local _preCacheFrame = CreateFrame("Frame")
_preCacheFrame:Hide()
local function PreCacheItems(entries, callback)
    local uniqueEntries = {}
    local seen = {}
    for _, e in ipairs(entries) do
        if not seen[e] then
            seen[e] = true
            table.insert(uniqueEntries, e)
        end
    end

    local cacheIndex = 0
    local waitFrames = 0
    _preCacheFrame:Show()
    _preCacheFrame:SetScript("OnUpdate", function(self)
        if cacheIndex < #uniqueEntries then
            cacheIndex = cacheIndex + 1
            local tt = GetScratchTooltip()
            tt:ClearLines()
            tt:SetHyperlink("item:" .. uniqueEntries[cacheIndex])
            tt:Hide()
        else
            waitFrames = waitFrames + 1
            if waitFrames >= CACHE_WAIT_FRAMES then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                if callback then callback() end
            end
        end
    end)
end

-- ============================================================
-- SCREEN 1: CASE GRID (Seleccion de cofres)
-- ============================================================
local gridFrame = CreateFrame("Frame", "StrikeChestGridFrame", UIParent)
gridFrame:SetSize(500, 350)
gridFrame:SetPoint("CENTER")
gridFrame:SetFrameStrata("DIALOG")
gridFrame:SetMovable(true)
gridFrame:EnableMouse(true)
gridFrame:RegisterForDrag("LeftButton")
gridFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
gridFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
gridFrame:Hide()

local gridBg = gridFrame:CreateTexture(nil, "BACKGROUND")
gridBg:SetAllPoints()
gridBg:SetTexture(BG_TEXTURE)
gridBg:SetVertexColor(0.05, 0.05, 0.05, 0.95)

local gridBorder = CreateFrame("Frame", nil, gridFrame)
gridBorder:SetPoint("TOPLEFT", -2, 2)
gridBorder:SetPoint("BOTTOMRIGHT", 2, -2)
gridBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
})
gridBorder:SetBackdropBorderColor(0.5, 0.4, 0.1, 0.8)

local gridTitle = gridFrame:CreateFontString(nil, "OVERLAY")
gridTitle:SetFont("Fonts\\FRIZQT__.TTF", 16)
gridTitle:SetPoint("TOP", 0, -12)
gridTitle:SetText("|cffFFD700Contenedores Disponibles|r")

local gridCloseBtn = CreateFrame("Button", nil, gridFrame, "UIPanelCloseButton")
gridCloseBtn:SetPoint("TOPRIGHT", -3, -3)
gridCloseBtn:SetScript("OnClick", function() gridFrame:Hide() end)

tinsert(UISpecialFrames, "StrikeChestGridFrame")

local gridCaseFrames = {}

-- ============================================================
-- SCREEN 2: CASE DETAIL (Detalle del cofre)
-- ============================================================
local overlay = CreateFrame("Frame", "StrikeChestOverlay", UIParent)
overlay:SetAllPoints(UIParent)
overlay:SetFrameStrata("FULLSCREEN_DIALOG")
overlay:EnableMouse(true)
overlay:Hide()

local overlayBg = overlay:CreateTexture(nil, "BACKGROUND")
overlayBg:SetAllPoints()
overlayBg:SetTexture(BG_TEXTURE)
overlayBg:SetVertexColor(0, 0, 0, 0.92)

tinsert(UISpecialFrames, "StrikeChestOverlay")

-- Detail view elements (visible before spinning)
-- detailContainer queda como capa legacy (ya no se usa para mostrar el detalle).
local detailContainer = CreateFrame("Frame", nil, overlay)
detailContainer:SetAllPoints()

-- Ventana del detalle ("Abrir contenedor"): ventana NORMAL centrada y movible.
-- Es top-level hija de UIParent (NO del overlay a pantalla completa), por lo que
-- no oscurece toda la pantalla ni bloquea el resto del juego.
local detailPanel = CreateFrame("Frame", "StrikeChestDetailPanel", UIParent)
detailPanel:SetSize(620, 500)
detailPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
detailPanel:SetFrameStrata("DIALOG")
detailPanel:SetToplevel(true)
detailPanel:SetClampedToScreen(true)
detailPanel:Hide()
tinsert(UISpecialFrames, "StrikeChestDetailPanel")
detailPanel:EnableMouse(true)
detailPanel:SetMovable(true)
detailPanel:RegisterForDrag("LeftButton")
detailPanel:SetScript("OnDragStart", function(self) self:StartMoving() end)
detailPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
detailPanel:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})

-- Capa interior oscura para dar el aspecto de "mazmorra" del fondo.
local detailInnerDark = detailPanel:CreateTexture(nil, "BORDER")
detailInnerDark:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 12, -12)
detailInnerDark:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -12, 12)
detailInnerDark:SetTexture(BG_TEXTURE)
detailInnerDark:SetVertexColor(0.03, 0.025, 0.02, 0.82)

-- Resplandor dorado detras del cofre (efecto "escenario").
local detailGlow = detailPanel:CreateTexture(nil, "ARTWORK")
detailGlow:SetTexture("Interface\\Common\\talent-blue-glow")
detailGlow:SetBlendMode("ADD")
detailGlow:SetVertexColor(1.0, 0.78, 0.22, 0.5)
detailGlow:SetSize(380, 380)

-- Cabecera ornamentada (banner) con el titulo.
local detailHeader = detailPanel:CreateTexture(nil, "ARTWORK")
detailHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
detailHeader:SetSize(320, 64)
detailHeader:SetPoint("TOP", detailPanel, "TOP", 0, 12)

local detailTitle = detailPanel:CreateFontString(nil, "OVERLAY")
detailTitle:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
detailTitle:SetPoint("TOP", detailHeader, "TOP", 0, -14)
detailTitle:SetText("|cffFFD200ABRIR CONTENEDOR|r")

-- Boton cerrar (X roja) arriba a la derecha.
local btnCloseDetail = CreateFrame("Button", nil, detailPanel, "UIPanelCloseButton")
btnCloseDetail:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -4, -4)
btnCloseDetail:SetScript("OnClick", function() detailPanel:Hide() end)

-- Nombre del cofre (dorado, grande).
local detailCaseName = detailPanel:CreateFontString(nil, "OVERLAY")
detailCaseName:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
detailCaseName:SetPoint("TOP", detailPanel, "TOP", 0, -54)

-- Coste: icono de moneda/objeto + cantidad.
local detailCost = detailPanel:CreateFontString(nil, "OVERLAY")
detailCost:SetFont("Fonts\\FRIZQT__.TTF", 15)
detailCost:SetPoint("TOP", detailCaseName, "BOTTOM", 11, -8)

local detailCostIcon = detailPanel:CreateTexture(nil, "ARTWORK")
detailCostIcon:SetSize(20, 20)
detailCostIcon:SetPoint("RIGHT", detailCost, "LEFT", -4, 0)

-- Cofre grande: boton clicable para abrir el contenedor.
local detailCaseIcon = CreateFrame("Button", nil, detailPanel)
detailCaseIcon:SetSize(150, 150)
detailCaseIcon:SetPoint("TOP", detailCost, "BOTTOM", -11, -18)

local detailCaseTex = detailCaseIcon:CreateTexture(nil, "ARTWORK")
detailCaseTex:SetAllPoints()
detailCaseTex:SetTexture("Interface\\Icons\\INV_Box_01")

local detailCaseHi = detailCaseIcon:CreateTexture(nil, "HIGHLIGHT")
detailCaseHi:SetAllPoints()
detailCaseHi:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
detailCaseHi:SetBlendMode("ADD")
detailCaseHi:SetVertexColor(1, 0.85, 0.2, 0.5)

detailGlow:SetPoint("CENTER", detailCaseIcon, "CENTER", 0, 0)

detailCaseIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cffFFD200Haz clic para abrir|r")
    GameTooltip:Show()
end)
detailCaseIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Linea informativa bajo el cofre.
local detailInfo = detailPanel:CreateFontString(nil, "OVERLAY")
detailInfo:SetFont("Fonts\\FRIZQT__.TTF", 12)
detailInfo:SetPoint("TOP", detailCaseIcon, "BOTTOM", 0, -12)
detailInfo:SetText("|cffcfcfcfEste contenedor solo se puede abrir una vez.|r")

-- Encabezado de la seccion de recompensas.
local rewardsHeader = detailPanel:CreateFontString(nil, "OVERLAY")
rewardsHeader:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
rewardsHeader:SetPoint("TOP", detailInfo, "BOTTOM", 0, -16)
rewardsHeader:SetText("|cffFFD200POSIBLES RECOMPENSAS|r")

-- Contenedor de la fila de recompensas (debajo del encabezado).
local itemGridContainer = CreateFrame("Frame", nil, detailPanel)
itemGridContainer:SetSize(580, 110)
itemGridContainer:SetPoint("TOP", rewardsHeader, "BOTTOM", 0, -12)

local itemGridFrames = {}

-- Boton "Volver" (regresa a la lista de cofres ya cacheada).
local btnBackToList = CreateFrame("Button", nil, detailPanel)
btnBackToList:SetSize(90, 24)
btnBackToList:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", 18, 16)

local btnBackText = btnBackToList:CreateFontString(nil, "OVERLAY")
btnBackText:SetFont("Fonts\\FRIZQT__.TTF", 13)
btnBackText:SetPoint("LEFT")
btnBackText:SetText("|cffcfcfcf< Volver|r")

btnBackToList:SetScript("OnEnter", function() btnBackText:SetText("|cffFFD200< Volver|r") end)
btnBackToList:SetScript("OnLeave", function() btnBackText:SetText("|cffcfcfcf< Volver|r") end)
btnBackToList:SetScript("OnClick", function()
    detailPanel:Hide()
    if selectFrame then selectFrame:Show() end
end)

-- ============================================================
-- SCREEN 3: SPINNING ANIMATION
-- ============================================================
local spinContainer = CreateFrame("Frame", nil, overlay)
spinContainer:SetAllPoints()
spinContainer:Hide()

local spinTitle = spinContainer:CreateFontString(nil, "OVERLAY")
spinTitle:SetFont("Fonts\\FRIZQT__.TTF", 22)
spinTitle:SetPoint("TOP", 0, -25)
spinTitle:SetText("|cffFFFFFFAbrir contenedor|r")

local spinCaseName = spinContainer:CreateFontString(nil, "OVERLAY")
spinCaseName:SetFont("Fonts\\FRIZQT__.TTF", 16)
spinCaseName:SetPoint("TOP", spinTitle, "BOTTOM", 0, -4)

local spinInfo = spinContainer:CreateFontString(nil, "OVERLAY")
spinInfo:SetFont("Fonts\\FRIZQT__.TTF", 11)
spinInfo:SetPoint("TOP", spinCaseName, "BOTTOM", 0, -4)
spinInfo:SetText("|cff888888(i) Este contenedor solo se puede abrir una vez|r")

-- Viewport (ScrollFrame for clipping)
local viewport = CreateFrame("ScrollFrame", nil, spinContainer)
viewport:SetSize(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
viewport:SetPoint("CENTER", spinContainer, "CENTER", 0, 0)

local vpBg = viewport:CreateTexture(nil, "BACKGROUND")
vpBg:SetAllPoints()
vpBg:SetTexture(BG_TEXTURE)
vpBg:SetVertexColor(0.06, 0.06, 0.06, 0.95)

-- Reel container (scroll child)
local reelContainer = CreateFrame("Frame", nil, viewport)
reelContainer:SetSize(1, VIEWPORT_HEIGHT)
reelContainer:SetPoint("TOPLEFT")
viewport:SetScrollChild(reelContainer)

-- Center marker (on spinContainer, not viewport, so it doesn't scroll)
local markerLine = spinContainer:CreateTexture(nil, "OVERLAY", nil, 7)
markerLine:SetSize(3, VIEWPORT_HEIGHT + 20)
markerLine:SetPoint("CENTER", viewport, "CENTER", 0, 0)
markerLine:SetTexture(BG_TEXTURE)
markerLine:SetVertexColor(1, 0.82, 0, 0.95)

-- Top triangle marker
local markerTop = spinContainer:CreateTexture(nil, "OVERLAY", nil, 7)
markerTop:SetSize(16, 10)
markerTop:SetPoint("BOTTOM", markerLine, "TOP", 0, 0)
markerTop:SetTexture(BG_TEXTURE)
markerTop:SetVertexColor(1, 0.82, 0, 0.95)

-- Bottom triangle marker
local markerBot = spinContainer:CreateTexture(nil, "OVERLAY", nil, 7)
markerBot:SetSize(16, 10)
markerBot:SetPoint("TOP", markerLine, "BOTTOM", 0, 0)
markerBot:SetTexture(BG_TEXTURE)
markerBot:SetVertexColor(1, 0.82, 0, 0.95)

-- Vignette overlays (on spinContainer)
local vigLeft = spinContainer:CreateTexture(nil, "OVERLAY", nil, 5)
vigLeft:SetSize(120, VIEWPORT_HEIGHT + 20)
vigLeft:SetPoint("RIGHT", viewport, "LEFT", 120, 0)
vigLeft:SetTexture(BG_TEXTURE)
vigLeft:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.95, 0, 0, 0, 0)

local vigRight = spinContainer:CreateTexture(nil, "OVERLAY", nil, 5)
vigRight:SetSize(120, VIEWPORT_HEIGHT + 20)
vigRight:SetPoint("LEFT", viewport, "RIGHT", -120, 0)
vigRight:SetTexture(BG_TEXTURE)
vigRight:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, 0.95)

-- Result text area
local resultItemName = spinContainer:CreateFontString(nil, "OVERLAY")
resultItemName:SetFont("Fonts\\FRIZQT__.TTF", 18)
resultItemName:SetPoint("TOP", viewport, "BOTTOM", 0, -25)
resultItemName:SetText("")

local resultRarityName = spinContainer:CreateFontString(nil, "OVERLAY")
resultRarityName:SetFont("Fonts\\FRIZQT__.TTF", 14)
resultRarityName:SetPoint("TOP", resultItemName, "BOTTOM", 0, -5)
resultRarityName:SetText("")

-- Post-result buttons
local btnOpenAnother = CreateFrame("Button", nil, spinContainer, "UIPanelButtonTemplate")
btnOpenAnother:SetSize(160, 30)
btnOpenAnother:SetPoint("TOP", resultRarityName, "BOTTOM", -90, -15)
btnOpenAnother:SetText("Abrir Otro")
btnOpenAnother:Hide()

local btnCloseResult = CreateFrame("Button", nil, spinContainer, "UIPanelButtonTemplate")
btnCloseResult:SetSize(160, 30)
btnCloseResult:SetPoint("TOP", resultRarityName, "BOTTOM", 90, -15)
btnCloseResult:SetText("Cerrar")
btnCloseResult:Hide()

-- (El handler real de btnCloseResult:OnClick se registra mas abajo, junto al
--  resto de acciones de resultado, para evitar duplicar logica.)

-- *** MODELO 3D: PlayerModel para monturas + DressUpModel para armas ***
local modelFrame = CreateFrame("PlayerModel", nil, overlay)
modelFrame:SetSize(300, 350)
modelFrame:SetPoint("CENTER", overlay, "CENTER", 0, 20)
modelFrame:SetFrameLevel(overlay:GetFrameLevel() + 10)
modelFrame:Hide()

local modelBg = modelFrame:CreateTexture(nil, "BACKGROUND")
modelBg:SetAllPoints()
modelBg:SetTexture(BG_TEXTURE)
modelBg:SetVertexColor(0.05, 0.05, 0.05, 0.9)

local modelRotating = false
local modelStartX = 0
local modelStartFacing = 0
modelFrame:EnableMouse(true)
modelFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        modelRotating = true
        modelStartX = GetCursorPosition()
        modelStartFacing = self:GetFacing()
    end
end)
modelFrame:SetScript("OnMouseUp", function()
    modelRotating = false
end)
modelFrame:SetScript("OnUpdate", function(self)
    if modelRotating then
        local x = GetCursorPosition()
        local diff = (x - modelStartX) * 0.02
        self:SetFacing(modelStartFacing + diff)
    end
end)

local modelHint = modelFrame:CreateFontString(nil, "OVERLAY")
modelHint:SetFont("Fonts\\FRIZQT__.TTF", 10)
modelHint:SetPoint("BOTTOM", modelFrame, "BOTTOM", 0, 5)
modelHint:SetText("|cff888888Arrastra para rotar|r")

-- DressUpModel separado para armas/armaduras (TryOn solo existe en DressUpModel)
local dressUpFrame = CreateFrame("DressUpModel", nil, overlay)
dressUpFrame:SetSize(300, 350)
dressUpFrame:SetPoint("CENTER", overlay, "CENTER", 0, 20)
dressUpFrame:SetFrameLevel(overlay:GetFrameLevel() + 10)
dressUpFrame:Hide()

local dressUpBg = dressUpFrame:CreateTexture(nil, "BACKGROUND")
dressUpBg:SetAllPoints()
dressUpBg:SetTexture(BG_TEXTURE)
dressUpBg:SetVertexColor(0.05, 0.05, 0.05, 0.9)

dressUpFrame:EnableMouse(true)
dressUpFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        modelRotating = true
        modelStartX = GetCursorPosition()
        modelStartFacing = self:GetFacing()
    end
end)
dressUpFrame:SetScript("OnMouseUp", function()
    modelRotating = false
end)
dressUpFrame:SetScript("OnUpdate", function(self)
    if modelRotating then
        local x = GetCursorPosition()
        local diff = (x - modelStartX) * 0.02
        self:SetFacing(modelStartFacing + diff)
    end
end)

local dressUpHint = dressUpFrame:CreateFontString(nil, "OVERLAY")
dressUpHint:SetFont("Fonts\\FRIZQT__.TTF", 10)
dressUpHint:SetPoint("BOTTOM", dressUpFrame, "BOTTOM", 0, 5)
dressUpHint:SetText("|cff888888Arrastra para rotar|r")

-- *** Icono grande para items no-equipables sin modelo de criatura ***
-- (consumibles, recetas, materiales: GetItemInfo equipLoc == "" o nil)
local iconResultFrame = CreateFrame("Frame", nil, overlay)
iconResultFrame:SetSize(300, 350)
iconResultFrame:SetPoint("CENTER", overlay, "CENTER", 0, 20)
iconResultFrame:SetFrameLevel(overlay:GetFrameLevel() + 10)
iconResultFrame:Hide()

local iconResultBg = iconResultFrame:CreateTexture(nil, "BACKGROUND")
iconResultBg:SetAllPoints()
iconResultBg:SetTexture(BG_TEXTURE)
iconResultBg:SetVertexColor(0.05, 0.05, 0.05, 0.9)

local iconResultBorder = iconResultFrame:CreateTexture(nil, "BORDER")
iconResultBorder:SetSize(208, 208)
iconResultBorder:SetPoint("CENTER", iconResultFrame, "CENTER", 0, 10)
iconResultBorder:SetTexture("Interface\\Buttons\\UI-EmptySlot")
iconResultBorder:SetVertexColor(0.6, 0.6, 0.6, 0.85)

local iconResultIcon = iconResultFrame:CreateTexture(nil, "ARTWORK")
iconResultIcon:SetSize(192, 192)
iconResultIcon:SetPoint("CENTER", iconResultFrame, "CENTER", 0, 10)
iconResultIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

-- Tooltip al pasar el raton sobre el icono grande.
iconResultFrame:EnableMouse(true)
iconResultFrame:SetScript("OnEnter", function(self)
    if not self._entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. self._entry)
    GameTooltip:Show()
end)
iconResultFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- *** FIN icono grande ***
-- *** FIN MODELO 3D ***

-- *** NUEVO: Creature Preloader (frame casi invisible para pre-cargar modelos) ***
-- Tiene que estar shown y on-screen (aunque sea con alpha 0 y 1x1 px) para que
-- el cliente cargue realmente el modelo de la criatura en cache. Lo dejamos
-- justo dentro del area visible (0,0) en vez de fuera de pantalla.
local creaturePreloader = CreateFrame("PlayerModel", nil, UIParent)
creaturePreloader:SetSize(1, 1)
creaturePreloader:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
creaturePreloader:SetAlpha(0)
creaturePreloader:Show()

-- Cola de criaturas a precachear. El preloader solo guarda 1 modelo a la vez,
-- asi que iteramos por OnUpdate (un creature por frame) en vez de hacer un loop
-- que se sobrescribe a si mismo y solo precachea la ultima.
local _creatureQueue = {}
local _creatureQueueSeen = {}
local _creatureQueueFrame = CreateFrame("Frame")
_creatureQueueFrame:Hide()
_creatureQueueFrame:SetScript("OnUpdate", function(self)
    local id = table.remove(_creatureQueue, 1)
    if id then
        creaturePreloader:ClearModel()
        creaturePreloader:SetCreature(id)
        creaturePreloader:SetCamera(0)
    else
        self:Hide()
    end
end)

local function QueueCreaturePreload(id)
    if not id or id <= 0 or _creatureQueueSeen[id] then return end
    _creatureQueueSeen[id] = true
    table.insert(_creatureQueue, id)
    _creatureQueueFrame:Show()
end
-- *** FIN NUEVO ***

-- ============================================================
-- FUNCTIONS: Build Item Grid for Detail View
-- ============================================================
local function BuildItemGrid(caseInfo)
    -- Clear old items
    for _, f in ipairs(itemGridFrames) do
        f:Hide()
        f:SetParent(nil)
    end
    itemGridFrames = {}

    local items = caseInfo.items
    if not items then return end

    -- Sort items by rarity order
    local rarityIndex = {}
    for i, r in ipairs(RARITY_ORDER) do
        rarityIndex[r] = i
    end
    local sortedItems = {}
    for _, item in ipairs(items) do
        table.insert(sortedItems, item)
    end
    table.sort(sortedItems, function(a, b)
        return (rarityIndex[a.rarity] or 99) < (rarityIndex[b.rarity] or 99)
    end)

    local ITEM_SIZE = 56
    local ITEM_GAP = 8
    local ITEMS_PER_ROW = 9
    local numItems = #sortedItems
    local numRows = math.ceil(numItems / ITEMS_PER_ROW)
    local totalGridW = ITEMS_PER_ROW * (ITEM_SIZE + ITEM_GAP) - ITEM_GAP
    local totalGridH = numRows * (ITEM_SIZE + 30 + ITEM_GAP) - ITEM_GAP

    itemGridContainer:SetSize(totalGridW, totalGridH)

    for idx, item in ipairs(sortedItems) do
        local row = math.floor((idx - 1) / ITEMS_PER_ROW)
        local col = (idx - 1) % ITEMS_PER_ROW

        local card = CreateFrame("Frame", nil, itemGridContainer)
        card:SetSize(ITEM_SIZE, ITEM_SIZE + 30)
        local xOff = col * (ITEM_SIZE + ITEM_GAP) - totalGridW / 2 + ITEM_SIZE / 2
        local yOff = -row * (ITEM_SIZE + 30 + ITEM_GAP)
        card:SetPoint("TOP", itemGridContainer, "TOP", xOff, yOff)
        card:EnableMouse(true)  -- *** NUEVO: habilitar mouse para tooltip ***

        -- Card background
        local cardBg = card:CreateTexture(nil, "BACKGROUND")
        cardBg:SetPoint("TOPLEFT")
        cardBg:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", 0, -ITEM_SIZE)
        cardBg:SetTexture(BG_TEXTURE)
        cardBg:SetVertexColor(0.06, 0.06, 0.06, 1)

        -- Marco biselado del slot (estilo inventario).
        local slotFrame = card:CreateTexture(nil, "OVERLAY")
        slotFrame:SetPoint("TOPLEFT", card, "TOPLEFT", -1, 1)
        slotFrame:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", 1, -ITEM_SIZE - 1)
        slotFrame:SetTexture("Interface\\Common\\WhiteIconFrame")
        slotFrame:SetVertexColor(0.72, 0.62, 0.36, 1)

        -- Item icon
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ITEM_SIZE - 8, ITEM_SIZE - 8)
        icon:SetPoint("CENTER", card, "TOP", 0, -ITEM_SIZE / 2)

        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item.entry)
        if itemTexture then
            icon:SetTexture(itemTexture)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        -- Rarity bottom bar
        local color = RARITY_COLORS[item.rarity] or RARITY_COLORS.white
        local rarBar = card:CreateTexture(nil, "OVERLAY")
        rarBar:SetSize(ITEM_SIZE, 3)
        rarBar:SetPoint("BOTTOM", card, "TOP", 0, -ITEM_SIZE)
        rarBar:SetTexture(BG_TEXTURE)
        rarBar:SetVertexColor(color.r, color.g, color.b, 1)

        -- Item name
        local nameText = card:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 8)
        nameText:SetPoint("TOP", card, "TOP", 0, -ITEM_SIZE - 4)
        nameText:SetWidth(ITEM_SIZE)
        nameText:SetJustifyH("CENTER")

        local itemName = GetItemInfo(item.entry)
        if itemName then
            local hex = RARITY_HEX[item.rarity] or "e6e6e6"
            nameText:SetText("|cff" .. hex .. itemName .. "|r")
        else
            nameText:SetText("|cff888888Item #" .. item.entry .. "|r")
        end

        -- *** NUEVO: Tooltip al pasar el mouse sobre el item ***
        local itemEntry = item.entry
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. itemEntry .. ":0:0:0:0:0:0:0")
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        -- *** FIN NUEVO ***

        -- Store for retry
        card._icon = icon
        card._nameText = nameText
        card._entry = item.entry
        card._rarity = item.rarity

        table.insert(itemGridFrames, card)
    end

    -- Retry para items que aun no estan cacheados.
    -- Frame compartido reutilizado entre llamadas (no se puede destruir un Frame en WoW).
    if not _itemGridRetryFrame then
        _itemGridRetryFrame = CreateFrame("Frame")
    end
    local retryCount = 0
    _itemGridRetryFrame:SetScript("OnUpdate", function(self)
        retryCount = retryCount + 1
        if retryCount > 300 then
            self:SetScript("OnUpdate", nil)
            return
        end
        if retryCount % 5 ~= 0 then return end

        local allDone = true
        for _, card in ipairs(itemGridFrames) do
            if card._entry then
                local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(card._entry)
                if tex then
                    card._icon:SetTexture(tex)
                end
                if name then
                    local hex = RARITY_HEX[card._rarity] or "e6e6e6"
                    card._nameText:SetText("|cff" .. hex .. name .. "|r")
                end
                if not name or not tex then
                    allDone = false
                end
            end
        end
        if allDone then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- ============================================================
-- FUNCTIONS: Show Case Detail (Screen 2)
-- ============================================================
ShowCaseDetail = function(caseId, caseInfo)
    currentCaseId = caseId
    currentCaseInfo = caseInfo

    -- Mostrar la ventana de detalle como ventana NORMAL (sin oscurecer la
    -- pantalla). Ocultamos el overlay de giro/resultado (y sus hijos).
    gridFrame:Hide()
    overlay:Hide()
    detailPanel:Show()

    -- Nombre del cofre (dorado) y coste (icono de moneda + cantidad) debajo.
    local cost = NormalizeCaseCost(caseInfo)
    detailCaseName:SetText("|cffFFD200" .. caseInfo.name .. "|r")
    local costIcon, costText = GetCostIconAndText(cost)
    detailCostIcon:SetTexture(costIcon)
    detailCost:SetText(costText)

    -- Cofre grande (textura del boton clicable).
    detailCaseTex:SetTexture(caseInfo.icon or "Interface\\Icons\\INV_Box_01")

    -- Build item grid
    BuildItemGrid(caseInfo)

    -- *** NUEVO: Pre-cargar modelos de criaturas del cofre (encolando) ***
    if caseInfo.items then
        for _, itemData in ipairs(caseInfo.items) do
            QueueCreaturePreload(itemData.creatureEntry)
        end
    end
    -- *** FIN NUEVO ***

    -- Abrir el contenedor al hacer clic sobre el cofre.
    detailCaseIcon:SetScript("OnClick", function()
        AIO.Handle("StrikeChest", "RequestOpen", caseId)
    end)
end

-- ============================================================
-- FUNCTIONS: Show Case Grid (Screen 1)
-- ============================================================
local function ShowCaseGrid(casesInfo)
    cachedCasesInfo = casesInfo

    -- Clear old case frames
    for _, f in ipairs(gridCaseFrames) do
        f:Hide()
        f:SetParent(nil)
    end
    gridCaseFrames = {}

    -- Pre-cache all items from all cases (incluido el item-coste si lo hay).
    local allEntries = {}
    for _, caseInfo in pairs(casesInfo) do
        if caseInfo.items then
            for _, item in ipairs(caseInfo.items) do
                table.insert(allEntries, item.entry)
            end
        end
        local cost = NormalizeCaseCost(caseInfo)
        if cost.type == "item" and cost.itemId then
            table.insert(allEntries, cost.itemId)
        end
    end
    PreCacheItems(allEntries, nil)

    -- Sort case IDs
    local sortedIds = {}
    for id in pairs(casesInfo) do
        table.insert(sortedIds, id)
    end
    table.sort(sortedIds)

    local numCases = #sortedIds
    local CASE_CARD_W = 130
    local CASE_CARD_H = 160
    local CASE_GAP = 20
    local totalW = numCases * CASE_CARD_W + (numCases - 1) * CASE_GAP
    gridFrame:SetSize(totalW + 60, CASE_CARD_H + 80)

    for idx, id in ipairs(sortedIds) do
        local info = casesInfo[id]

        local card = CreateFrame("Frame", nil, gridFrame)
        card:SetSize(CASE_CARD_W, CASE_CARD_H)
        local xOff = -totalW / 2 + (idx - 1) * (CASE_CARD_W + CASE_GAP) + CASE_CARD_W / 2
        card:SetPoint("TOP", gridFrame, "TOP", xOff, -45)
        card:EnableMouse(true)

        -- Card background
        local cardBg = card:CreateTexture(nil, "BACKGROUND")
        cardBg:SetAllPoints()
        cardBg:SetTexture(BG_TEXTURE)
        cardBg:SetVertexColor(0.1, 0.1, 0.1, 0.95)

        -- Border
        card:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
        })
        card:SetBackdropBorderColor(0.6, 0.5, 0.2, 0.8)

        -- Case icon
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(64, 64)
        icon:SetPoint("TOP", card, "TOP", 0, -12)
        icon:SetTexture(info.icon or "Interface\\Icons\\INV_Box_01")

        -- Case name
        local nameText = card:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        nameText:SetPoint("TOP", icon, "BOTTOM", 0, -6)
        nameText:SetWidth(CASE_CARD_W - 10)
        nameText:SetJustifyH("CENTER")
        nameText:SetText("|cffFFFFFF" .. info.name .. "|r")

        -- Price
        local _gridCost = NormalizeCaseCost(info)
        local goldAmount = math.ceil((_gridCost.amount or 0) / 10000)
        local priceText = card:CreateFontString(nil, "OVERLAY")
        priceText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        priceText:SetPoint("TOP", nameText, "BOTTOM", 0, -4)
        priceText:SetText("|cffFFD700" .. goldAmount .. " gold|r")

        -- Hover highlight
        local highlight = card:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(BG_TEXTURE)
        highlight:SetVertexColor(1, 1, 1, 0.08)

        -- Click handler -> go to detail view
        card:SetScript("OnMouseUp", function()
            ShowCaseDetail(id, info)
        end)

        -- Tooltip on hover: show item list
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(info.name, 1, 0.82, 0)
            GameTooltip:AddLine("Precio: " .. goldAmount .. " gold", 1, 0.84, 0)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Contiene uno de los siguientes objetos:", 0.7, 0.7, 0.7)

            if info.items then
                -- Group items by rarity
                local byRarity = {}
                for _, item in ipairs(info.items) do
                    if not byRarity[item.rarity] then
                        byRarity[item.rarity] = {}
                    end
                    table.insert(byRarity[item.rarity], item)
                end

                for _, rarKey in ipairs(RARITY_ORDER) do
                    local items = byRarity[rarKey]
                    if items then
                        local color = RARITY_COLORS[rarKey]
                        for _, item in ipairs(items) do
                            local itemName = GetItemInfo(item.entry)
                            if not itemName then
                                itemName = "Item #" .. item.entry
                            end
                            GameTooltip:AddLine(itemName .. " | " .. item.rarityName, color.r, color.g, color.b)
                        end
                    end
                end

                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("!o un objeto especial extraordinariamente raro!", 1, 0.8, 0)
            end

            GameTooltip:Show()
        end)

        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(gridCaseFrames, card)
    end

    overlay:Hide()
    gridFrame:Show()
end

-- ============================================================
-- FUNCTIONS: Build Reel Cards
-- ============================================================
local function BuildReelCards(reelData)
    for _, data in ipairs(reelIcons) do
        if data.frame then
            data.frame:Hide()
            data.frame:SetParent(nil)
        end
    end
    reelIcons = {}

    local totalWidth = #reelData * CARD_TOTAL
    reelContainer:SetSize(totalWidth, VIEWPORT_HEIGHT)

    for i, itemData in ipairs(reelData) do
        local card = CreateFrame("Frame", nil, reelContainer)
        card:SetSize(CARD_WIDTH, CARD_HEIGHT)
        card:SetPoint("LEFT", reelContainer, "LEFT", (i - 1) * CARD_TOTAL, 0)

        local cardBg = card:CreateTexture(nil, "BACKGROUND")
        cardBg:SetAllPoints()
        cardBg:SetTexture(BG_TEXTURE)
        cardBg:SetVertexColor(0.12, 0.12, 0.12, 1)

        local iconSize = 80
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER", card, "CENTER", 0, 3)

        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemData.entry)
        if itemTexture then
            icon:SetTexture(itemTexture)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local color = RARITY_COLORS[itemData.rarity] or RARITY_COLORS.white
        local rarityBar = card:CreateTexture(nil, "OVERLAY")
        rarityBar:SetSize(CARD_WIDTH, RARITY_BAR_HEIGHT)
        rarityBar:SetPoint("BOTTOM", card, "BOTTOM", 0, 0)
        rarityBar:SetTexture(BG_TEXTURE)
        rarityBar:SetVertexColor(color.r, color.g, color.b, 1)

        local topLine = card:CreateTexture(nil, "OVERLAY")
        topLine:SetSize(CARD_WIDTH, 1)
        topLine:SetPoint("TOP", card, "TOP", 0, 0)
        topLine:SetTexture(BG_TEXTURE)
        topLine:SetVertexColor(color.r, color.g, color.b, 0.3)

        reelIcons[i] = {
            frame = card,
            icon = icon,
            entry = itemData.entry,
            rarity = itemData.rarity,
        }
    end

    -- Retry para iconos del reel no cacheados.
    -- Frame y tooltip compartidos para no acumular frames a cada apertura.
    if not _reelRetryFrame then
        _reelRetryFrame = CreateFrame("Frame")
    end
    local retryCount = 0
    _reelRetryFrame:SetScript("OnUpdate", function(self)
        retryCount = retryCount + 1
        if retryCount > 300 then
            self:SetScript("OnUpdate", nil)
            return
        end
        if retryCount % 5 ~= 0 then return end
        local allCached = true
        local tt
        for _, data in ipairs(reelIcons) do
            local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(data.entry)
            if tex then
                data.icon:SetTexture(tex)
            else
                allCached = false
                tt = tt or GetScratchTooltip()
                tt:ClearLines()
                tt:SetHyperlink("item:" .. data.entry)
                tt:Hide()
            end
        end
        if allCached then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- ============================================================
-- FUNCTIONS: Reveal Result
-- ============================================================
-- equipLoc que SI tienen "slot" pero NO se renderizan en DressUpModel: bolsas,
-- carcaj, municion, reliquias, etc. Para esos preferimos el icono grande.
local NON_RENDERED_EQUIP_LOC = {
    INVTYPE_BAG       = true,
    INVTYPE_QUIVER    = true,
    INVTYPE_AMMO      = true,
    INVTYPE_RELIC     = true,
    INVTYPE_NON_EQUIP = true,
}

-- Devuelve true si el item es renderizable en DressUpModel.
-- Si el item aun no esta cacheado, devuelve false: en ese caso preferimos mostrar
-- el icono grande antes que un personaje desnudo aleatorio.
local function IsItemEquipable(entry)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(entry)
    if not equipLoc or equipLoc == "" then return false end
    if NON_RENDERED_EQUIP_LOC[equipLoc] then return false end
    return true
end

local function RevealResult()
    local color = RARITY_COLORS[currentWinRarity] or RARITY_COLORS.white
    local hex = RARITY_HEX[currentWinRarity] or "e6e6e6"

    local itemName = GetItemInfo(currentWinEntry)
    if not itemName then
        itemName = "Item #" .. currentWinEntry
    end

    -- *** CAMBIO: Mostrar modelo 3D con SetCreature para monturas ***
    spinContainer:Hide()

    -- Helper local para reposicionar texto y botones en torno al frame visible.
    -- Orden vertical (de arriba a abajo): nombre del item -> rareza -> modelo/icono.
    -- La rareza ya no cae debajo del nombre (que dejaba el texto sobre el modelo);
    -- ahora va entre el nombre y el frame, siempre por encima del modelo.
    local function anchorToFrame(displayFrame)
        resultRarityName:SetParent(overlay)
        resultRarityName:ClearAllPoints()
        resultRarityName:SetPoint("BOTTOM", displayFrame, "TOP", 0, 8)

        resultItemName:SetParent(overlay)
        resultItemName:ClearAllPoints()
        resultItemName:SetPoint("BOTTOM", resultRarityName, "TOP", 0, 4)

        btnOpenAnother:SetParent(overlay)
        btnOpenAnother:ClearAllPoints()
        btnOpenAnother:SetPoint("TOP", displayFrame, "BOTTOM", -90, -15)

        btnCloseResult:SetParent(overlay)
        btnCloseResult:ClearAllPoints()
        btnCloseResult:SetPoint("TOP", displayFrame, "BOTTOM", 90, -15)
    end

    if currentWinCreatureId and currentWinCreatureId > 0 then
        -- A) Es una montura: PlayerModel + SetCreature.
        dressUpFrame:Hide()
        iconResultFrame:Hide()
        modelFrame:Show()
        local adj = GetCreatureAdjustment(currentWinCreatureId)
        modelFrame:SetCreature(currentWinCreatureId)
        modelFrame:SetCamera(0)
        modelFrame:SetModelScale(adj.scale or 0.4)
        modelFrame:SetFacing(adj.facing or 0.3)
        modelFrame:SetPosition(adj.x or 0, adj.y or 0, adj.z or -0.3)
        anchorToFrame(modelFrame)
    elseif IsItemEquipable(currentWinEntry) then
        -- B) Item equipable (arma/armadura): DressUpModel + TryOn.
        modelFrame:Hide()
        iconResultFrame:Hide()
        dressUpFrame:Show()
        dressUpFrame:SetUnit("player")
        dressUpFrame:Undress()
        dressUpFrame:SetFacing(0.4)
        local _, itemLink = GetItemInfo(currentWinEntry)
        if itemLink then
            dressUpFrame:TryOn(itemLink)
        else
            dressUpFrame:TryOn("item:" .. currentWinEntry .. ":0:0:0:0:0:0:0")
        end
        anchorToFrame(dressUpFrame)
    else
        -- C) Item no equipable y sin creatureEntry (consumibles, recetas, materiales,
        --    o item aun sin cachear): mostramos solo el icono grande.
        modelFrame:Hide()
        dressUpFrame:Hide()
        iconResultFrame._entry = currentWinEntry
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(currentWinEntry)
        iconResultIcon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
        iconResultBorder:SetVertexColor(color.r, color.g, color.b, 0.9)
        iconResultFrame:Show()
        anchorToFrame(iconResultFrame)
    end
    -- *** FIN CAMBIO ***

    resultItemName:SetText("|cff" .. hex .. itemName .. "|r")
    resultRarityName:SetText("|cff" .. hex .. currentWinRarityName .. "|r")

    btnOpenAnother:Show()
    btnCloseResult:Show()

    PlaySound("LevelUp")

    -- Claim reward from server
    AIO.Handle("StrikeChest", "ClaimReward")
end

-- ============================================================
-- FUNCTIONS: Start Spin Animation
-- ============================================================
local animFrame = CreateFrame("Frame")

local function StartSpinAnimation(reelData, winPosition)
    -- Switch to spin view
    detailContainer:Hide()
    detailPanel:Hide()
    modelFrame:Hide()
    dressUpFrame:Hide()
    iconResultFrame:Hide()
    spinContainer:Show()

    resultItemName:SetText("")
    resultRarityName:SetText("")
    btnOpenAnother:Hide()
    btnCloseResult:Hide()

    -- *** NUEVO: Pre-cargar modelo de criatura ganadora durante la animacion ***
    QueueCreaturePreload(currentWinCreatureId)
    -- *** FIN NUEVO ***

    -- Pre-cache reel items then build and animate
    local entries = {}
    for _, item in ipairs(reelData) do
        table.insert(entries, item.entry)
    end

    PreCacheItems(entries, function()
        BuildReelCards(reelData)

        -- Calculate target position
        targetPosition = (winPosition - 1) * CARD_TOTAL - (VIEWPORT_WIDTH / 2) + (CARD_TOTAL / 2)
        spinPosition = 0
        animElapsed = 0
        lastCardIndex = -1
        spinning = true

        viewport:SetHorizontalScroll(0)

        animFrame:SetScript("OnUpdate", function(self, elapsed)
            if not spinning then return end

            animElapsed = animElapsed + elapsed

            if animElapsed >= ANIM_DURATION then
                spinning = false
                spinPosition = targetPosition
                viewport:SetHorizontalScroll(spinPosition)
                animFrame:SetScript("OnUpdate", nil)

                -- Delay reveal
                local revealFrame = CreateFrame("Frame")
                local revealWait = 0
                revealFrame:SetScript("OnUpdate", function(rf, el)
                    revealWait = revealWait + el
                    if revealWait >= 0.5 then
                        rf:SetScript("OnUpdate", nil)
                        RevealResult()
                    end
                end)

                PlaySound("ReadyCheck")
                return
            end

            -- Calculate progress with two phases
            local progress
            if animElapsed <= FAST_DURATION then
                progress = FAST_RATIO * (animElapsed / FAST_DURATION)
            else
                local t = (animElapsed - FAST_DURATION) / SLOW_DURATION
                progress = FAST_RATIO + SLOW_RATIO * t * (2 - t)
            end

            spinPosition = targetPosition * progress
            viewport:SetHorizontalScroll(spinPosition)

            -- Tick sound when passing a card
            local currentCardIndex = math.floor(spinPosition / CARD_TOTAL)
            if currentCardIndex ~= lastCardIndex then
                lastCardIndex = currentCardIndex
                PlaySound("igMainMenuOptionCheckBoxOn")
            end
        end)
    end)
end

-- ============================================================
-- CASE SELECTION GRID (Screen 1)
-- ============================================================
selectFrame = CreateFrame("Frame", "StrikeChestSelectFrame", UIParent)
selectFrame:SetSize(500, 300)
selectFrame:SetPoint("CENTER")
selectFrame:SetFrameStrata("DIALOG")
selectFrame:SetFrameLevel(50)
selectFrame:Hide()
selectFrame:EnableMouse(true)
selectFrame:SetMovable(true)
selectFrame:RegisterForDrag("LeftButton")
selectFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
selectFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
tinsert(UISpecialFrames, "StrikeChestSelectFrame")

local selectBg = selectFrame:CreateTexture(nil, "BACKGROUND")
selectBg:SetAllPoints()
selectBg:SetTexture(BG_TEXTURE)
selectBg:SetVertexColor(0.05, 0.05, 0.08, 0.95)

selectFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
})
selectFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

local selectTitle = selectFrame:CreateFontString(nil, "OVERLAY")
selectTitle:SetFont("Fonts\\FRIZQT__.TTF", 16)
selectTitle:SetPoint("TOP", 0, -12)
selectTitle:SetText("|cffFFD700Contenedores Disponibles|r")

local selectCloseBtn = CreateFrame("Button", nil, selectFrame, "UIPanelCloseButton")
selectCloseBtn:SetPoint("TOPRIGHT", -3, -3)
selectCloseBtn:SetScript("OnClick", function() selectFrame:Hide() end)

local caseCards = {}

local function ShowCaseSelection(casesInfo)
    -- (Antes guardabamos casesInfo en un global 'allCasesInfo' que nunca se leia.)

    -- Pre-cachear los items-coste para que FormatCostText pueda mostrar nombre+icono.
    local costEntries = {}
    for _, info in pairs(casesInfo) do
        local cost = NormalizeCaseCost(info)
        if cost.type == "item" and cost.itemId then
            table.insert(costEntries, cost.itemId)
        end
    end
    if #costEntries > 0 then
        PreCacheItems(costEntries, nil)
    end

    for _, card in ipairs(caseCards) do
        card:Hide()
        card:SetParent(nil)
    end
    caseCards = {}

    local sortedIds = {}
    for id in pairs(casesInfo) do
        table.insert(sortedIds, id)
    end
    table.sort(sortedIds)

    local numCases = #sortedIds
    local ICON_SIZE = 64
    local CARD_W = 120
    local CARD_H = 130
    local GAP = 15
    local totalWidth = numCases * CARD_W + (numCases - 1) * GAP

    selectFrame:SetSize(totalWidth + 50, CARD_H + 80)

    for idx, id in ipairs(sortedIds) do
        local info = casesInfo[id]

        local card = CreateFrame("Frame", nil, selectFrame)
        card:SetSize(CARD_W, CARD_H)
        local xOffset = -totalWidth / 2 + (idx - 1) * (CARD_W + GAP) + CARD_W / 2
        card:SetPoint("TOP", selectFrame, "TOP", xOffset, -45)
        card:EnableMouse(true)

        -- Card background
        local bg = card:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(BG_TEXTURE)
        bg:SetVertexColor(0.1, 0.1, 0.12, 0.9)

        -- Card border
        card:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
        })
        card:SetBackdropBorderColor(0.5, 0.45, 0.2, 0.7)

        -- Chest icon
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("TOP", card, "TOP", 0, -10)
        icon:SetTexture(info.icon or "Interface\\Icons\\INV_Box_01")

        -- Case name
        local nameText = card:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        nameText:SetPoint("TOP", icon, "BOTTOM", 0, -5)
        nameText:SetWidth(CARD_W - 8)
        nameText:SetText("|cffFFFFFF" .. info.name .. "|r")
        nameText:SetJustifyH("CENTER")

        -- Price (gold o item-coste)
        local cost = NormalizeCaseCost(info)
        local priceText = card:CreateFontString(nil, "OVERLAY")
        priceText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        priceText:SetPoint("TOP", nameText, "BOTTOM", 0, -3)
        priceText:SetText(FormatCostShort(cost))

        -- Hover highlight
        local highlight = card:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(BG_TEXTURE)
        highlight:SetVertexColor(1, 1, 1, 0.08)

        -- Tooltip on hover (show item list)
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(info.name, 1, 0.82, 0)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Contiene:", 0.7, 0.7, 0.7)
            if info.items then
                for _, item in ipairs(info.items) do
                    local color = RARITY_COLORS[item.rarity] or RARITY_COLORS.white
                    local itemName = GetItemInfo(item.entry)
                    if not itemName then
                        itemName = "Item #" .. item.entry
                    end
                    GameTooltip:AddLine("  " .. itemName, color.r, color.g, color.b)
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Costo: " .. FormatCostText(cost), 1, 1, 1)
            GameTooltip:AddLine("|cff00FF00Click para ver detalles|r")
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Click to open detail view
        local caseId = id
        card:SetScript("OnMouseUp", function()
            selectFrame:Hide()
            ShowCaseDetail(caseId, info)
        end)

        table.insert(caseCards, card)
    end

    selectFrame:Show()
end

-- ============================================================
-- HANDLERS AIO CLIENTE
-- ============================================================
local ClientHandlers = AIO.AddHandlers("StrikeChest", {})

function ClientHandlers.ShowCaseSelect(player, casesInfo)
    overlay:Hide()
    detailPanel:Hide()
    ShowCaseSelection(casesInfo)
end

-- *** CAMBIO: Aceptar winCreatureId como nuevo parametro ***
function ClientHandlers.StartSpin(player, caseId, reelData, winPosition, winEntry, winRarity, winRarityName, winCreatureId)
    currentWinEntry = winEntry
    currentWinRarity = winRarity
    currentWinRarityName = winRarityName
    currentWinCreatureId = winCreatureId or 0

    detailPanel:Hide()
    overlay:Show()
    selectFrame:Hide()
    StartSpinAnimation(reelData, winPosition)
end

function ClientHandlers.ShowCaseDetail(player, caseId, caseInfo)
    currentCaseId = caseId
    currentCaseInfo = caseInfo
    selectFrame:Hide()
    ShowCaseDetail(caseId, caseInfo)
end

function ClientHandlers.Error(player, errorMsg)
    print("|cffFF0000[Cofres]|r " .. errorMsg)
    if overlay:IsShown() then
        resultItemName:SetText("|cffFF0000" .. errorMsg .. "|r")
        resultRarityName:SetText("")
        btnCloseResult:Show()
    end
end

-- ============================================================
-- BUTTON ACTIONS FOR RESULT
-- ============================================================
btnOpenAnother:SetScript("OnClick", function()
    btnOpenAnother:Hide()
    btnCloseResult:Hide()
    modelFrame:Hide()
    dressUpFrame:Hide()
    iconResultFrame:Hide()
    resultItemName:SetText("")
    resultRarityName:SetText("")

    if currentCaseId and currentCaseInfo then
        ShowCaseDetail(currentCaseId, currentCaseInfo)
    else
        overlay:Hide()
        AIO.Handle("StrikeChest", "RequestCaseList")
    end
end)

btnCloseResult:SetScript("OnClick", function()
    overlay:Hide()
    detailPanel:Hide()
    spinContainer:Hide()
    detailContainer:Hide()
    modelFrame:Hide()
    dressUpFrame:Hide()
    iconResultFrame:Hide()
    resultItemName:SetText("")
    resultRarityName:SetText("")
    btnOpenAnother:Hide()
    btnCloseResult:Hide()
end)

-- ============================================================
-- SLASH COMMANDS
-- ============================================================
SLASH_STRIKECHEST1 = "/cofre"
SLASH_STRIKECHEST2 = "/opencase"
SlashCmdList["STRIKECHEST"] = function()
    AIO.Handle("StrikeChest", "RequestCaseList")
end

print("|cff00FF00[Cofres]|r Sistema cargado. Usa |cffFFD700.opencase|r o |cffFFD700/cofre|r")