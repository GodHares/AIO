local AIO = AIO or require("AIO")
if AIO.AddAddon() then return end

local StoreHandlers = AIO.AddHandlers("FelStormStore", {})

local currentCategory = "Destacado"
local currentLayoutType = "simple_grid"
local selectedItem = nil
local featuredEntry = nil
local productEntries = {}
local editorialData = nil

local STORE_CURRENCY_ID = 49426
local currentCurrencyAmount = 0

local PreviewModel = nil
local DressUpModels = {}
local HeroModelPool = {}
local HeroIconPool = {}
local activeHeroModelCount = 0
local activeHeroSingleModel = nil
local previewRotation = 0.2
local previewPosX = 0.0
local previewPosY = 0.0
local previewPosZ = 0.0
local previewScale = 0.80
local previewIsRotating = false
local previewLastX = 0

local CategoryButtons = {}
local GridCards = {}
local RewardCards = {}

local DetailsButton = nil
local BackButton = nil
local GiftButton = nil
local GiftPopup = nil
local GiftNameEditBox = nil
local GiftConfirmButton = nil
local GiftCancelButton = nil
local GiftPopupText = nil

-- POPUPS DE CONFIRMACIÓN
local ConfirmPopup = nil
local ConfirmPopupTitle = nil
local ConfirmPopupText = nil
local ConfirmPopupYesBtn = nil
local ConfirmPopupNoBtn = nil
local ConfirmPopupCallback = nil

local LeftArrowButton = nil
local RightArrowButton = nil
local TabViewport = nil
local TabContent = nil
local tabScrollOffset = 0
local maxTabScroll = 0
local TAB_SCROLL_STEP = 160

local HeroTexture = nil
local GlowFrame = nil
local HeroItemGlow1 = nil
local HeroItemGlow2 = nil
local HeroItemFrame = nil
local HeroItemBorder = nil
local HeroItemIcon = nil
local PurchaseBox = nil

local packageDetailsMode = false
local currentPackageItem = nil
local selectedRewardIndex = 1
local selectedRewardData = nil

local ScrollFrame = nil
local ScrollChild = nil
local currentScrollSnapPoints = {0}

local LeftTitleOriginalPoint = nil
local LeftSubtitleOriginalPoint = nil
local LeftDescriptionOriginalPoint = nil
local LeftDividerOriginalPoint = nil
local ScrollFrameOriginalPoint = nil


-- =============================================================
-- STORE MODEL PRESETS
-- =============================================================
local CREATURE_PRESETS = {
    HERO_POSITIONED = { camera = 0, alpha = 1.0 },
    HERO_DYNAMIC    = { camera = 0, alpha = 1.0 },
    CARD_FEATURED   = { camera = 0, alpha = 1.0 },
    CARD_GRID       = { camera = 0, alpha = 1.0 },
    REWARD          = { camera = 0, alpha = 1.0 },
}

local DRESSUP_PRESETS = {
    HERO_POSITIONED = { camera = 0, alpha = 1.0 },
    HERO_DYNAMIC    = { camera = 0, alpha = 1.0 },
    CARD_FEATURED   = { camera = 0, alpha = 1.0 },
    CARD_GRID       = { camera = 0, alpha = 1.0 },
    REWARD          = { camera = 0, alpha = 1.0 },
}

local function ApplyCreaturePreset(model, presetKey, params, creatureId)
    if not model or not creatureId then return end

    local preset = CREATURE_PRESETS[presetKey] or {}
    local p = params or {}

    if model.ClearModel then
        model:ClearModel()
    end
    if model.SetCreature then
        model:SetCreature(creatureId)
    end
    if model.SetCamera then
        model:SetCamera(preset.camera or 0)
    end
    if model.SetAlpha and preset.alpha then
        model:SetAlpha(preset.alpha)
    end
    if model.SetFacing and p.facing ~= nil then
        model:SetFacing(p.facing)
    end
    if model.SetModelScale and p.scale then
        model:SetModelScale(p.scale)
    end
    if model.SetPosition then
        model:SetPosition(p.x or 0, p.y or 0, p.z or 0)
    end
end

local function ApplyDressUpPreset(model, presetKey, params)
    if not model then return end

    local preset = DRESSUP_PRESETS[presetKey] or {}
    local p = params or {}

    if model.SetCamera then
        model:SetCamera(preset.camera or 0)
    end
    if model.SetAlpha and preset.alpha then
        model:SetAlpha(preset.alpha)
    end
    if model.SetFacing and p.facing ~= nil then
        model:SetFacing(p.facing)
    end
    if model.SetModelScale and p.scale then
        model:SetModelScale(p.scale)
    end
    if model.SetPosition then
        model:SetPosition(p.x or 0, p.y or 0, p.z or 0)
    end
end

local CategoryBackgrounds = {
    "Interface\\shop\\catalogshopbgtheatrical",
    "Interface\\shop\\catalogshoptempbgmapteal",
    "Interface\\shop\\catalogshopbgmap",
    "Interface\\shop\\catalogshoptempbgmapred",
    "Interface\\shop\\catalogshoptempbgmapmagenta",
    "Interface\\shop\\catalogshoptempbgmapblue",
}

local ItemBackgroundAssignments = {}
local CategoryItemCounter = {}

local MainBackgroundTexture = nil

local function UpdateMainBackground(texturePath)
    if MainBackgroundTexture then
        MainBackgroundTexture:SetTexture(texturePath)
        MainBackgroundTexture:SetTexCoord(0.000000000, 0.788000000, 0.000000000, 0.894000000)
        MainBackgroundTexture:Show()
    end
end

local function GetItemBackground(item)
    local numBackgrounds = #CategoryBackgrounds
    if not item or not item.id then
        return CategoryBackgrounds[1]
    end
    local key = tostring(item.id)
    if not ItemBackgroundAssignments[key] then
        local count = (CategoryItemCounter[0] or 0) + 1
        CategoryItemCounter[0] = count
        ItemBackgroundAssignments[key] = ((count - 1) % numBackgrounds) + 1
    end
    return CategoryBackgrounds[ItemBackgroundAssignments[key]]
end

local function ResetCategoryBackgroundSystem(newCategory)
    currentCategory = newCategory
    UpdateMainBackground(CategoryBackgrounds[1])
end

local function Trim(s)
    s = tostring(s or "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function TruncateText(s, maxChars)
    s = tostring(s or "")
    if string.len(s) <= maxChars then return s end
    return string.sub(s, 1, maxChars - 3) .. "..."
end

local function GetItemTexture(itemId, fallbackIcon)
    if not itemId or itemId == 0 then
        if fallbackIcon and fallbackIcon ~= "" then
            return "Interface\\Icons\\" .. fallbackIcon
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local texture = GetItemIcon(itemId)
    if texture then return texture end
    if fallbackIcon and fallbackIcon ~= "" then
        return "Interface\\Icons\\" .. fallbackIcon
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetDisplayTexture(item)
    if item.icon and item.icon ~= "" then
        return "Interface\\Icons\\" .. item.icon
    end
    if item.bannerTexture and item.bannerTexture ~= "" then return item.bannerTexture end
    if item.cardTexture and item.cardTexture ~= "" then return item.cardTexture end
    if item.heroTexture and item.heroTexture ~= "" then return item.heroTexture end
    return GetItemTexture(item.id, item.icon)
end

local function GetHeroTexture(item)
    if item.heroTexture and item.heroTexture ~= "" and item.heroTexture ~= "Interface\\Icons\\" then 
        return item.heroTexture 
    end
    if item.icon and item.icon ~= "" then
        return "Interface\\Icons\\" .. item.icon
    end
    if item.bannerTexture and item.bannerTexture ~= "" then return item.bannerTexture end
    if item.service then
        return "Interface\\Icons\\INV_Misc_Gear_01"
    end
    return GetItemTexture(item.id, item.icon)
end

local function SetupItemTooltip(frame, itemId)
    if not frame or not frame.SetScript then return end
    if frame.EnableMouse then frame:EnableMouse(true) end
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local _, itemLink = GetItemInfo(itemId)
        if itemLink then
            GameTooltip:SetHyperlink(itemLink)
        else
            GameTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function GetRewardTexture(reward)
    if reward.icon and reward.icon ~= "" then return "Interface\\Icons\\" .. reward.icon end
    if reward.heroTexture and reward.heroTexture ~= "" then return reward.heroTexture end
    if reward.bannerTexture and reward.bannerTexture ~= "" then return reward.bannerTexture end
    if reward.type == "item" and reward.id then return GetItemTexture(reward.id, reward.icon) end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetRewardName(reward)
    if reward.name and reward.name ~= "" then return reward.name end
    if reward.type == "item" and reward.id and reward.id > 0 then
        local name = GetItemInfo(reward.id)
        if name then return name end
        return "Objeto #" .. tostring(reward.id)
    end
    if reward.type == "service" then return reward.label or reward.key or "Servicio" end
    return "Recompensa"
end

local function GetRewardDescription(reward)
    if reward.description and reward.description ~= "" then return reward.description end
    if reward.type == "service" then return "Servicio incluido en el paquete." end
    return "Objeto incluido en el paquete."
end

local function NormalizeRewardEntry(reward, packageItem)
    local data = {}
    data.entryType = "reward"
    data.previewType = reward.previewType or "iconHero"
    data.id = reward.id or 0
    data.itemId = reward.id or 0
    data.name = GetRewardName(reward)
    data.description = GetRewardDescription(reward)
    data.icon = reward.icon
    data.heroTexture = reward.heroTexture or reward.bannerTexture or GetRewardTexture(reward)
    data.bannerTexture = reward.bannerTexture
    data.cardTexture = reward.cardTexture
    data.creatureid = reward.creatureid
    data.itemSet = reward.itemSet
    data.armorType = reward.armorType
    data.displayRace = reward.displayRace
    data.displayGender = reward.displayGender
    data.count = reward.count or 1
    data.parentPackageId = packageItem and packageItem.id or 0
    data.rewardType = reward.type
    data.showModel = reward.showModel
    data.isCreature = reward.isCreature or (reward.type == "creature3D")
    
    return data
end

local POSITION_CONFIG = {
    -- ============================================
    -- 1 MODELO
    -- ============================================
    ["1_creature"] = { 
        mounts = {{x=0, y=0, facing=-0.40, scale=2.40, zAdj=-0.30, xAdj=0, heroX=-100, heroY=0}} 
    },
    ["1_char"] = { 
        chars = {{x=0, y=-10, facing=-0.20, scale=2.40, zAdj=-0.40, xAdj=0, heroX=-100, heroY=0}} 
    },
    
    -- ============================================
    -- 2 MODELOS
    -- ============================================
    ["2_creatures"] = {
        mounts = {
            {x=-300, y=10, facing=0.35, scale=2.00, zAdj=-0.20, xAdj=-0.40, heroX=-250, heroY=0},
            {x=300, y=10, facing=-0.35, scale=2.00, zAdj=-0.20, xAdj=0.40, heroX=250, heroY=0}
        }
    },
    ["2_chars"] = {
        chars = {
            {x=-300, y=-10, facing=0.35, scale=1.90, zAdj=-0.40, xAdj=-0.40, heroX=-250, heroY=-10},
            {x=300, y=-10, facing=-0.35, scale=1.90, zAdj=-0.40, xAdj=0.40, heroX=250, heroY=-10}
        }
    },
    ["1_creature_1_char"] = {
        mounts = {{x=200, y=-10, facing=-0.20, scale=1.90, zAdj=-0.30, xAdj=0, heroX=150, heroY=0}},
        chars = {{x=-200, y=0, facing=-0.40, scale=1.80, zAdj=-0.20, xAdj=-0.80, heroX=-250, heroY=0}}
    },
    
    -- ============================================
    -- 3 MODELOS
    -- ============================================
    ["3_creatures"] = {
        mounts = {
            {x=-450, y=10, facing=0.35, scale=1.60, zAdj=-0.10, xAdj=-0.85, heroX=-350, heroY=0},
            {x=0, y=30, facing=0.0, scale=1.60, zAdj=0.20, xAdj=0, heroX=0, heroY=20},
            {x=450, y=10, facing=-0.35, scale=1.60, zAdj=-0.10, xAdj=0.85, heroX=350, heroY=0}
        }
    },
    ["3_chars"] = {
        chars = {
            {x=-400, y=-10, facing=0.35, scale=1.70, zAdj=-0.40, xAdj=-0.65, heroX=-300, heroY=-10},
            {x=0, y=-10, facing=0.0, scale=1.70, zAdj=-0.40, xAdj=0, heroX=0, heroY=-10},
            {x=400, y=-10, facing=-0.35, scale=1.70, zAdj=-0.40, xAdj=0.65, heroX=300, heroY=-10}
        }
    },
    ["2_creatures_1_char"] = {
        mounts = {
            {x=-450, y=0, facing=0.35, scale=1.00, zAdj=-0.20, xAdj=-0.70, heroX=-350, heroY=0},
            {x=450, y=0, facing=-0.35, scale=1.00, zAdj=-0.20, xAdj=0.70, heroX=200, heroY=0}
        },
        chars = {{x=0, y=-15, facing=0.0, scale=1.00, zAdj=-0.40, xAdj=0, heroX=-50, heroY=-15}}
    },
    ["1_creature_2_chars"] = {
        mounts = {{x=0, y=20, facing=0.0, scale=1.80, zAdj=-0.10, xAdj=0, heroX=0, heroY=20}},
        chars = {
            {x=-350, y=-15, facing=0.35, scale=1.90, zAdj=-0.40, xAdj=-0.60, heroX=-280, heroY=-10},
            {x=350, y=-15, facing=-0.35, scale=1.90, zAdj=-0.40, xAdj=0.60, heroX=280, heroY=-10}
        }
    },
    
    -- ============================================
    -- 4 MODELOS
    -- ============================================
    ["4_creatures"] = {
        mounts = {
            {x=-500, y=10, facing=0.40, scale=1.35, zAdj=-0.10, xAdj=-1.15, heroX=-380, heroY=0},
            {x=-200, y=30, facing=0.15, scale=1.35, zAdj=0.20, xAdj=-0.35, heroX=-130, heroY=20},
            {x=200, y=30, facing=-0.15, scale=1.35, zAdj=0.20, xAdj=0.35, heroX=130, heroY=20},
            {x=500, y=10, facing=-0.40, scale=1.35, zAdj=-0.10, xAdj=1.15, heroX=380, heroY=0}
        }
    },
    ["4_chars"] = {
        chars = {
            {x=-450, y=-10, facing=0.40, scale=1.45, zAdj=-0.40, xAdj=-0.90, heroX=-320, heroY=-10},
            {x=-150, y=-10, facing=0.15, scale=1.45, zAdj=-0.40, xAdj=-0.30, heroX=-100, heroY=-10},
            {x=150, y=-10, facing=-0.15, scale=1.45, zAdj=-0.40, xAdj=0.30, heroX=100, heroY=-10},
            {x=450, y=-10, facing=-0.40, scale=1.45, zAdj=-0.40, xAdj=0.90, heroX=320, heroY=-10}
        }
    },
    ["2_creatures_2_chars"] = {
        mounts = {
            {x=-400, y=20, facing=0.35, scale=1.60, zAdj=-0.10, xAdj=-0.85, heroX=-300, heroY=10},
            {x=400, y=20, facing=-0.35, scale=1.60, zAdj=-0.10, xAdj=0.85, heroX=300, heroY=10}
        },
        chars = {
            {x=-200, y=-20, facing=0.15, scale=1.70, zAdj=-0.40, xAdj=-0.30, heroX=-150, heroY=-15},
            {x=200, y=-20, facing=-0.15, scale=1.70, zAdj=-0.40, xAdj=0.30, heroX=150, heroY=-15}
        }
    },
    ["3_creatures_1_char"] = {
        mounts = {
            {x=-500, y=10, facing=0.35, scale=1.60, zAdj=-0.10, xAdj=-0.85, heroX=-350, heroY=0},
            {x=-200, y=30, facing=0.0, scale=1.60, zAdj=0.40, xAdj=0, heroX=0, heroY=20},
            {x=500, y=10, facing=-0.35, scale=1.60, zAdj=-0.10, xAdj=0.85, heroX=150, heroY=0}
        },
        chars = {{x=200, y=-25, facing=0.0, scale=1.80, zAdj=-0.50, xAdj=0, heroX=-180, heroY=-25}}
    },
    ["1_creature_3_chars"] = {
        mounts = {{x=0, y=30, facing=0.0, scale=1.50, zAdj=0.10, xAdj=0, heroX=0, heroY=25}},
        chars = {
            {x=-400, y=-10, facing=0.35, scale=1.70, zAdj=-0.20, xAdj=-0.65, heroX=-280, heroY=-10},
            {x=400, y=-10, facing=-0.35, scale=1.70, zAdj=-0.20, xAdj=0.65, heroX=280, heroY=-10},
            {x=0, y=-35, facing=0.0, scale=1.70, zAdj=-0.50, xAdj=0, heroX=0, heroY=-30}
        }
    },
    
    -- ============================================
    -- CONFIGURACIONES POR DEFECTO (FALLBACK)
    -- ============================================
    ["default_single"] = {
        mounts = {{x=0, y=10, facing=0.20, scale=2.40, zAdj=-0.30, xAdj=0, heroX=0, heroY=0}},
        chars = {{x=0, y=10, facing=0.20, scale=2.40, zAdj=-0.40, xAdj=0, heroX=0, heroY=0}}
    },
    ["default_double"] = {
        mounts = {
            {x=-300, y=20, facing=0.30, scale=1.80, zAdj=-0.20, xAdj=-0.15, heroX=-200, heroY=0},
            {x=300, y=20, facing=-0.30, scale=1.80, zAdj=-0.20, xAdj=0.15, heroX=200, heroY=0}
        },
        chars = {
            {x=-300, y=20, facing=0.30, scale=1.90, zAdj=-0.30, xAdj=-0.05, heroX=-200, heroY=0},
            {x=300, y=20, facing=-0.30, scale=1.90, zAdj=-0.30, xAdj=0.05, heroX=200, heroY=0}
        }
    },
    ["default_triple"] = {
        mounts = {
            {x=-450, y=30, facing=0.30, scale=1.60, zAdj=-0.10, xAdj=0, heroX=-300, heroY=10},
            {x=0, y=30, facing=0.0, scale=1.60, zAdj=-0.10, xAdj=0, heroX=0, heroY=20},
            {x=450, y=30, facing=-0.30, scale=1.60, zAdj=-0.10, xAdj=0, heroX=300, heroY=10}
        },
        chars = {
            {x=-450, y=30, facing=0.30, scale=1.70, zAdj=-0.05, xAdj=-0.15, heroX=-300, heroY=5},
            {x=0, y=30, facing=0.0, scale=1.70, zAdj=-0.05, xAdj=0, heroX=0, heroY=10},
            {x=450, y=30, facing=-0.30, scale=1.70, zAdj=-0.05, xAdj=0.15, heroX=300, heroY=5}
        }
    },
    ["default_quadruple"] = {
        mounts = {
            {x=-500, y=30, facing=0.40, scale=1.35, zAdj=-0.10, xAdj=0, heroX=-350, heroY=10},
            {x=-200, y=30, facing=0.25, scale=1.35, zAdj=-0.10, xAdj=0, heroX=-120, heroY=20},
            {x=200, y=30, facing=-0.25, scale=1.35, zAdj=-0.10, xAdj=0, heroX=120, heroY=20},
            {x=500, y=30, facing=-0.40, scale=1.35, zAdj=-0.10, xAdj=0, heroX=350, heroY=10}
        },
        chars = {
            {x=-500, y=30, facing=0.40, scale=1.45, zAdj=-0.05, xAdj=0, heroX=-350, heroY=5},
            {x=-200, y=30, facing=0.25, scale=1.45, zAdj=-0.05, xAdj=0, heroX=-120, heroY=15},
            {x=200, y=30, facing=-0.25, scale=1.45, zAdj=-0.05, xAdj=0, heroX=120, heroY=15},
            {x=500, y=30, facing=-0.40, scale=1.45, zAdj=-0.05, xAdj=0, heroX=350, heroY=5}
        }
    }
}

local function DetectPositionConfig(creatures, chars, total)
    if total == 1 then
        if creatures == 1 then return "1_creature" end
        if chars == 1 then return "1_char" end
        return "default_single"
    elseif total == 2 then
        if creatures == 2 and chars == 0 then return "2_creatures" end
        if creatures == 0 and chars == 2 then return "2_chars" end
        if creatures == 1 and chars == 1 then return "1_creature_1_char" end
        return "default_double"
    elseif total == 3 then
        if creatures == 3 and chars == 0 then return "3_creatures" end
        if creatures == 0 and chars == 3 then return "3_chars" end
        if creatures == 2 and chars == 1 then return "2_creatures_1_char" end
        if creatures == 1 and chars == 2 then return "1_creature_2_chars" end
        return "default_triple"
    elseif total == 4 then
        if creatures == 4 and chars == 0 then return "4_creatures" end
        if creatures == 0 and chars == 4 then return "4_chars" end
        if creatures == 2 and chars == 2 then return "2_creatures_2_chars" end
        if creatures == 3 and chars == 1 then return "3_creatures_1_char" end
        if creatures == 1 and chars == 3 then return "1_creature_3_chars" end
        return "default_quadruple"
    end
    return "default_single"
end

local function GetCardPositionConfig(creatures, chars, total, isFeatured)
    local key = DetectPositionConfig(creatures, chars, total)
    local cfg = POSITION_CONFIG[key] or POSITION_CONFIG["default_single"]

    local xScale = isFeatured and 0.24 or 0.14
    local yScale = isFeatured and 0.18 or 0.12
    local scaleScaleMount = isFeatured and 0.34 or 0.18
    local scaleScaleChar = isFeatured and 0.24 or 0.16
    local yBias = 0

    local out = {
        mounts = {},
        chars = {},
    }

    if cfg.mounts then
        for i, p in ipairs(cfg.mounts) do
            out.mounts[i] = {
                x = (p.x or 0) * xScale,
                y = ((p.y or 0) * yScale) + yBias,
                facing = p.facing or 0,
                scale = p.scale or 1.0,
                zAdj = p.zAdj or 0,
                xAdj = p.xAdj or 0,
                scaleFactor = scaleScaleMount,
            }
        end
    end

    if cfg.chars then
        for i, p in ipairs(cfg.chars) do
            out.chars[i] = {
                x = (p.x or 0) * xScale,
                y = ((p.y or 0) * yScale) + yBias,
                facing = p.facing or 0,
                scale = p.scale or 1.0,
                zAdj = p.zAdj or 0,
                xAdj = p.xAdj or 0,
                scaleFactor = scaleScaleChar,
            }
        end
    end

    return out
end

local function GetCreatureAdjustment(creatureId)
    return {x=-0.10, y=0.0, z=2.15, facing=0.20, scale=0.23}
end

local CardModelPool = {}
local CardDressUpPool = {}
local CardIconPool = {}

local function GetPooledFrame(pool)
    for _, m in ipairs(pool) do
        if not m.inUse then
            m.inUse = true
            return m
        end
    end
    return nil
end

local function ReleasePooledFrame(model)
    if not model then return end

    model.inUse = false
    model.ownerCard = nil

    if model.tracker then
        model.tracker:SetScript("OnUpdate", nil)
    end

    model:ClearAllPoints()

    if model:GetObjectType() == "DressUpModel" then
        pcall(function()
            if model.Undress then
                model:Undress()
            end
        end)
    end

    if model.ClearModel then
        model:ClearModel()
    end

    if model.SetModel and model:GetObjectType() ~= "DressUpModel" then
        model:SetModel("Interface\\InventoryItems\\EmptySlot.m2")
    end

    model._storedItemSet = nil
    model._storedDisplayRace = nil
    model._storedDisplayGender = nil
    model._storedFacing = nil

    model:Hide()
end

local function IsModelHolderFullyVisibleY(holder, topPadding, bottomPadding)
    if not holder or not holder:IsShown() or not ScrollFrame or not ScrollFrame:IsShown() then
        return false
    end

    topPadding = topPadding or 0
    bottomPadding = bottomPadding or topPadding or 0

    local viewportTop = ScrollFrame:GetTop()
    local viewportBottom = ScrollFrame:GetBottom()

    local top = holder:GetTop()
    local bottom = holder:GetBottom()

    if not viewportTop or not viewportBottom or not top or not bottom then
        return false
    end

    if top > (viewportTop - topPadding) then
        return false
    end

    if bottom < (viewportBottom + bottomPadding) then
        return false
    end

    return true
end

local function ShowItemSetOnModel(model, itemSet, displayRace, displayGender, facing)
    if not model or not itemSet then return end
    model:ClearModel()
    model:Hide()
    pcall(function()
        if displayRace and displayGender then
            if model.SetCustomRace then model:SetCustomRace(displayRace, displayGender) end
        end
        model:SetUnit("player")
        model:SetCamera(0)
        model:SetFacing(facing or 0)
        model:Show()
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.1 then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                pcall(function()
                    model:Undress()
                    model:SetUnit("player")
                    local equipDelay = CreateFrame("Frame")
                    local equipElapsed = 0
                    equipDelay:SetScript("OnUpdate", function(self2, dt2)
                        equipElapsed = equipElapsed + dt2
                        if equipElapsed >= 0.05 then
                            self2:SetScript("OnUpdate", nil)
                            self2:Hide()
                            for _, itemId in ipairs(itemSet) do
                                if type(itemId) == "number" and itemId > 0 then
                                    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemId)
                                    if itemEquipLoc then
                                        if itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_BAG" then
                                            pcall(function() model:TryOn(itemId) end)
                                        end
                                    else
                                        pcall(function() model:TryOn(itemId) end)
                                    end
                                end
                            end
                        end
                    end)
                    equipDelay:Show()
                end)
            end
        end)
        delayFrame:Show()
    end)
end




local function EnsureDressUpSetApplied(model)
    if not model or model:GetObjectType() ~= "DressUpModel" then
        return
    end

    if not model._storedItemSet or #model._storedItemSet == 0 then
        return
    end

    ShowItemSetOnModel(
        model,
        model._storedItemSet,
        model._storedDisplayRace,
        model._storedDisplayGender,
        model._storedFacing or 0
    )
end
local function ApplyCardModelTransform(model, creatureId, isFeatured, scaleMult)
    if not model then return end
    if model.ClearModel then model:ClearModel() end
    if model.SetPosition then model:SetPosition(0,0,0) end
    if model.SetCreature then model:SetCreature(creatureId) end
    if model.SetCamera then model:SetCamera(0) end
    local adj = GetCreatureAdjustment(creatureId)
    local baseScale = adj.scale or 0.45
    local scale = (isFeatured and baseScale * 1.2 or baseScale * 0.9) * (scaleMult or 1.0)
    if model.SetModelScale then model:SetModelScale(scale) end
    if model.SetFacing then model:SetFacing(adj.facing or 0.20) end
    local z = adj.z or 2.10
    if not isFeatured then z = z - 0.1 end
    if model.SetPosition then model:SetPosition(adj.x or 0, adj.y or 0, z) end
end

local function ApplyPreviewTransform(adj)
    previewRotation = adj.facing or 0.20
    previewPosX = adj.x or 0.0
    previewPosY = adj.y or 0.0
    previewPosZ = adj.z or 2.10
    previewScale = adj.scale or 0.80
    if PreviewModel.SetModelScale then PreviewModel:SetModelScale(previewScale) end
    if PreviewModel.SetFacing then PreviewModel:SetFacing(previewRotation) end
    if PreviewModel.SetPosition then PreviewModel:SetPosition(previewPosX, previewPosY, previewPosZ) end
end

local function FilterIconsIf3DPresent(models)
    local has3D = false
    for _, m in ipairs(models) do
        if m.type == "creature" or m.type == "itemSet" then 
            has3D = true 
            break 
        end
    end
    if has3D then
        local filtered = {}
        for _, m in ipairs(models) do
            if m.type ~= "icon" then 
                table.insert(filtered, m) 
            end
        end
        return filtered
    end
    return models
end

local function GroupArmorSetsByType(rewards)
    local grouped = {}
    local seenTypes = {}
    for _, reward in ipairs(rewards or {}) do
        if reward.previewType == "itemSet" and reward.itemSet then
            local armorType = reward.armorType or "unknown"
            if not seenTypes[armorType] then
                seenTypes[armorType] = true
                table.insert(grouped, {
                    type = "itemSet",
                    itemSet = reward.itemSet,
                    armorType = armorType,
                    displayRace = reward.displayRace,
                    displayGender = reward.displayGender,
                    name = reward.name or armorType
                })
            end
        elseif (reward.previewType == "creature3D" or reward.type == "creature3D") and reward.creatureid and reward.creatureid > 0 then
            table.insert(grouped, {
                type = "creature",
                creatureid = reward.creatureid,
                name = reward.name or "Montura"
            })
        elseif reward.type == "item" or reward.previewType == "iconHero" then
            table.insert(grouped, {
                type = "icon",
                iconTexture = GetRewardTexture(reward),
                name = reward.name or "Objeto"
            })
        end
    end
    return grouped
end

local function ReorderForSymmetry(models)
    if not models then return {} end
    local creatures = {}
    local sets = {}
    local icons = {}
    for _, m in ipairs(models) do
        if m.type == "creature" then table.insert(creatures, m)
        elseif m.type == "itemSet" then table.insert(sets, m)
        else table.insert(icons, m) end
    end
    local ordered = {}
    if #models == 4 and #creatures == 2 and #sets == 2 then
        table.insert(ordered, creatures[1])
        table.insert(ordered, sets[1])
        table.insert(ordered, sets[2])
        table.insert(ordered, creatures[2])
        return ordered
    elseif #models == 3 and #sets == 2 and #creatures == 1 then
        table.insert(ordered, sets[1])
        table.insert(ordered, creatures[1])
        table.insert(ordered, sets[2])
        return ordered
    elseif #models == 3 and #creatures == 2 and #sets == 1 then
        table.insert(ordered, creatures[1])
        table.insert(ordered, sets[1])
        table.insert(ordered, creatures[2])
        return ordered
    end
    return models
end

local MainFrame = CreateFrame("Frame", "FelStormStoreFrame", UIParent, "PortraitFrameTemplate_NineSlice")
MainFrame:SetSize(1500, 900)
MainFrame:SetPoint("CENTER", 0, 50)
MainFrame:SetToplevel(true)
MainFrame:EnableMouse(true)
MainFrame:SetMovable(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetClampedToScreen(true)
MainFrame:SetClampRectInsets(0, 0, 0, 0)
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
table.insert(UISpecialFrames, "FelStormStoreFrame")

do
    local MetalBorder = CreateFrame("Frame", nil, MainFrame)
    MetalBorder:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", -15, 30)
    MetalBorder:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", 5, -5)
    MetalBorder:SetFrameLevel(10)

    -- Esquina Superior Izquierda
    local CornerTopLeft = MetalBorder:CreateTexture(nil, "OVERLAY")
    CornerTopLeft:SetSize(75, 75)
    CornerTopLeft:SetPoint("TOPLEFT", MetalBorder, "TOPLEFT", 0, 0)
    CornerTopLeft:SetTexture("Interface\\FrameGeneral\\UIFrameMetal2x")
    CornerTopLeft:SetTexCoord(0.00195312, 0.294922, 0.298828, 0.591797)

    -- Esquina Superior Derecha
    local CornerTopRight = MetalBorder:CreateTexture(nil, "OVERLAY")
    CornerTopRight:SetSize(75, 75)
    CornerTopRight:SetPoint("TOPRIGHT", MetalBorder, "TOPRIGHT", 0, 0)
    CornerTopRight:SetTexture("Interface\\FrameGeneral\\UIFrameMetal2x")
    CornerTopRight:SetTexCoord(0.298828, 0.591797, 0.00195312, 0.294922)

    -- Esquina Inferior Izquierda
    local CornerBottomLeft = MetalBorder:CreateTexture(nil, "OVERLAY")
    CornerBottomLeft:SetSize(32, 32)
    CornerBottomLeft:SetPoint("BOTTOMLEFT", MetalBorder, "BOTTOMLEFT", 0, 0)
    CornerBottomLeft:SetTexture("Interface\\FrameGeneral\\UIFrameMetal2x")
    CornerBottomLeft:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)

    -- Esquina Inferior Derecha
    local CornerBottomRight = MetalBorder:CreateTexture(nil, "OVERLAY")
    CornerBottomRight:SetSize(32, 32)
    CornerBottomRight:SetPoint("BOTTOMRIGHT", MetalBorder, "BOTTOMRIGHT", 0, 0)
    CornerBottomRight:SetTexture("Interface\\FrameGeneral\\UIFrameMetal2x")
    CornerBottomRight:SetTexCoord(0.427734, 0.552734, 0.298828, 0.423828)

    -- Borde Superior
    local BorderTop = MetalBorder:CreateTexture(nil, "OVERLAY")
    BorderTop:SetPoint("TOPLEFT", CornerTopLeft, "TOPRIGHT", 0, 0)
    BorderTop:SetPoint("TOPRIGHT", CornerTopRight, "TOPLEFT", 0, 0)
    BorderTop:SetHeight(75)
    BorderTop:SetTexture("Interface\\FrameGeneral\\UIFrameMetalHorizontal2x")
    BorderTop:SetTexCoord(0, 0.5, 0.00390625, 0.589844)

    -- Borde Izquierdo
    local BorderLeft = MetalBorder:CreateTexture(nil, "OVERLAY")
    BorderLeft:SetPoint("TOPLEFT", CornerTopLeft, "BOTTOMLEFT", 0, 0)
    BorderLeft:SetPoint("BOTTOMLEFT", CornerBottomLeft, "TOPLEFT", 0, 0)
    BorderLeft:SetWidth(75)
    BorderLeft:SetTexture("Interface\\FrameGeneral\\UIFrameMetalVertical2x")
    BorderLeft:SetTexCoord(0.00195312, 0.294922, 0, 1)

    -- Borde Derecho
    local BorderRight = MetalBorder:CreateTexture(nil, "OVERLAY")
    BorderRight:SetPoint("TOPRIGHT", CornerTopRight, "BOTTOMRIGHT", 0, 0)
    BorderRight:SetPoint("BOTTOMRIGHT", CornerBottomRight, "TOPRIGHT", 0, 0)
    BorderRight:SetWidth(75)
    BorderRight:SetTexture("Interface\\FrameGeneral\\UIFrameMetalVertical2x")
    BorderRight:SetTexCoord(0.298828, 0.591797, 0, 1)

    -- Borde Inferior
    local BorderBottom = MetalBorder:CreateTexture(nil, "OVERLAY")
    BorderBottom:SetPoint("BOTTOMLEFT", CornerBottomLeft, "BOTTOMRIGHT", 0, 0)
    BorderBottom:SetPoint("BOTTOMRIGHT", CornerBottomRight, "BOTTOMLEFT", 0, 0)
    BorderBottom:SetHeight(32)
    BorderBottom:SetTexture("Interface\\FrameGeneral\\UIFrameMetalHorizontal2x")
    BorderBottom:SetTexCoord(0, 1, 0.597656, 0.847656)

    -- Botón de Cerrar (X)
    local CloseButton = CreateFrame("Button", nil, MainFrame, "CloseButtonTemplate")
    CloseButton:SetPoint("TOPRIGHT", MetalBorder, "TOPRIGHT", -4, -17)
    CloseButton:SetFrameLevel(20)
    CloseButton:SetScript("OnClick", function(self)
        MainFrame:Hide()
    end)
end

-- Textura de fondo de categoria: cubre el frame principal completo
MainBackgroundTexture = MainFrame:CreateTexture(nil, "BORDER")
MainBackgroundTexture:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 0, -62)
MainBackgroundTexture:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", 0, 5)
MainBackgroundTexture:SetTexCoord(0.000000000, 0.788000000, 0.000000000, 0.894000000)
MainBackgroundTexture:Hide()

-- Sombreado izquierdo: encima del fondo de categoria, mismo ancho que el panel izquierdo
local LeftOverlayTexture = MainFrame:CreateTexture(nil, "ARTWORK")
LeftOverlayTexture:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 0, 0)
LeftOverlayTexture:SetPoint("BOTTOMLEFT", MainFrame, "BOTTOMLEFT", 0, 5)
LeftOverlayTexture:SetWidth(570)
LeftOverlayTexture:SetTexture("Interface\\shop\\catalogshopfgmidnightexpansionepic")
LeftOverlayTexture:SetTexCoord(0.000000000, 0.333000000, 0.000000000, 0.895000000)

local TopHeader = CreateFrame("Frame", nil, MainFrame)
TopHeader:SetPoint("TOPLEFT", 8, -8)
TopHeader:SetPoint("TOPRIGHT", -8, -8)
TopHeader:SetHeight(54)

local categories = {"Destacado","Épicos","Bandas","Mejoras de juego","Monturas","Transfiguraciones","Servicios"}
local TabBar = CreateFrame("Frame", nil, MainFrame)
TabBar:SetPoint("TOPLEFT", TopHeader, "BOTTOMLEFT", -5, 44) ; TabBar:SetPoint("TOPRIGHT", TopHeader, "BOTTOMRIGHT", 5, 44)
TabBar:SetHeight(44)
local TabBarTexture = TabBar:CreateTexture(nil, "BACKGROUND")
TabBarTexture:SetAllPoints()
TabBarTexture:SetTexture("Interface\\shop\\catalogshopheadermenu2x.blp")
TabBarTexture:SetTexCoord(0.646484375, 0.707289063, 0.000000000, 0.196000000)

local StoreIconFrame = CreateFrame("Frame", nil, MainFrame)
StoreIconFrame:SetSize(54, 54)
StoreIconFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", -1, 6)
StoreIconFrame:SetFrameLevel(TabBar:GetFrameLevel() + 10)
local StoreIcon = StoreIconFrame:CreateTexture(nil, "ARTWORK")
StoreIcon:SetAllPoints()
StoreIcon:SetTexture("Interface\\shop\\IconFallen.blp")

local HeaderTitle = StoreIconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeaderTitle:SetPoint("TOP", TopHeader, "TOP", 0, 2)
HeaderTitle:SetText("|cffffd24aTienda|r")

LeftArrowButton = CreateFrame("Button", nil, TabBar)
LeftArrowButton:SetSize(28,28)
LeftArrowButton:SetPoint("LEFT", TabBar, "LEFT", 60, 0)
LeftArrowButton:Hide()
LeftArrowButton.Icon = LeftArrowButton:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
LeftArrowButton.Icon:SetPoint("CENTER",0,-1)
LeftArrowButton.Icon:SetText("|cffffd24a<|r")

local SearchBoxBg = CreateFrame("Frame", nil, TabBar)
SearchBoxBg:SetSize(250,25)
SearchBoxBg:SetPoint("RIGHT", TabBar, "RIGHT", -20, 0)
SearchBoxBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=8, edgeSize=8, insets={left=1,right=1,top=1,bottom=1}})
SearchBoxBg:SetBackdropColor(0.03,0.03,0.03,0.98)

local SearchBox = CreateFrame("EditBox","FelStormStoreSearchBox",SearchBoxBg)
SearchBox:SetPoint("TOPLEFT",5,-1) ; SearchBox:SetPoint("BOTTOMRIGHT",-5,1)
SearchBox:SetAutoFocus(false)
SearchBox:SetFontObject(GameFontHighlightSmall)
SearchBox:SetTextInsets(4,4,0,0)
SearchBox:SetText("")

local SearchLabel = SearchBoxBg:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
SearchLabel:SetPoint("LEFT",8,0) ; SearchLabel:SetText("Buscar")

local CurrencyFrame = CreateFrame("Frame", nil, TabBar)
CurrencyFrame:SetSize(88,20)
CurrencyFrame:SetPoint("RIGHT", SearchBoxBg, "LEFT", -8, 0)
local CurrencyIcon = CurrencyFrame:CreateTexture(nil,"ARTWORK")
CurrencyIcon:SetSize(16,16) ; CurrencyIcon:SetPoint("LEFT",0,0)
CurrencyIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")

local CurrencyText = CurrencyFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
CurrencyText:SetPoint("LEFT", CurrencyIcon, "RIGHT", 5, 0)
CurrencyText:SetText("0")
SetupItemTooltip(CurrencyFrame, STORE_CURRENCY_ID)

RightArrowButton = CreateFrame("Button", nil, TabBar)
RightArrowButton:SetSize(28,28)
RightArrowButton:SetPoint("RIGHT", CurrencyFrame, "LEFT", -6, 0)
RightArrowButton:Hide()
RightArrowButton.Icon = RightArrowButton:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
RightArrowButton.Icon:SetPoint("CENTER",0,-1)
RightArrowButton.Icon:SetText("|cffffd24a>|r")

TabViewport = CreateFrame("Frame", nil, TabBar)
TabViewport:SetPoint("TOPLEFT", LeftArrowButton, "TOPRIGHT", 2, 0)
TabViewport:SetPoint("BOTTOMRIGHT", RightArrowButton, "BOTTOMLEFT", -2, 0)

TabContent = CreateFrame("Frame", nil, TabViewport)
TabContent:SetPoint("TOPLEFT",0,0) ; TabContent:SetHeight(30)

local function UpdateCategoryButtonStates()
    for _, btn in ipairs(CategoryButtons) do
        if btn.categoryName == currentCategory then
            btn.SelectedTex:Show()
            btn.HighlightTex:Hide()
        else
            btn.SelectedTex:Hide()
        end
    end
end

local function UpdateTabScrollButtons()
    if maxTabScroll <= 0 then LeftArrowButton:Hide() ; RightArrowButton:Hide() ; return end
    LeftArrowButton:Show() ; RightArrowButton:Show()
    LeftArrowButton.Icon:SetText(tabScrollOffset<=0 and "|cff7a6a3a<|r" or "|cffffd24a<|r")
    RightArrowButton.Icon:SetText(tabScrollOffset>=maxTabScroll and "|cff7a6a3a>|r" or "|cffffd24a>|r")
end

local function UpdateTabLayout()
    local totalWidth = 0
    for i=1,#CategoryButtons do totalWidth=totalWidth+CategoryButtons[i]:GetWidth() end
    TabContent:SetWidth(totalWidth)
    local visibleWidth = TabViewport:GetWidth() or 0
    maxTabScroll = math.max(0, totalWidth-visibleWidth)
    if tabScrollOffset > maxTabScroll then tabScrollOffset=maxTabScroll end
    if tabScrollOffset < 0 then tabScrollOffset=0 end
    TabContent:ClearAllPoints()
    TabContent:SetPoint("TOPLEFT", TabViewport, "TOPLEFT", -tabScrollOffset, 0)
    UpdateTabScrollButtons()
end

local tabWidths = {108,90,90,136,100,144,100}
local tabX = 0

for i, cat in ipairs(categories) do
    local btn = CreateFrame("Button", nil, TabContent)
    btn:SetHeight(40) ; btn:SetWidth(tabWidths[i] or 120)
    btn:SetPoint("LEFT", TabContent, "LEFT", tabX, 0)
    btn.categoryName = cat
    btn:SetBackdrop(nil)
    btn:SetBackdropColor(0,0,0,0)

    btn.Text = btn:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    btn.Text:SetPoint("CENTER",0,0) ; btn.Text:SetText(string.upper(cat))

    btn.HighlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.HighlightTex:SetAllPoints()
    
    if i == 1 then
        -- Primer botón (izquierda)
        btn.HighlightTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.HighlightTex:SetTexCoord(0.000000000, 0.416039063, 0.203125000, 0.399171875)
    elseif i == #categories then
        -- Último botón (derecha)
        btn.HighlightTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.HighlightTex:SetTexCoord(0.000000000, 0.416039063, 0.406296875, 0.599609375)
    else
        -- Botones del medio
        btn.HighlightTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.HighlightTex:SetTexCoord(0.646484375, 0.707609375, 0.000000000, 0.195312500)
    end
    btn.HighlightTex:SetBlendMode("ADD")
    btn.HighlightTex:Hide()
    
    btn.SelectedTex = btn:CreateTexture(nil, "OVERLAY")
    btn.SelectedTex:SetAllPoints()
    
    if i == 1 then
        -- Primer botón (izquierda)
        btn.SelectedTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.SelectedTex:SetTexCoord(00.000000000, 0.416039063, 0.203125000, 0.399171875)
    elseif i == #categories then
        -- Último botón (derecha)
        btn.SelectedTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.SelectedTex:SetTexCoord(0.000000000, 0.416039063, 0.406296875, 0.599609375)
    else
        -- Botones del medio
        btn.SelectedTex:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.SelectedTex:SetTexCoord(0.646484375, 0.707609375, 0.000000000, 0.195312500)
    end
	btn.SelectedTex:SetBlendMode("ADD")
    btn.SelectedTex:Hide()

    if i < #categories then
        btn.Divider = btn:CreateTexture(nil,"ARTWORK")
        btn.Divider:SetWidth(1)
        btn.Divider:SetPoint("TOPRIGHT",0,4)
        btn.Divider:SetPoint("BOTTOMRIGHT",0,-4)
        btn.Divider:SetTexture("Interface\\shop\\catalogshopheadermenu2x")
        btn.Divider:SetTexCoord(0.962890625, 0.968750000, 0.031250000, 0.154296875)
    end

    btn:SetScript("OnClick", function(self)
    selectedItem=nil
    packageDetailsMode=false ; currentPackageItem=nil
    selectedRewardIndex=1 ; selectedRewardData=nil
    
    ResetCategoryBackgroundSystem(self.categoryName)
    currentCategory = self.categoryName
    
    UpdateCategoryButtonStates()
    AIO.Handle("FelStormStore","RequestCategory",self.categoryName)
end)
    
    btn:SetScript("OnEnter", function(self)
        if self.categoryName ~= currentCategory then
            self.HighlightTex:Show()
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.HighlightTex:Hide()
        UpdateCategoryButtonStates()
    end)
    
    table.insert(CategoryButtons, btn)
    tabX = tabX + btn:GetWidth()
end

local ContentFrame = CreateFrame("Frame", nil, MainFrame)
ContentFrame:SetPoint("TOPLEFT", TabBar, "BOTTOMLEFT", 0, -8)
ContentFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -8, 8)

local LeftPanel = CreateFrame("Frame", nil, ContentFrame)
LeftPanel:SetPoint("TOPLEFT",0,0) ; LeftPanel:SetPoint("BOTTOMLEFT",0,0)
LeftPanel:SetWidth(570)

local LeftPanelDivider = LeftPanel:CreateTexture(nil,"ARTWORK")
LeftPanelDivider:SetHeight(1)
LeftPanelDivider:SetPoint("TOPLEFT",18,-42) ; LeftPanelDivider:SetPoint("TOPRIGHT",-18,-42)
LeftPanelDivider:SetTexture("Interface\\Buttons\\WHITE8x8") ; LeftPanelDivider:SetVertexColor(1,1,1,0.18)

BackButton = CreateFrame("Button", nil, LeftPanel, "UIPanelButtonTemplate")
BackButton:SetSize(110,26) ; BackButton:SetPoint("TOPLEFT",16,-10)
BackButton:SetText("Atrás") ; BackButton:Hide()

local LeftTitle = LeftPanel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
LeftTitle:SetPoint("TOPLEFT",18,-10)
LeftTitle:SetText("DESTACADO")
LeftTitle:SetFont("Fonts\\FRIZQT__.TTF",26,"OUTLINE")

local LeftSubtitle = LeftPanel:CreateFontString(nil,"OVERLAY","GameFontHighlight")
LeftSubtitle:SetPoint("TOPLEFT",18,-48) ; LeftSubtitle:SetText("")

local LeftDescription = LeftPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
LeftDescription:SetPoint("TOPLEFT",18,-66) ; LeftDescription:SetWidth(520)
LeftDescription:SetJustifyH("LEFT") ; LeftDescription:SetText("")

ScrollFrame = CreateFrame("ScrollFrame","FelStormStoreScrollFrame",LeftPanel,"GlueDark_FauxScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT",16,-60)
ScrollFrame:SetPoint("BOTTOMRIGHT",-30,18)

ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetWidth(520) ; ScrollChild:SetHeight(1200)
ScrollFrame:SetScrollChild(ScrollChild)
local function GetCatalogScrollValue()
    local scrollBar = _G["FelStormStoreScrollFrameScrollBar"]
    if scrollBar then
        return scrollBar:GetValue() or 0
    end
    return 0
end

local function SetScrollSnapPoints(points)
    currentScrollSnapPoints = points or {0}
    if #currentScrollSnapPoints == 0 then
        currentScrollSnapPoints = {0}
    end
    table.sort(currentScrollSnapPoints, function(a, b) return a < b end)
end

local function GetNearestScrollSnapIndex(value)
    local bestIndex = 1
    local bestDiff = math.abs((currentScrollSnapPoints[1] or 0) - value)

    for i = 2, #currentScrollSnapPoints do
        local diff = math.abs(currentScrollSnapPoints[i] - value)
        if diff < bestDiff then
            bestDiff = diff
            bestIndex = i
        end
    end

    return bestIndex
end

ScrollFrame:EnableMouseWheel(true)
ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local scrollBar = _G[self:GetName() .. "ScrollBar"]
    if not scrollBar then return end

    local current = scrollBar:GetValue() or 0
    local currentIndex = GetNearestScrollSnapIndex(current)
    local targetIndex = currentIndex

    if delta < 0 then
        targetIndex = math.min(#currentScrollSnapPoints, currentIndex + 1)
    elseif delta > 0 then
        targetIndex = math.max(1, currentIndex - 1)
    end

    local target = currentScrollSnapPoints[targetIndex] or 0
    local maxScroll = self:GetVerticalScrollRange() or 0

    if target < 0 then target = 0 end
    if target > maxScroll then target = maxScroll end

    scrollBar:SetValue(target)
end)

local scrollBar = _G["FelStormStoreScrollFrameScrollBar"]
if scrollBar then
    local isSnapping = false
    scrollBar:HookScript("OnValueChanged", function(self, value)
        if isSnapping then return end
        if not currentScrollSnapPoints or #currentScrollSnapPoints == 0 then return end

        local idx = GetNearestScrollSnapIndex(value or 0)
        local target = currentScrollSnapPoints[idx] or 0

        if math.abs((value or 0) - target) > 1 then
            isSnapping = true
            self:SetValue(target)
            isSnapping = false
        end
    end)
end

local RightPanel = CreateFrame("Frame", nil, ContentFrame)
RightPanel:SetPoint("TOPLEFT", LeftPanel, "TOPRIGHT", 12, 0)
RightPanel:SetPoint("BOTTOMRIGHT", ContentFrame, "BOTTOMRIGHT", 0, 0)
RightPanel:SetFrameStrata("MEDIUM") ; RightPanel:SetFrameLevel(10)

local HeroArea = CreateFrame("Frame", nil, RightPanel)
HeroArea:SetPoint("TOPLEFT",0,0) ; HeroArea:SetPoint("BOTTOMRIGHT",0,0)
HeroArea:SetFrameStrata("MEDIUM") ; HeroArea:SetFrameLevel(RightPanel:GetFrameLevel()+1)

local PreviewViewport = CreateFrame("Frame", nil, RightPanel)
PreviewViewport:ClearAllPoints()
PreviewViewport:SetPoint("TOPLEFT", RightPanel, "TOPLEFT", 280, -14)
PreviewViewport:SetPoint("BOTTOMRIGHT", RightPanel, "BOTTOMRIGHT", -90, 18)
PreviewViewport:SetFrameStrata("MEDIUM")
PreviewViewport:SetFrameLevel(HeroArea:GetFrameLevel() + 1)
if PreviewViewport.SetClipsChildren then
    PreviewViewport:SetClipsChildren(true)
end

local function RotateUV(tex, angle, l, t, r, b)
    local cx = (l + r) * 0.5
    local cy = (t + b) * 0.5
    local hw = (r - l) * 0.5 * 0.840
    local hh = (b - t) * 0.5 * 0.840
    local c, s = math.cos(angle), math.sin(angle)
    tex:SetTexCoord(
        cx - hw*c + hh*s,  cy - hw*s - hh*c,
        cx - hw*c - hh*s,  cy - hw*s + hh*c,
        cx + hw*c + hh*s,  cy + hw*s - hh*c,
        cx + hw*c - hh*s,  cy + hw*s + hh*c
    )
end

local function CreateGlowForFrame(anchorFrame, size)
    local parentFrame = anchorFrame and anchorFrame:GetParent() or HeroArea
    local f = CreateFrame("Frame", nil, parentFrame)
    f:SetSize(size, size)
    f:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(HeroArea:GetFrameLevel() + 2)
    
    f.t1 = f:CreateTexture(nil, "BACKGROUND")
    f.t1:SetAllPoints()
    f.t1:SetTexture("Interface\\shop\\catalogshopfxtokenrays")
    f.t1:SetBlendMode("ADD")
    f.t1:SetAlpha(0.35)

    f.t2 = f:CreateTexture(nil, "BACKGROUND")
    f.t2:SetAllPoints()
    f.t2:SetTexture("Interface\\shop\\catalogshopfxtokenrays")
    f.t2:SetBlendMode("ADD")
    f.t2:SetAlpha(0.35)
    
    local G1L, G1T, G1R, G1B = 0.473632813, 0.000000000, 0.973632813, 0.500000000
    local G2L, G2T, G2R, G2B = 0.000000000, 0.476562500, 0.500000000, 0.976562500

    f:SetScript("OnUpdate", function(self)
        local a = GetTime() * 0.25
        RotateUV(self.t1,  a, G1L, G1T, G1R, G1B)
        RotateUV(self.t2, -a, G2L, G2T, G2R, G2B)
    end)
    
    local origShow = anchorFrame.Show
    anchorFrame.Show = function(self)
        origShow(self)
        f:Show()
    end
    local origHide = anchorFrame.Hide
    anchorFrame.Hide = function(self)
        origHide(self)
        f:Hide()
    end
    f:Hide()
    return f
end

HeroTexture = HeroArea:CreateTexture(nil, "BACKGROUND")
HeroTexture:SetAllPoints()
HeroTexture:Hide()

HeroItemFrame = CreateFrame("Frame", nil, HeroArea)
HeroItemFrame:SetSize(120,120)
HeroItemFrame:SetPoint("CENTER", HeroArea, "CENTER", 0, 60)
HeroItemFrame:SetFrameStrata("MEDIUM")
HeroItemFrame:SetFrameLevel(HeroArea:GetFrameLevel()+5)
HeroItemFrame:Hide()
CreateGlowForFrame(HeroItemFrame, 250)

HeroItemBorder = HeroItemFrame:CreateTexture(nil,"ARTWORK")
HeroItemBorder:SetAllPoints()
HeroItemBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")

HeroItemIcon = HeroItemFrame:CreateTexture(nil,"ARTWORK")
HeroItemIcon:SetPoint("TOPLEFT",18,-18) ; HeroItemIcon:SetPoint("BOTTOMRIGHT",-18,18)
HeroItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
HeroItemIcon:SetTexCoord(0, 1, 0, 1)

PreviewModel = CreateFrame("PlayerModel", nil, PreviewViewport)
PreviewModel:SetAllPoints(PreviewViewport)
PreviewModel:SetFrameStrata("MEDIUM")
PreviewModel:SetFrameLevel(PreviewViewport:GetFrameLevel()+4)
PreviewModel:SetCamera(0) ; PreviewModel:Hide()

for i=1,4 do
    local m = CreateFrame("DressUpModel", nil, PreviewViewport)
    m:SetFrameStrata("HIGH") 
    m:SetFrameLevel(PreviewViewport:GetFrameLevel()+10)
    m:SetCamera(0)
    m:Hide()
    m.inUse = false
    if m.SetKeepModelOnHide then m:SetKeepModelOnHide(true) end
    table.insert(DressUpModels, m)
end

for _i=1,4 do
    local _m = CreateFrame("PlayerModel", nil, PreviewViewport)
    _m:SetFrameStrata("MEDIUM")
    _m:SetFrameLevel(PreviewViewport:GetFrameLevel()+6)
    _m:SetCamera(0)
    _m:Hide()
    _m.inUse = false
    table.insert(HeroModelPool, _m)
end

for i=1,4 do
    local m = CreateFrame("Frame", nil, PreviewViewport)
    m:SetSize(60, 60)
    m:SetFrameStrata("MEDIUM")
    m:SetFrameLevel(PreviewViewport:GetFrameLevel()+6)
    m:Hide()
    m.inUse = false
    m.Icon = m:CreateTexture(nil, "ARTWORK")
    m.Icon:SetAllPoints()
    m.Icon:SetTexCoord(0, 1, 0, 1)
    m.Border = m:CreateTexture(nil, "OVERLAY")
    m.Border:SetSize(80, 80)
    m.Border:SetPoint("CENTER")
    m.Border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    CreateGlowForFrame(m, 180)
    table.insert(HeroIconPool, m)
end

PurchaseBox = CreateFrame("Frame", nil, RightPanel)
PurchaseBox:SetSize(360,190)
PurchaseBox:SetPoint("BOTTOMRIGHT",-18,18)
PurchaseBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Tooltips\\border-tooltip-Noa",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=12,bottom=12}})
PurchaseBox:SetBackdropColor(0.02,0.02,0.02,0.94)
PurchaseBox:SetFrameStrata("HIGH")
PurchaseBox:SetFrameLevel(RightPanel:GetFrameLevel()+50)

local DetailTitle = PurchaseBox:CreateFontString(nil,"OVERLAY","GameFontNormal")
DetailTitle:SetPoint("TOP",0,-16) ; DetailTitle:SetWidth(300)
DetailTitle:SetJustifyH("CENTER") ; DetailTitle:SetText("Selecciona un objeto")

local DetailSub = PurchaseBox:CreateFontString(nil,"OVERLAY","GameFontHighlight")
DetailSub:SetPoint("TOP",DetailTitle,"BOTTOM",0,-6) ; DetailSub:SetText("")

local DetailDesc = PurchaseBox:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
DetailDesc:SetPoint("TOPLEFT",20,-72) ; DetailDesc:SetPoint("TOPRIGHT",-20,-72)
DetailDesc:SetJustifyH("CENTER") ; DetailDesc:SetText("")

local BuyButton = CreateFrame("Button", nil, PurchaseBox, "UIPanelButtonTemplate")
BuyButton:SetSize(142,30) ; BuyButton:SetPoint("BOTTOMLEFT",18,22)
BuyButton:SetText("Comprar") ; BuyButton:Disable()

DetailsButton = CreateFrame("Button", nil, PurchaseBox, "UIPanelButtonTemplate")
DetailsButton:SetSize(122,30) ; DetailsButton:SetPoint("BOTTOMRIGHT",-18,22)
DetailsButton:SetText("Detalles") ; DetailsButton:Hide()

-- BOTÓN REGALAR
GiftButton = CreateFrame("Button", nil, PurchaseBox)
GiftButton:SetSize(122, 122)
GiftButton:SetPoint("TOPLEFT", PurchaseBox, "TOPLEFT", -25, 25)
GiftButton:Hide()

-- Textura normal
GiftButton.NormalTexture = GiftButton:CreateTexture(nil, "ARTWORK")
GiftButton.NormalTexture:SetAllPoints()
GiftButton.NormalTexture:SetTexture("Interface\\shop\\Store_gift_fallen")
-- Textura hover
GiftButton:SetHighlightTexture("Interface\\shop\\Store_gift_fallen")

local PriceFrame = CreateFrame("Frame", nil, PurchaseBox)
PriceFrame:SetSize(200,50) ; PriceFrame:SetPoint("BOTTOM",0,48)

local OriginalPriceText = PriceFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
OriginalPriceText:SetPoint("BOTTOM", PriceFrame, "TOP", 0, -5)
OriginalPriceText:SetText("")
OriginalPriceText:Hide()

local PriceIcon = PriceFrame:CreateTexture(nil,"ARTWORK")
PriceIcon:SetSize(20,20) ; PriceIcon:SetPoint("RIGHT", PriceFrame, "CENTER", -5, 0)
PriceIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")

local PriceText = PriceFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
PriceText:SetPoint("LEFT", PriceIcon, "RIGHT", 5, 0) ; PriceText:SetText("0")

SetupItemTooltip(PriceFrame, STORE_CURRENCY_ID)

-- POPUP MODAL PARA REGALOS
GiftPopup = CreateFrame("Frame", nil, MainFrame)
GiftPopup:SetSize(460, 230)
GiftPopup:SetPoint("CENTER", MainFrame, "CENTER", 0, 0)
GiftPopup:SetFrameStrata("DIALOG")
GiftPopup:SetFrameLevel(300)
GiftPopup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\border-tooltip-Noa",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left=10,right=10,top=12,bottom=12}
})
GiftPopup:SetBackdropColor(0.02,0.02,0.02,0.98)
GiftPopup:Hide()

local GiftPopupTitle = GiftPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
GiftPopupTitle:SetPoint("TOP", 0, -18)
GiftPopupTitle:SetText("Regalar objeto")

GiftPopupText = GiftPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
GiftPopupText:SetPoint("TOPLEFT", 24, -52)
GiftPopupText:SetPoint("TOPRIGHT", -24, -52)
GiftPopupText:SetJustifyH("CENTER")
GiftPopupText:SetJustifyV("TOP")
GiftPopupText:SetSpacing(4)
GiftPopupText:SetText("Escribe el nombre del personaje que recibirá este regalo.")

local GiftNameBg = CreateFrame("Frame", nil, GiftPopup)
GiftNameBg:SetSize(300, 30)
GiftNameBg:SetPoint("TOP", GiftPopupText, "BOTTOM", 0, -18)
GiftNameBg:SetFrameStrata("DIALOG")
GiftNameBg:SetFrameLevel(GiftPopup:GetFrameLevel() + 10)
GiftNameBg:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,
    tileSize=8,
    edgeSize=8,
    insets={left=1,right=1,top=1,bottom=1}
})
GiftNameBg:SetBackdropColor(0.05,0.05,0.05,1)
GiftNameBg:SetBackdropBorderColor(1, 0.82, 0, 0.9)

GiftNameEditBox = CreateFrame("EditBox", nil, GiftNameBg)
GiftNameEditBox:SetPoint("TOPLEFT", 6, -2)
GiftNameEditBox:SetPoint("BOTTOMRIGHT", -6, 2)
GiftNameEditBox:SetFrameStrata("DIALOG")
GiftNameEditBox:SetFrameLevel(GiftNameBg:GetFrameLevel() + 5)
GiftNameEditBox:SetAutoFocus(false)
GiftNameEditBox:SetFontObject(GameFontHighlight)
GiftNameEditBox:SetTextInsets(4,4,0,0)
GiftNameEditBox:SetMaxLetters(12)
GiftNameEditBox:SetText("")
GiftNameEditBox:SetTextColor(1, 1, 1, 1)
GiftNameEditBox:EnableMouse(true)

GiftConfirmButton = CreateFrame("Button", nil, GiftPopup, "UIPanelButtonTemplate")
GiftConfirmButton:SetSize(130, 28)
GiftConfirmButton:SetPoint("BOTTOMLEFT", 55, 22)
GiftConfirmButton:SetText("Enviar regalo")

GiftCancelButton = CreateFrame("Button", nil, GiftPopup, "UIPanelButtonTemplate")
GiftCancelButton:SetSize(130, 28)
GiftCancelButton:SetPoint("BOTTOMRIGHT", -55, 22)
GiftCancelButton:SetText("Cancelar")

local function CreateDiscountBadge(parent, size)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetSize(size or 50, size or 50)
    badge:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -5)
    badge:SetFrameLevel(parent:GetFrameLevel() + 20)
    badge:Hide()
    
    badge.Bg = badge:CreateTexture(nil, "BACKGROUND")
    badge.Bg:SetSize(60, 40)
    badge.Bg:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badge.Bg:SetTexture("Interface\\shop\\catalogshop")
    badge.Bg:SetTexCoord(0.048339844, 0.082070313, 0.347656250, 0.393554688)

    badge.Text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.Text:SetPoint("CENTER", 8, 3)
    badge.Text:SetTextColor(1, 1, 1, 1)
    badge.Text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    
    return badge
end

local function CreateCard(isFeatured)
    local card = CreateFrame("Button", nil, ScrollChild)
    
    if isFeatured then
        card:SetSize(490, 300)
    else
        card:SetSize(154, 230)
    end
    
    card.isFeatured = isFeatured
    card.BgTex = card:CreateTexture(nil,"BACKGROUND")
    card.BgTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.BgTex:SetTexture("Interface\\shop\\catalogshop")
    if isFeatured then
        card.BgTex:SetSize(480, 290)
        card.BgTex:SetTexCoord(0.095703125, 0.355703125, 0.075703125, 0.368703125)
    else
        card.BgTex:SetSize(144, 220)
        card.BgTex:SetTexCoord(0.000000000, 0.083742188, 0.572265625, 0.812187500)
    end
    card.BorderTex = card:CreateTexture(nil,"ARTWORK")
    card.BorderTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.BorderTex:SetTexture("Interface\\shop\\catalogshop")
    if isFeatured then
        card.BorderTex:SetSize(490, 300)
        card.BorderTex:SetTexCoord(0.360351563, 0.625000000, 0.466796875, 0.772000000)
    else
        card.BorderTex:SetSize(154, 230)
        card.BorderTex:SetTexCoord(0.906250000, 0.995582031, 0.468750000, 0.716796875)
    end
    card.HighlightTex = card:CreateTexture(nil,"HIGHLIGHT")
    card.HighlightTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.HighlightTex:SetTexture("Interface\\shop\\catalogshop")
    if isFeatured then
        card.HighlightTex:SetSize(490, 300)
        card.HighlightTex:SetTexCoord(0.360839844, 0.625000000, 0.151367188, 0.456054688)
    else
        card.HighlightTex:SetSize(154, 230)
        card.HighlightTex:SetTexCoord(0.003417969, 0.092285156, 0.082031250, 0.330078125)
    end
    card.SelectedTex = card:CreateTexture(nil,"OVERLAY")
    card.SelectedTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.SelectedTex:SetTexture("Interface\\shop\\catalogshop")
    card.SelectedTex:SetAlpha(0)
    if isFeatured then
        card.SelectedTex:SetSize(490, 300)
        card.SelectedTex:SetTexCoord(0.634765625, 0.898437500, 0.153320313, 0.458007813)
    else
        card.SelectedTex:SetSize(154, 230)
        card.SelectedTex:SetTexCoord(0.906250000, 0.995117188, 0.154296875, 0.402343750)
    end
    card.ModelHolder = CreateFrame("Frame", nil, card)
    card.ModelHolder:SetFrameLevel(card:GetFrameLevel()+2)
    if isFeatured then
        card.ModelHolder:SetPoint("TOPLEFT", 8, -8)
        card.ModelHolder:SetPoint("TOPRIGHT", -8, -8)
        card.ModelHolder:SetHeight(180)
    else
        card.ModelHolder:SetSize(138, 110)
        card.ModelHolder:SetPoint("CENTER", card, "CENTER", 0, 25)
    end
    card.poolModels = {}
	
    card.IconBorder = card.ModelHolder:CreateTexture(nil,"ARTWORK")
    card.IconBorder:SetSize(isFeatured and 120 or 90, isFeatured and 120 or 90)
    card.IconBorder:SetPoint("CENTER",card.ModelHolder,"CENTER",0,0)
    card.IconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    card.Art = card.ModelHolder:CreateTexture(nil,"ARTWORK")
    card.Art:SetSize(isFeatured and 100 or 70, isFeatured and 100 or 70)
    card.Art:SetPoint("CENTER",card.ModelHolder,"CENTER",0,0)
    card.Art:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    card.Art:SetTexCoord(0, 1, 0, 1)
	
    card.Divider = card:CreateTexture(nil, "ARTWORK")
    card.Divider:SetTexture("Interface\\shop\\catalogshop")
    if isFeatured then
        card.Divider:SetSize(490, 50)
        card.Divider:SetPoint("BOTTOM", card, "BOTTOM", 0, 70)
        card.Divider:SetTexCoord(0.714843750, 0.962402344, 0.072265625, 0.138609375)
    else
        card.Divider:SetSize(140, 50)
        card.Divider:SetPoint("CENTER", card.ModelHolder, "CENTER", 0, -105)
        card.Divider:SetTexCoord(0.714843750, 0.962402344, 0.072265625, 0.138609375)
    end
    card.Name = card:CreateFontString(nil,"OVERLAY", isFeatured and "GameFontNormalLarge" or "GameFontHighlightSmall")
    if isFeatured then
        card.Name:SetPoint("TOPLEFT",  card, "BOTTOMLEFT",  8, 85)
        card.Name:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", -8, 85)
    else
        card.Name:SetPoint("TOPLEFT",  card.Divider, "BOTTOMLEFT",  0, 40)
        card.Name:SetPoint("TOPRIGHT", card.Divider, "BOTTOMRIGHT", 0, 40)
    end
    card.Name:SetJustifyH("CENTER") ; card.Name:SetJustifyV("TOP")
    card.Name:SetText("")
    
    card.OriginalPrice = card:CreateFontString(nil,"OVERLAY", isFeatured and "GameFontDisable" or "GameFontDisableSmall")
    card.OriginalPrice:SetPoint("TOP", card.Name, "BOTTOM", 0, -2)
    card.OriginalPrice:SetText("")
    card.OriginalPrice:Hide()
    
    card.BottomRow = CreateFrame("Frame", nil, card)
    card.BottomRow:SetHeight(24)
    card.BottomRow:SetPoint("TOP", card.OriginalPrice, "BOTTOM", 0, -2)
    if isFeatured then
        card.BottomRow:SetPoint("LEFT",  card, "LEFT",  8, 0)
        card.BottomRow:SetPoint("RIGHT", card, "RIGHT", -8, 0)
        card.BottomRow:SetPoint("TOP", card.OriginalPrice, "BOTTOM", 0, -4)
    else
        card.BottomRow:SetPoint("LEFT",  card.Divider, "LEFT",  0, 0)
        card.BottomRow:SetPoint("RIGHT", card.Divider, "RIGHT", 0, 0)
    end
    
    card.CurrencyIcon = card.BottomRow:CreateTexture(nil,"ARTWORK")
    card.CurrencyIcon:SetSize(isFeatured and 20 or 16, isFeatured and 20 or 16)
    card.CurrencyIcon:SetPoint("CENTER", card.BottomRow, "CENTER", -15, 0)
    card.CurrencyIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    card.CurrencyIcon:SetTexCoord(0.07,0.93,0.07,0.93)
    
    card.Price = card.BottomRow:CreateFontString(nil,"OVERLAY", isFeatured and "GameFontHighlightLarge" or "GameFontHighlight")
    card.Price:SetPoint("LEFT", card.CurrencyIcon, "RIGHT", 5, 0)
    card.Price:SetTextColor(0.2, 1, 0.2)
    card.Price:SetText("0")
    
    card.DiscountBadge = CreateDiscountBadge(card, isFeatured and 55 or 45)
    
    card:Hide()
    return card
end

local FeaturedCards = {}
local GridCards = {}
for i=1,6  do FeaturedCards[i] = CreateCard(true)  end
for i=1,24 do GridCards[i]      = CreateCard(false) end

for i=1,30 do
    local m = CreateFrame("PlayerModel", nil, MainFrame)
    m:SetSize(140, 140)
    m:SetFrameStrata("HIGH")
    m:SetFrameLevel(50)
    m:SetCamera(0)
    m:Hide()
    m.inUse = false
    m.ownerCard = nil
    m.tracker = CreateFrame("Frame", nil, MainFrame)
    m.tracker:SetScript("OnUpdate", nil)
    table.insert(CardModelPool, m)
end

for i=1,20 do
    local m = CreateFrame("DressUpModel", nil, MainFrame)
    m:SetSize(140, 140)
    m:SetFrameStrata("HIGH")
    m:SetFrameLevel(50)
    m:SetCamera(0)
    m:Hide()
    m.inUse = false
    m.ownerCard = nil
    m.tracker = CreateFrame("Frame", nil, MainFrame)
    m.tracker:SetScript("OnUpdate", nil)

    if m.SetKeepModelOnHide then
        m:SetKeepModelOnHide(true)
    end

    table.insert(CardDressUpPool, m)
end

for i=1,20 do
    local m = CreateFrame("Frame", nil, MainFrame)
    m:SetSize(40, 40)
    m:SetFrameStrata("HIGH")
    m:SetFrameLevel(50)
    m:Hide()
    m.inUse = false
    m.ownerCard = nil
    m.tracker = CreateFrame("Frame", nil, MainFrame)
    m.tracker:SetScript("OnUpdate", nil)
    m.Icon = m:CreateTexture(nil, "ARTWORK")
    m.Icon:SetAllPoints()
    m.Icon:SetTexCoord(0.07,0.93,0.07,0.93)
    m.Border = m:CreateTexture(nil, "OVERLAY")
    m.Border:SetSize(56, 56)
    m.Border:SetPoint("CENTER")
    m.Border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    table.insert(CardIconPool, m)
end

local function CreateRewardCard()
    local card = CreateFrame("Button", nil, ScrollChild)
    card:SetSize(154, 230)
    
    card.BgTex = card:CreateTexture(nil,"BACKGROUND")
    card.BgTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.BgTex:SetSize(144, 220)
    card.BgTex:SetTexture("Interface\\shop\\catalogshop")
    card.BgTex:SetTexCoord(0.000000000, 0.083742188, 0.572265625, 0.812187500)
    
    card.BorderTex = card:CreateTexture(nil,"ARTWORK")
    card.BorderTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.BorderTex:SetSize(154, 230)
    card.BorderTex:SetTexture("Interface\\shop\\catalogshop")
    card.BorderTex:SetTexCoord(0.906250000, 0.995582031, 0.468750000, 0.716796875)
    
    card.HighlightTex = card:CreateTexture(nil,"HIGHLIGHT")
    card.HighlightTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.HighlightTex:SetSize(154, 230)
    card.HighlightTex:SetTexture("Interface\\shop\\catalogshop")
    card.HighlightTex:SetTexCoord(0.003417969, 0.092285156, 0.082031250, 0.330078125)
    
    card.SelectedTex = card:CreateTexture(nil,"OVERLAY")
    card.SelectedTex:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.SelectedTex:SetSize(154, 230)
    card.SelectedTex:SetTexture("Interface\\shop\\catalogshop")
    card.SelectedTex:SetTexCoord(0.906250000, 0.995117188, 0.154296875, 0.402343750)
    card.SelectedTex:SetAlpha(0)
    
    card.ModelHolder = CreateFrame("Frame", nil, card)
    card.ModelHolder:SetFrameLevel(card:GetFrameLevel()+2)
    card.ModelHolder:SetPoint("TOPLEFT", 8, -8)
    card.ModelHolder:SetPoint("TOPRIGHT", -8, -8)
    card.ModelHolder:SetHeight(160)
    
    card.IconBorder = card.ModelHolder:CreateTexture(nil,"ARTWORK")
    card.IconBorder:SetSize(80, 80)
    card.IconBorder:SetPoint("CENTER",card.ModelHolder,"CENTER",0,0)
    card.IconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    
    card.Art = card.ModelHolder:CreateTexture(nil,"ARTWORK")
    card.Art:SetSize(64, 64)
    card.Art:SetPoint("CENTER",card.ModelHolder,"CENTER",0,0)
    card.Art:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    card.Art:SetTexCoord(0.07,0.93,0.07,0.93)
    
    card.Divider = card:CreateTexture(nil, "ARTWORK")
    card.Divider:SetTexture("Interface\\shop\\catalogshop")
    card.Divider:SetSize(140, 50)
    card.Divider:SetPoint("BOTTOM", card, "BOTTOM", 0, 2)
    card.Divider:SetTexCoord(0.714843750, 0.962402344, 0.072265625, 0.138609375)
    
    card.Name = card:CreateFontString(nil,"OVERLAY", "GameFontHighlightSmall")
    card.Name:SetPoint("TOPLEFT",  card.Divider, "BOTTOMLEFT",  0, 35)
    card.Name:SetPoint("TOPRIGHT", card.Divider, "BOTTOMRIGHT", 0, 35)
    card.Name:SetJustifyH("CENTER")
    card.Name:SetJustifyV("TOP")
    card.Name:SetText("")
    
    card.Count = card:CreateFontString(nil,"OVERLAY", "GameFontNormalSmall")
    card.Count:SetPoint("BOTTOMRIGHT", card.ModelHolder, "BOTTOMRIGHT", -5, 5)
    card.Count:SetText("")
    
    card.OriginalPrice = card:CreateFontString(nil,"OVERLAY", "GameFontDisableSmall")
    card.OriginalPrice:SetPoint("TOP", card.Name, "BOTTOM", 0, -2)
    card.OriginalPrice:SetText("")
    card.OriginalPrice:Hide()
    
    card.PriceFrame = CreateFrame("Frame", nil, card)
    card.PriceFrame:SetSize(100, 20)
    card.PriceFrame:SetPoint("TOP", card.OriginalPrice, "BOTTOM", 0, -4)
    
    card.CurrencyIcon = card.PriceFrame:CreateTexture(nil,"ARTWORK")
    card.CurrencyIcon:SetSize(14,14)
    card.CurrencyIcon:SetPoint("LEFT",0,0)
    card.CurrencyIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    card.Price = card.PriceFrame:CreateFontString(nil,"OVERLAY", "GameFontHighlight")
    card.Price:SetPoint("LEFT", card.CurrencyIcon, "RIGHT", 3, 0)
    card.Price:SetTextColor(0.2, 1, 0.2)
    card.Price:SetText("0")
    
    card.DiscountBadge = CreateDiscountBadge(card, 40)
    
    card.rewardIndex = 0
    card.rewardData = nil
    card.poolModels = {}
    card:Hide()
    return card
end

for i=1,12 do RewardCards[i] = CreateRewardCard() end

local function ClearCatalogCards()
    for i=1,#FeaturedCards do
        local c=FeaturedCards[i] ; c:Hide() ; c.itemData=nil
        if c.poolModels then
            for _, m in ipairs(c.poolModels) do ReleasePooledFrame(m) end
            c.poolModels = {}
        end
        if c.Art   then c.Art:Show() end
        if c.IconBorder then c.IconBorder:Show() end
        if c.OriginalPrice then c.OriginalPrice:Hide() end
        if c.DiscountBadge then c.DiscountBadge:Hide() end
        if c.Price then c.Price:SetTextColor(0.2, 1, 0.2) end
    end
    for i=1,#GridCards do
        local c=GridCards[i] ; c:Hide() ; c.itemData=nil
        if c.poolModels then
            for _, m in ipairs(c.poolModels) do ReleasePooledFrame(m) end
            c.poolModels = {}
        end
        if c.Art   then c.Art:Show() end
        if c.IconBorder then c.IconBorder:Show() end
        if c.OriginalPrice then c.OriginalPrice:Hide() end
        if c.DiscountBadge then c.DiscountBadge:Hide() end
        if c.Price then c.Price:SetTextColor(0.2, 1, 0.2) end
    end
end

local function ClearRewardCards()
    for i=1,#RewardCards do
        local c=RewardCards[i]   
        c:Hide()   
        c.rewardData=nil
        c.rewardIndex=0
        if c.poolModels then
            for _, m in ipairs(c.poolModels) do ReleasePooledFrame(m) end
            c.poolModels = {}
        end
        if c.Art   then c.Art:Show() end
        if c.IconBorder then c.IconBorder:Show() end
        if c.OriginalPrice then c.OriginalPrice:Hide() end
        if c.DiscountBadge then c.DiscountBadge:Hide() end
        if c.Count then c.Count:SetText("") end
    end
end

local function ClearDetailPanel()
    selectedItem=nil ; selectedRewardData=nil
    if HeroItemFrame then HeroItemFrame:Hide() end
    if HeroItemIcon  then HeroItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
    PreviewModel:ClearModel() ; PreviewModel:Hide()
    
    for _, m in ipairs(DressUpModels) do m:ClearModel() ; m:Hide() ; m.inUse = false end
    for _, m in ipairs(HeroModelPool) do m:ClearModel() ; m:Hide() ; m.inUse = false end
    for _, m in ipairs(HeroIconPool) do m:Hide() ; m.inUse = false end

    DetailTitle:SetText("Selecciona un objeto")
    DetailSub:SetText("") ; DetailDesc:SetText("")
    PriceText:SetText("0")
    PriceText:SetTextColor(1, 1, 1)
    OriginalPriceText:Hide()
    
    DetailDesc:ClearAllPoints()
    DetailDesc:SetPoint("TOPLEFT",20,-72)
    DetailDesc:SetPoint("TOPRIGHT",-20,-72)
    
    BuyButton:SetText("Comprar") ; BuyButton:Disable()
    DetailsButton:Hide()
    
    if GiftButton then GiftButton:Hide() end
    if GiftPopup then GiftPopup:Hide() end
    if GiftNameEditBox then
        GiftNameEditBox:SetText("")
        GiftNameEditBox:ClearFocus()
    end
end

local function GetActivePreviewData()
    if packageDetailsMode and selectedRewardData then return selectedRewardData end
    return selectedItem
end

local CREATURE_PREVIEW_MIN_SCALE = 0.80
local CREATURE_PREVIEW_MAX_SCALE = 1.30
local CREATURE_PREVIEW_STEP = 0.02

local function ResetSinglePreviewModel()
    if not activeHeroSingleModel then
        return
    end

    local pd = GetActivePreviewData()
    if not pd then
        return
    end

    local previewScaleFactor = GetHeroPreviewViewportScale(1)
    previewRotation = 0.20

    if activeHeroSingleModel.SetFacing then
        activeHeroSingleModel:SetFacing(previewRotation)
    end

    activeHeroSingleModel:ClearAllPoints()
    activeHeroSingleModel:SetPoint("CENTER", PreviewViewport, "CENTER", 0, 0)

    if activeHeroSingleModel:GetObjectType() == "DressUpModel" then
        local customScale = pd.modelScale or 1.0
        previewScale = 1.55 * previewScaleFactor * customScale

        if activeHeroSingleModel.SetModelScale then
            activeHeroSingleModel:SetModelScale(previewScale)
        end

        if activeHeroSingleModel.SetPosition then
            activeHeroSingleModel:SetPosition(0, 0, -0.40)
        end

        return
    end

    if pd.creatureid then
        local adj = GetCreatureAdjustment(pd.creatureid)
        local customScale = pd.modelScale or 1.0
        local resetScale = (adj.scale or 0.80) * 1.35 * previewScaleFactor * customScale
        local creatureZ = (adj.z or 2.10) - 0.30

        previewScale = math.max(CREATURE_PREVIEW_MIN_SCALE, math.min(CREATURE_PREVIEW_MAX_SCALE, resetScale))
        previewPosX = adj.x or 0
        previewPosY = adj.y or 0
        previewPosZ = creatureZ

        if activeHeroSingleModel.SetModelScale then
            activeHeroSingleModel:SetModelScale(previewScale)
        end

        if activeHeroSingleModel.SetPosition then
            activeHeroSingleModel:SetPosition(previewPosX, previewPosY, previewPosZ)
        end
    end
end

local function ReleaseAllHeroModels()
    for _, m in ipairs(HeroModelPool) do m.inUse=false ; m:ClearModel() ; m:Hide() end
    for _, m in ipairs(DressUpModels) do m.inUse=false ; m:ClearModel() ; m:Hide() end
    for _, m in ipairs(HeroIconPool) do m.inUse=false ; m:Hide() end
    activeHeroModelCount = 0
    activeHeroSingleModel = nil
end

local function GetHeroViewerOffsets(count)
    if count == 1 then return {0} end
    if count == 2 then return {-160, 160} end 
    if count == 3 then return {-260, 0, 260} end
    return {-300, -100, 100, 300}
end

local function GetHeroPreviewFrameSize(totalModels)
    if totalModels <= 1 then
        return 930, 834
    elseif totalModels == 2 then
        return 430, 430
    elseif totalModels == 3 then
        return 430, 430
    else
        return 430, 430
    end
end

local function GetHeroPreviewViewportScale(totalModels)
    if totalModels <= 1 then
        return 0.58
    elseif totalModels == 2 then
        return 0.30
    elseif totalModels == 3 then
        return 0.78
    else
        return 0.86
    end
end

local function GetFeaturedModelOffsets(count)
    if count == 1 then return {0} end
    if count == 2 then return {-70, 70} end
    if count == 3 then return {-100, 0, 100} end
    return {-120, -40, 40, 120}
end

local function GetGridModelOffsets(count)
    if count == 1 then return {0} end
    if count == 2 then return {-25, 25} end
    if count == 3 then return {-35, 0, 35} end
    return {-45, -15, 15, 45}
end

local function ApplyHeroPreviewFrameSize(model, totalModels)
    local frameW, frameH = GetHeroPreviewFrameSize(totalModels)
    model:SetSize(frameW, frameH)
end

local function RenderPreviewData(item)
    ReleaseAllHeroModels()
    PreviewModel:ClearModel()
    PreviewModel:Hide()

    UpdateMainBackground(GetItemBackground(item))

    if HeroItemFrame then
        HeroItemFrame:Hide()
    end

    if not item then
        return
    end

    local isPackage = (item.entryType == "package" or item.previewType == "multiModel")
    local force3D = (item.showModel == true)
    local isReward3D = (item.entryType == "reward" and (item.previewType == "itemSet" or item.previewType == "creature3D"))
    local isItemCreature3D = (item.previewType == "creature3D" and item.creatureid and tonumber(item.creatureid) > 0)

    if isPackage or force3D or isReward3D or isItemCreature3D then
        print("[DEBUG] Preview item modelScale:", item.modelScale)
        local displayModels = {}

        if isItemCreature3D and not isPackage then
            table.insert(displayModels, {
                type = "creature",
                creatureid = tonumber(item.creatureid)
            })
        elseif item.rewards and #item.rewards > 0 then
            displayModels = GroupArmorSetsByType(item.rewards)
        end

        if #displayModels == 0 then
            if item.previewType == "creature3D" and item.creatureid and tonumber(item.creatureid) > 0 then
                table.insert(displayModels, {
                    type = "creature",
                    creatureid = tonumber(item.creatureid)
                })
            elseif item.previewType == "itemSet" and item.itemSet then
                table.insert(displayModels, {
                    type = "itemSet",
                    itemSet = item.itemSet,
                    displayRace = item.displayRace,
                    displayGender = item.displayGender
                })
            end
        end

        displayModels = FilterIconsIf3DPresent(displayModels)

        if #displayModels < 4 then
            displayModels = ReorderForSymmetry(displayModels)
        elseif #displayModels == 4 then
            local creatures, sets = {}, {}
            for _, m in ipairs(displayModels) do
                if m.type == "creature" then
                    table.insert(creatures, m)
                elseif m.type == "itemSet" then
                    table.insert(sets, m)
                end
            end

            if #creatures == 2 and #sets == 2 then
                displayModels = {creatures[1], sets[1], sets[2], creatures[2]}
            elseif #creatures == 1 and #sets == 3 then
                displayModels = {creatures[1], sets[1], sets[2], sets[3]}
            else
                displayModels = ReorderForSymmetry(displayModels)
            end
        end

        local totalModels = #displayModels

        if totalModels > 0 then
            activeHeroModelCount = totalModels
            activeHeroSingleModel = nil

            local creatureCount = 0
            local charCount = 0
            for _, m in ipairs(displayModels) do
                if m.type == "creature" then
                    creatureCount = creatureCount + 1
                elseif m.type == "itemSet" then
                    charCount = charCount + 1
                end
            end

            local configKey = DetectPositionConfig(creatureCount, charCount, totalModels)
            local positionConfig = POSITION_CONFIG[configKey] or POSITION_CONFIG["default_single"]

            local mountIdx = 1
            local charIdx = 1

            local frameW, frameH = GetHeroPreviewFrameSize(totalModels)

            for idx, modelData in ipairs(displayModels) do
                local pos = nil
                if modelData.type == "creature" and positionConfig.mounts and positionConfig.mounts[mountIdx] then
                    pos = positionConfig.mounts[mountIdx]
                    mountIdx = mountIdx + 1
                elseif modelData.type == "itemSet" and positionConfig.chars and positionConfig.chars[charIdx] then
                    pos = positionConfig.chars[charIdx]
                    charIdx = charIdx + 1
                end

                if modelData.type == "creature" then
                    local m = nil
                    for _, h in ipairs(HeroModelPool) do
                        if not h.inUse then
                            h.inUse = true
                            m = h
                            break
                        end
                    end

                    if m then
                        if totalModels == 1 then
                            activeHeroSingleModel = m
                        end

                        m:SetSize(frameW, frameH)

                        if pos then
                            local previewScaleFactor = GetHeroPreviewViewportScale(totalModels)

                            local modelScale = modelData.modelScale or 1.0
                            ApplyCreaturePreset(m, "HERO_POSITIONED", {
                                scale = (pos.scale or 1.0) * previewScaleFactor * modelScale,
                                facing = pos.facing,
                                x = 0,
                                y = 0,
                                z = pos.zAdj or 0,
                            }, modelData.creatureid)

                            m:ClearAllPoints()
                            -- Usar heroX/heroY si existen, si no usar x/y
                            local hx = pos.heroX ~= nil and pos.heroX or pos.x
                            local hy = pos.heroY ~= nil and pos.heroY or pos.y
                            m:SetPoint("CENTER", PreviewViewport, "CENTER", hx, hy)
                        else
                            local adj = GetCreatureAdjustment(modelData.creatureid)
                            local previewScaleFactor = GetHeroPreviewViewportScale(totalModels)
                            local scaleMult = (totalModels == 1) and 1.35 or 1.15
                            local baseScale = (adj.scale or 0.80) * scaleMult * previewScaleFactor
                            local creatureZ = (adj.z or 2.10) - 0.30

                            local modelScale = modelData.modelScale or 1.0
                            ApplyCreaturePreset(m, "HERO_DYNAMIC", {
                                scale = baseScale * modelScale,
                                facing = adj.facing or 0.20,
                                x = adj.x or 0,
                                y = adj.y or 0,
                                z = creatureZ,
                            }, modelData.creatureid)

                            local xOff = GetHeroViewerOffsets(totalModels)[idx] or 0
                            local forcedY = (totalModels == 1) and 0 or ((totalModels == 2) and 10 or 20)

                            m:ClearAllPoints()
                            m:SetPoint("CENTER", PreviewViewport, "CENTER", xOff, forcedY)
                        end

                        m:Show()
                    end

                elseif modelData.type == "itemSet" then
                    local m = nil
                    for _, d in ipairs(DressUpModels) do
                        if not d.inUse then
                            d.inUse = true
                            m = d
                            break
                        end
                    end

                    if m then
                        if totalModels == 1 then
                            activeHeroSingleModel = m
                        end

                        m:SetSize(frameW, frameH)

                        if pos then
                            local previewScaleFactor = GetHeroPreviewViewportScale(totalModels)

                            m:ClearAllPoints()
                            -- Usar heroX/heroY si existen, si no usar x/y
                            local hx = pos.heroX ~= nil and pos.heroX or pos.x
                            local hy = pos.heroY ~= nil and pos.heroY or pos.y
                            m:SetPoint("CENTER", PreviewViewport, "CENTER", hx, hy)

                            local modelScale = modelData.modelScale or 1.0
                            ApplyDressUpPreset(m, "HERO_POSITIONED", {
                                scale = ((pos.scale or 1.0) * previewScaleFactor) * 0.80 * modelScale,
                                facing = pos.facing,
                                x = 0,
                                y = 0,
                                z = pos.zAdj or -0.40,
                            })

                            ShowItemSetOnModel(m, modelData.itemSet, modelData.displayRace, modelData.displayGender, pos.facing)
                        else
                            local previewScaleFactor = GetHeroPreviewViewportScale(totalModels)

                            m:ClearAllPoints()

                            local xOff = GetHeroViewerOffsets(totalModels)[idx] or 0
                            local forcedY = (totalModels == 1) and 0 or ((totalModels == 2) and 10 or 20)

                            m:SetPoint("CENTER", PreviewViewport, "CENTER", xOff, forcedY)

                            local scaleMult = ((totalModels == 1) and 1.55 or 1.30) * previewScaleFactor
                            local charZ = (totalModels == 1) and -0.40 or -0.30
                            local facing = (totalModels == 1) and 0.20 or ((idx == 1) and 0.30 or -0.30)

                            local modelScale = modelData.modelScale or 1.0
                            ApplyDressUpPreset(m, "HERO_DYNAMIC", {
                                scale = scaleMult * modelScale,
                                facing = facing,
                                x = 0,
                                y = 0,
                                z = charZ,
                            })

                            ShowItemSetOnModel(m, modelData.itemSet, modelData.displayRace, modelData.displayGender, facing)
                        end
                    end
                end
            end
        end

    else
        if HeroItemFrame then
            HeroItemFrame:Show()
        end

        if HeroItemIcon then
            local texture = nil

            if item.service and item.icon and item.icon ~= "" then
                texture = "Interface\\Icons\\" .. item.icon
            else
                texture = item.heroTexture or GetHeroTexture(item)
            end

            if not texture or texture == "" or texture == "Interface\\Icons\\" then
                texture = "Interface\\Icons\\INV_Misc_Gear_01"
            end

            HeroItemIcon:SetTexture(texture)
        end

        if HeroItemBorder then
            if item.service then
                HeroItemBorder:Hide()
            else
                HeroItemBorder:Show()
            end
        end
    end

    if PurchaseBox then
        PurchaseBox:Raise()
    end
end

local function FillCardPreview(card, item)
    if not card then return end
    if card.poolModels then
        for _, m in ipairs(card.poolModels) do ReleasePooledFrame(m) end
    end
    card.poolModels = {}

    local isPackage = (item.entryType == "package" or item.previewType == "multiModel")
    local force3D = (item.showModel == true)
    local isItemCreature3D = (item.previewType == "creature3D" and item.creatureid and tonumber(item.creatureid) > 0)
    local isItemSet = (item.previewType == "itemSet" and item.itemSet and #item.itemSet > 0)

    if isPackage or force3D or isItemCreature3D or isItemSet then
        if card.Art   then card.Art:Hide() end
        if card.IconBorder then card.IconBorder:Hide() end

        local displayModels = {}
        
        if isItemCreature3D and not isPackage then
            table.insert(displayModels, {
                type = "creature", 
                creatureid = tonumber(item.creatureid)
            })
        elseif isItemSet and not isPackage then
            table.insert(displayModels, {
                type = "itemSet", 
                itemSet = item.itemSet,
                displayRace = item.displayRace,
                displayGender = item.displayGender
            })
        elseif item.rewards and #item.rewards > 0 then
            displayModels = GroupArmorSetsByType(item.rewards)
        end
        
        if #displayModels == 0 and item.creatureid and tonumber(item.creatureid) > 0 then
            table.insert(displayModels, {type="creature", creatureid=tonumber(item.creatureid)})
        end
        
        if #displayModels == 0 and item.itemSet and #item.itemSet > 0 then
            table.insert(displayModels, {
                type = "itemSet", 
                itemSet = item.itemSet,
                displayRace = item.displayRace,
                displayGender = item.displayGender
            })
        end

        displayModels = FilterIconsIf3DPresent(displayModels)
        if #displayModels < 4 then
            displayModels = ReorderForSymmetry(displayModels)
        end
        while #displayModels > 4 do table.remove(displayModels) end

        if #displayModels == 1 and displayModels[1].type == "icon" then 
            if card.Art then card.Art:Show() ; card.Art:SetTexture(GetDisplayTexture(item)) end
            if card.IconBorder then card.IconBorder:Show() end
            return 
        end

        if #displayModels > 0 then
            local numModels = #displayModels
        local creatureCount = 0
        local charCount = 0

        for _, model in ipairs(displayModels) do
            if model.type == "creature" then
                creatureCount = creatureCount + 1
            elseif model.type == "itemSet" then
                charCount = charCount + 1
            end
        end

        local cardConfig = GetCardPositionConfig(creatureCount, charCount, numModels, card.isFeatured)
        local mountIdx = 1
        local charIdx = 1

            for idx, modelData in ipairs(displayModels) do
                local m = nil
                if modelData.type == "icon" then
                    m = GetPooledFrame(CardIconPool)
                elseif modelData.type == "itemSet" then
                    m = GetPooledFrame(CardDressUpPool)
                else
                    m = GetPooledFrame(CardModelPool)
                end

                if m then
                    m.ownerCard = card
                    table.insert(card.poolModels, m)
                    local pos = nil
                if modelData.type == "creature" and cardConfig.mounts and cardConfig.mounts[mountIdx] then
                    pos = cardConfig.mounts[mountIdx]
                    mountIdx = mountIdx + 1
                elseif modelData.type == "itemSet" and cardConfig.chars and cardConfig.chars[charIdx] then
                    pos = cardConfig.chars[charIdx]
                    charIdx = charIdx + 1
                end

                if modelData.type == "creature" then
    local adj = GetCreatureAdjustment(modelData.creatureid)
    local baseScale = adj.scale or 0.45

    local scale = baseScale
    local facing = adj.facing or 0.20
    local posX = adj.x or 0
    local posY = adj.y or 0
    local posZ = adj.z or 2.10

    if pos then
        scale = baseScale * (pos.scale or 1.0) * (pos.scaleFactor or 0.20)
        facing = pos.facing or facing

        -- Igual que preview: posición interna neutra y offset visual por SetPoint
        posX = 0
        posY = 0
        posZ = pos.zAdj or 0
    else
        scale = baseScale * (card.isFeatured and 1.10 or 0.85)
        if not card.isFeatured then
            posZ = posZ - 0.1
        end
    end

    ApplyCreaturePreset(m, card.isFeatured and "CARD_FEATURED" or "CARD_GRID", {
        scale = scale,
        facing = facing,
        x = posX,
        y = posY,
        z = posZ,
    }, modelData.creatureid)

                elseif modelData.type == "itemSet" then
    m:ClearModel()

    local scale = card.isFeatured and 0.42 or 0.22
    local facing = 0
    local x = 0
    local y = 0
    local z = card.isFeatured and -0.05 or -0.10

    if pos then
        scale = (pos.scale or 1.0) * (pos.scaleFactor or 0.28)
        facing = pos.facing or 0

        -- Igual que preview: SetPoint maneja la posición visual
        x = 0
        y = 0
        z = pos.zAdj or z
    end

    ApplyDressUpPreset(m, card.isFeatured and "CARD_FEATURED" or "CARD_GRID", {
        scale = scale,
        facing = facing,
        x = x,
        y = y,
        z = z,
    })

        m._storedItemSet = modelData.itemSet
    m._storedDisplayRace = modelData.displayRace
    m._storedDisplayGender = modelData.displayGender
    m._storedFacing = facing

    ShowItemSetOnModel(m, modelData.itemSet, modelData.displayRace, modelData.displayGender, facing)

                elseif modelData.type == "icon" then
                    m.Icon:SetTexture(modelData.iconTexture)
                    if m.Border then
                        m.Border:Show()
                    end
                end

                    m.tracker:SetScript("OnUpdate", function()
                        if not card or not card:IsShown() or not ScrollFrame or not ScrollFrame:IsVisible() then
                            m:Hide()
                            return
                        end

                        local topPad = card.isFeatured and 2 or 1
                        local bottomPad = card.isFeatured and 14 or 10

                        if not IsModelHolderFullyVisibleY(card.ModelHolder, topPad, bottomPad) then
                            m:Hide()
                            return
                        end

                        local cx, cy = card.ModelHolder:GetCenter()
                        if not cx or not cy then
                            m:Hide()
                            return
                        end

                        m:ClearAllPoints()

                        local offsetX = 0
local offsetY = 0

if pos then
    offsetX = pos.x or 0
    offsetY = pos.y or 0
end

if modelData.type == "icon" then
    local yOff = card.isFeatured and 0 or 15
    m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx + offsetX, cy + yOff + offsetY)
else
    m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx + offsetX, cy + offsetY)
end

                        if not m:IsShown() then
                            m:Show()

                            if m:GetObjectType() == "DressUpModel" then
                                EnsureDressUpSetApplied(m)
                            end
                        end
                    end)
                end
            end
            return
        end
    else
        if card.Art then 
            card.Art:Show() 
            card.Art:SetTexture(GetDisplayTexture(item)) 
        end
        if card.IconBorder then
            if item.service then
                card.IconBorder:Hide()
            else
                card.IconBorder:Show()
            end
        end
    end
end

local function FillRewardCardPreview(card, rewardData)
    if not card then return end
    if card.poolModels then
        for _, m in ipairs(card.poolModels) do ReleasePooledFrame(m) end
    end
    card.poolModels = {}
    
    if rewardData.previewType == "creature3D" or rewardData.isCreature then
        if card.Art then card.Art:Hide() end
        if card.IconBorder then card.IconBorder:Hide() end
        
        local creatureId = tonumber(rewardData.creatureid)
        if creatureId and creatureId > 0 then
            local m = GetPooledFrame(CardModelPool)
            if m then
                m.ownerCard = card
                table.insert(card.poolModels, m)
                
                local adj = GetCreatureAdjustment(creatureId)
                local baseScale = adj.scale or 0.45
                local customScale = rewardData.modelScale or 1.0
                local scale = baseScale * customScale
                local z = (adj.z or 2.10) - 0.1
                ApplyCreaturePreset(m, "REWARD", {
                    scale = scale,
                    facing = adj.facing or 0.20,
                    x = adj.x or 0,
                    y = adj.y or 0,
                    z = z,
                }, creatureId)

                m.tracker:SetScript("OnUpdate", function()
                    if not card or not card:IsShown() or not ScrollFrame or not ScrollFrame:IsVisible() then
                        m:Hide()
                        return
                    end

                    if not IsModelHolderFullyVisibleY(card.ModelHolder, 1, 10) then
    m:Hide()
    return
end

                    local cx, cy = card.ModelHolder:GetCenter()
                    if not cx or not cy then
                        m:Hide()
                        return
                    end

                    m:ClearAllPoints()
                    m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

                    if not m:IsShown() then
                        m:Show()
                    end
                end)
            end
        end
        return
        
    elseif rewardData.previewType == "itemSet" and rewardData.itemSet then
        if card.Art then card.Art:Hide() end
        if card.IconBorder then card.IconBorder:Hide() end
        
        local m = GetPooledFrame(CardDressUpPool)
        if m then
            m.ownerCard = card
            table.insert(card.poolModels, m)
            m:ClearModel()
            local customScale = rewardData.modelScale or 1.0
            ApplyDressUpPreset(m, "REWARD", {
                scale = 1.0 * customScale,
                facing = 0,
                x = -0.15,
                y = 0,
                z = -0.1,
            })
                    m._storedItemSet = rewardData.itemSet
        m._storedDisplayRace = rewardData.displayRace
        m._storedDisplayGender = rewardData.displayGender
        m._storedFacing = 0

        ShowItemSetOnModel(m, rewardData.itemSet, rewardData.displayRace, rewardData.displayGender, 0)

            m.tracker:SetScript("OnUpdate", function()
                if not card or not card:IsShown() or not ScrollFrame or not ScrollFrame:IsVisible() then
                    m:Hide()
                    return
                end

                if not IsModelHolderFullyVisibleY(card.ModelHolder, 1, 10) then
    m:Hide()
    return
end

                local cx, cy = card.ModelHolder:GetCenter()
                if not cx or not cy then
                    m:Hide()
                    return
                end

                m:ClearAllPoints()
                m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

                if not m:IsShown() then
                m:Show()

                if m:GetObjectType() == "DressUpModel" then
                    EnsureDressUpSetApplied(m)
                end
            end
            end)
        end
        return
    end

    local tex = rewardData.heroTexture or GetRewardTexture(rewardData)
    if card.Art then 
        card.Art:Show() 
        card.Art:SetTexture(tex) 
    end
    if card.IconBorder then
        if rewardData.rewardType == "service" then
            card.IconBorder:Hide()
        else
            card.IconBorder:Show()
        end
    end
end

local function ApplyCardState(card, isSelected, isFeatured)
    if isSelected then
        if card.SelectedTex then card.SelectedTex:SetAlpha(1) end
    else
        if card.SelectedTex then card.SelectedTex:SetAlpha(0) end
    end
end

local function ApplyRewardCardState(card, isSelected)
    if isSelected then
        if card.SelectedTex then card.SelectedTex:SetAlpha(1) end
    else
        if card.SelectedTex then card.SelectedTex:SetAlpha(0) end
    end
end

local function RefreshCatalogSelectionOnly()
    for i = 1, #FeaturedCards do
        local c = FeaturedCards[i]
        if c and c.itemData then
            local isSelected = selectedItem
                and selectedItem.id == c.itemData.id
                and selectedItem.category == c.itemData.category

            ApplyCardState(c, isSelected, true)
        end
    end

    for i = 1, #GridCards do
        local c = GridCards[i]
        if c and c.itemData then
            local isSelected = selectedItem
                and selectedItem.id == c.itemData.id
                and selectedItem.category == c.itemData.category

            ApplyCardState(c, isSelected, false)
        end
    end
end

local function RefreshRewardSelection()
    for i=1,#RewardCards do
        local c=RewardCards[i]
        if c:IsShown() then ApplyRewardCardState(c, i==selectedRewardIndex) end
    end
end

local function RenderSelectedReward(rewardData)
    if not rewardData then return end
    selectedRewardData=rewardData
    DetailTitle:SetText(rewardData.name or "Recompensa")
    DetailSub:SetText(rewardData.rewardType=="service" and "Servicio incluido" or currentCategory)
    DetailDesc:SetText("Los artículos comprados en la tienda serán enviados al buzón del juego")
    
    local price = 0
    if currentPackageItem then
        price = tonumber(currentPackageItem.price) or 0
    end
    
    if price > 0 then
        PriceText:SetText("|cff00ff00Incluido|r")
        PriceText:SetTextColor(0.2, 1, 0.2)
    else
        PriceText:SetText("|cff00ff00Incluido|r")
        PriceText:SetTextColor(0.2, 1, 0.2)
    end
    OriginalPriceText:Hide()
    
    BuyButton:SetText("Comprar") ; BuyButton:Enable()
    DetailsButton:Hide()
    
    if GiftButton then GiftButton:Hide() end
    
    RenderPreviewData(rewardData)
end

local function GetFilteredProducts()
    local result={}
    local q=string.lower(Trim(SearchBox:GetText() or ""))
    for _,item in ipairs(productEntries or {}) do
        if q=="" then
            table.insert(result,item)
        else
            local name=string.lower(tostring(item.name or ""))
            local desc=string.lower(tostring(item.description or ""))
            if string.find(name,q,1,true) or string.find(desc,q,1,true) then
                table.insert(result,item)
            end
        end
    end
    return result
end

local function ApplyDiscountToCard(card, item)
    if not card or not item then return end
    
    local price = tonumber(item.price) or 0
    local originalPrice = tonumber(item.originalPrice) or 0
    local discount = tonumber(item.discount) or 0
    
    local hasDiscount = (discount > 0 and originalPrice > price)

    if card.CurrencyIcon and card.BottomRow then
        card.CurrencyIcon:ClearAllPoints()
        if hasDiscount then
            card.CurrencyIcon:SetPoint("CENTER", card.BottomRow, "CENTER", -35, 0)
        else
            card.CurrencyIcon:SetPoint("CENTER", card.BottomRow, "CENTER", -10, 0)
        end
        
        card.Price:ClearAllPoints()
        card.Price:SetPoint("LEFT", card.CurrencyIcon, "RIGHT", 5, 0)
    end
    
    if hasDiscount then
        -- Precio con descuento en VERDE, precio original tachado en ROJO
        if currentCurrencyAmount >= price then
            card.Price:SetText("|cff00ff00" .. price .. "|r   |cffff0000~~" .. originalPrice .. "~~|r")
        else
            card.Price:SetText("|cffff0000" .. price .. "|r   |cffff0000~~" .. originalPrice .. "~~|r")
        end

        if card.OriginalPrice then
            card.OriginalPrice:Hide()
        end

        if card.DiscountBadge then
            card.DiscountBadge.Text:SetText("-" .. discount .. "%")
            card.DiscountBadge:Show()
        end
    else
        if currentCurrencyAmount >= price then
            card.Price:SetTextColor(0.2, 1, 0.2)
        else
            card.Price:SetTextColor(1, 0.25, 0.25)
        end
        card.Price:SetText(price)

        if card.OriginalPrice then
            card.OriginalPrice:Hide()
        end
        if card.DiscountBadge then
            card.DiscountBadge:Hide()
        end
    end
end
local function FillCard(card, item, isFeatured)
    card.itemData=item
    card.Name:SetText(TruncateText(item.name or "Objeto", 36))
    FillCardPreview(card, item)
    if card.CurrencyIcon then
        card.CurrencyIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    ApplyDiscountToCard(card, item)
    
    local isSelected=selectedItem and selectedItem.id==item.id and selectedItem.category==item.category
    ApplyCardState(card, isSelected, isFeatured)
    card:SetScript("OnClick", function(self)
    if not self.itemData then return end

    local sameSelection = selectedItem
        and selectedItem.id == self.itemData.id
        and selectedItem.category == self.itemData.category

    if sameSelection and not packageDetailsMode then
        RefreshCatalogSelectionOnly()
        return
    end

    packageDetailsMode = false
    currentPackageItem = nil
    selectedRewardIndex = 1
    selectedRewardData = nil
    BackButton:Hide()

    AIO.Handle("FelStormStore", "RequestSelectedItem", currentCategory, self.itemData.id)
end)
    card:SetScript("OnEnter", function(self)
        local sel=selectedItem and self.itemData and selectedItem.id==self.itemData.id and selectedItem.category==self.itemData.category
        if not sel then self:SetBackdropColor(0.15,0.10,0.02,0.98) end
    end)
    card:SetScript("OnLeave", function(self)
        local sel=selectedItem and self.itemData and selectedItem.id==self.itemData.id and selectedItem.category==self.itemData.category
        ApplyCardState(self, sel, isFeatured)
    end)
end

local function ApplyDiscountToDetailPanel(item)
    if not item then 
        PriceText:SetText("0")
        PriceText:SetTextColor(1, 1, 1)
        OriginalPriceText:Hide()
        return 
    end
    
    local price = tonumber(item.price) or 0
    local originalPrice = tonumber(item.originalPrice) or 0
    local discount = tonumber(item.discount) or 0
    
    if currentCurrencyAmount >= price then
        PriceText:SetText(price)
        PriceText:SetTextColor(0.2, 1, 0.2)
    else
        PriceText:SetText(price)
        PriceText:SetTextColor(1, 0.25, 0.25)
    end

    PriceFrame:ClearAllPoints()
    PriceFrame:SetPoint("BOTTOM", PurchaseBox, "BOTTOM", -30, 48)
    
    if discount > 0 and originalPrice > price then
        OriginalPriceText:ClearAllPoints()
        OriginalPriceText:SetPoint("LEFT", PriceText, "RIGHT", 8, 0)
        OriginalPriceText:SetText("|cffff0000~~" .. originalPrice .. "~~|r")
        OriginalPriceText:SetFontObject("GameFontHighlightLarge")
        OriginalPriceText:Show()
        
        DetailDesc:ClearAllPoints()
        DetailDesc:SetPoint("TOPLEFT",20,-82)
        DetailDesc:SetPoint("TOPRIGHT",-20,-82)
    else
        OriginalPriceText:Hide()
        DetailDesc:ClearAllPoints()
        DetailDesc:SetPoint("TOPLEFT",20,-72)
        DetailDesc:SetPoint("TOPRIGHT",-20,-72)
    end
end

local function RenderSelectedItem(item)
    selectedItem=item ; selectedRewardData=nil
    if not item then ClearDetailPanel() return end
    
    if item.service then
        if (not item.icon or item.icon == "") and item.heroTexture then
            local iconName = string.match(item.heroTexture, "Interface\\Icons\\(.+)")
            if iconName then
                item.icon = iconName
            end
        end
        
        if not item.icon or item.icon == "" then
            item.icon = "INV_Misc_Gear_01"
            item.heroTexture = "Interface\\Icons\\INV_Misc_Gear_01"
        end
    end
    
    DetailTitle:SetText(item.name or "Objeto")
    if item.entryType=="package" then
        DetailSub:SetText("Paquete") ; DetailsButton:Show()
    elseif item.previewType=="creature3D" then
        DetailSub:SetText(currentCategory or "Montura") ; DetailsButton:Hide()
    elseif item.previewType=="itemSet" then
        DetailSub:SetText("Transfiguración") ; DetailsButton:Hide()
    elseif item.previewType=="multiModel" then
        DetailSub:SetText("Pack Especial") ; DetailsButton:Show()
    elseif item.service then
        DetailSub:SetText("Servicio") ; DetailsButton:Hide()
    else
        DetailSub:SetText(currentCategory or "") ; DetailsButton:Hide()
    end
    DetailDesc:SetText("Los artículos comprados en la tienda serán enviados al buzón del juego")
    
    ApplyDiscountToDetailPanel(item)

    -- Configurar botón según tipo de item
    if item.entryType=="package" or item.previewType=="multiModel" then
        -- Paquete: botón a la izquierda, Detalles a la derecha
        BuyButton:SetText("Comprar") ; BuyButton:Enable()
        BuyButton:ClearAllPoints()
        BuyButton:SetPoint("BOTTOMLEFT", PurchaseBox, "BOTTOMLEFT", 18, 22)
        BuyButton:SetSize(142, 30)
    else
        -- Item normal: botón a la izquierda, espacio para regalo
        BuyButton:SetText("Comprar") ; BuyButton:Enable()
        BuyButton:ClearAllPoints()
        BuyButton:SetPoint("BOTTOMLEFT", PurchaseBox, "BOTTOMLEFT", 18, 22)
        BuyButton:SetSize(142, 30)
    end

    if GiftButton then
        if item and not item.service then
            GiftButton:Show()
        else
            GiftButton:Hide()
        end
    end

    RenderPreviewData(item)
end

local function RenderPackageDetailsView(packageItem)
    if not packageItem or packageItem.entryType~="package" then 
        return 
    end
    packageDetailsMode=true
    currentPackageItem=packageItem
    BackButton:Show()
    ClearCatalogCards()
    ClearRewardCards()
    
    -- Reposicionar el ScrollFrame
    ScrollFrame:ClearAllPoints()
    ScrollFrame:SetPoint("TOPLEFT", 16, -112)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 18)
    
    -- Mover el divisor
    LeftPanelDivider:ClearAllPoints()
    LeftPanelDivider:SetPoint("TOPLEFT", 18, -84)
    LeftPanelDivider:SetPoint("TOPRIGHT", -18, -84)
    
    -- Reposicionar el título
    LeftTitle:ClearAllPoints()
    LeftTitle:SetPoint("TOPLEFT", 18, -54)
    LeftTitle:SetText(string.upper(packageItem.name or "PAQUETE"))
    LeftTitle:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
    
    -- Reposicionar el subtítulo debajo del divisor
    LeftSubtitle:ClearAllPoints()
    LeftSubtitle:SetPoint("TOPLEFT", 18, -92)
    LeftSubtitle:SetText("")
    
    -- Reposicionar la descripción
    LeftDescription:ClearAllPoints()
    LeftDescription:SetPoint("TOPLEFT", 18, -110)
    LeftDescription:SetWidth(520)
    LeftDescription:SetJustifyH("LEFT")
    LeftDescription:SetText("")

    selectedRewardIndex = 0
    selectedRewardData = nil
    DetailTitle:SetText(packageItem.name or "Paquete Especial")
    DetailSub:SetText(currentCategory or "Paquete")
    DetailDesc:SetText("Contiene todos los objetos listados a la izquierda.")
    
    ApplyDiscountToDetailPanel(packageItem)
    
    BuyButton:SetText("Comprar Paquete") ; BuyButton:Enable()
    BuyButton:ClearAllPoints()
    BuyButton:SetPoint("BOTTOM", PurchaseBox, "BOTTOM", 0, 22)
    BuyButton:SetSize(180, 30)
    DetailsButton:Hide()
    
    if GiftButton then GiftButton:Show() end
    
    RenderPreviewData(packageItem)

    local rewards=packageItem.rewards or {}
    
    local colSpacing=168
    local rowSpacing=250
    local startY=-20
    
    for i=1,#rewards do
        local reward=rewards[i]
        local card=RewardCards[i]
        if not card then break end
        
        local rewardData=NormalizeRewardEntry(reward, packageItem)
        card.rewardData=rewardData
        card.rewardIndex=i
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        
        local y = startY-(row*rowSpacing)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 10+(col*colSpacing), y)
        
        FillRewardCardPreview(card, rewardData)
        card.Name:SetText(TruncateText(rewardData.name or "Recompensa", 30))
        
        if rewardData.count and rewardData.count > 1 then
            card.Count:SetText("|cffffd24ax"..tostring(rewardData.count).."|r")
        else
            card.Count:SetText("")
        end
        
        card.Price:SetText("")
        card.OriginalPrice:Hide()
        card.DiscountBadge:Hide()
        card.CurrencyIcon:Hide()
        
        if reward.type=="item" or reward.type=="creature3D" then
            if reward.id then
                SetupItemTooltip(card, reward.id)
            end
        end
        
        card:SetScript("OnClick", function(self)
            selectedRewardIndex=self.rewardIndex
            RefreshRewardSelection()
            RenderSelectedReward(self.rewardData)
        end)
        card:SetScript("OnEnter", function(self)
            if self.rewardIndex~=selectedRewardIndex then
                self:SetBackdropColor(0.15,0.10,0.02,0.98)
            end
        end)
        card:SetScript("OnLeave", function(self)
            ApplyRewardCardState(self, self.rewardIndex==selectedRewardIndex)
        end)
        card:Show()
    end
    
    local rows = math.ceil(math.max(1, #rewards) / 3)
	local totalHeight = math.abs(startY) + (rows * rowSpacing) + 40
	ScrollChild:SetHeight(totalHeight)

	local snapPoints = {0}
	local currentOffset = 0
	for i = 2, rows do
		currentOffset = currentOffset + rowSpacing
		table.insert(snapPoints, currentOffset)
	end
	SetScrollSnapPoints(snapPoints)
    
    -- Ajustar el scroll del ScrollFrame para que muestre el inicio
    local scrollBar = _G["FelStormStoreScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetValue(0)
    end
    
    RefreshRewardSelection()
end

local function ExitPackageDetailsView()
    packageDetailsMode=false
    currentPackageItem=nil
    selectedRewardIndex=1
    selectedRewardData=nil
    BackButton:Hide()
    ClearRewardCards()
    
    -- Restaurar el ScrollFrame
    ScrollFrame:ClearAllPoints()
    ScrollFrame:SetPoint("TOPLEFT", 16, -60)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 18)
    
    -- Restaurar el divisor
    LeftPanelDivider:ClearAllPoints()
    LeftPanelDivider:SetPoint("TOPLEFT", 18, -42)
    LeftPanelDivider:SetPoint("TOPRIGHT", -18, -42)
    
    -- Restaurar título
    LeftTitle:ClearAllPoints()
    LeftTitle:SetPoint("TOPLEFT", 18, -10)
    LeftTitle:SetText(string.upper(currentCategory or "DESTACADO"))
    LeftTitle:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
    
    -- Restaurar subtítulo
    LeftSubtitle:ClearAllPoints()
    LeftSubtitle:SetPoint("TOPLEFT", 18, -48)
    LeftSubtitle:SetText("")
    
    -- Restaurar descripción
    LeftDescription:ClearAllPoints()
    LeftDescription:SetPoint("TOPLEFT", 18, -66)
    LeftDescription:SetWidth(520)
    LeftDescription:SetJustifyH("LEFT")
    LeftDescription:SetText("")

    local scrollBar = _G["FelStormStoreScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetValue(0)
    end
    
    RefreshCatalog()
    if selectedItem then RenderSelectedItem(selectedItem) end
end

local function Count3DModels(item)
    if not item then 
        return 0, 0 
    end
    
    local creatureCount = 0
    local charCount = 0
    
    if item.rewards and #item.rewards > 0 then
        for _, reward in ipairs(item.rewards) do
            if reward.previewType == "creature3D" and reward.creatureid and tonumber(reward.creatureid) > 0 then
                creatureCount = creatureCount + 1
            elseif reward.previewType == "itemSet" and reward.itemSet and #reward.itemSet > 0 then
                charCount = charCount + 1
            end
        end
    end
    
    if item.previewType == "creature3D" and item.creatureid and tonumber(item.creatureid) > 0 then
        creatureCount = creatureCount + 1
    end
    
    if item.previewType == "itemSet" and item.itemSet and #item.itemSet > 0 then
        charCount = charCount + 1
    end
    
    return creatureCount, charCount
end

local function ShouldBeFeatured(item)
    if not item then 
        return false 
    end
    
    if item.cardType == "featured" then 
        return true 
    end
    if item.cardType == "grid" then 
        return false 
    end
    
    local creatureCount, charCount = Count3DModels(item)
    local totalModels = creatureCount + charCount
    
    if creatureCount > 0 and charCount > 0 then
        return true
    end
    
    if creatureCount > 0 then
        if creatureCount == 1 then
            return false
        else
            return true
        end
    end
    
    if charCount > 0 then
        if charCount == 1 then
            return false
        else
            return true
        end
    end
    
    return false
end

function RefreshCatalog(preserveScroll)
    if packageDetailsMode and currentPackageItem then
        RenderPackageDetailsView(currentPackageItem)
        return
    end

    local previousScroll = preserveScroll and GetCatalogScrollValue() or 0

    BackButton:Hide()
    ClearRewardCards()
    
    -- Asegurar que el ScrollFrame
    ScrollFrame:ClearAllPoints()
    ScrollFrame:SetPoint("TOPLEFT", 16, -60)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 18)
    
    -- Asegurar que el divisor
    LeftPanelDivider:ClearAllPoints()
    LeftPanelDivider:SetPoint("TOPLEFT", 18, -42)
    LeftPanelDivider:SetPoint("TOPRIGHT", -18, -42)
    
    -- Asegurar que el título y posiciones están correctos cuando no es modo paquete
    LeftTitle:ClearAllPoints()
    LeftTitle:SetPoint("TOPLEFT", 18, -10)
    LeftTitle:SetText(string.upper(currentCategory or "DESTACADO"))
    LeftTitle:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
    
    LeftSubtitle:ClearAllPoints()
    LeftSubtitle:SetPoint("TOPLEFT", 18, -48)
    LeftSubtitle:SetText("")
    
    LeftDescription:ClearAllPoints()
    LeftDescription:SetPoint("TOPLEFT", 18, -66)
    LeftDescription:SetWidth(520)
    LeftDescription:SetJustifyH("LEFT")
    LeftDescription:SetText("")


    
    for i=1,#FeaturedCards do FeaturedCards[i]:Hide() ; FeaturedCards[i].itemData=nil end
    for i=1,#GridCards     do GridCards[i]:Hide()      ; GridCards[i].itemData=nil      end
    
    local CARD_H      = 220
    local FEATURED_H  = 300
    local CARD_W      = 154
    local FEATURED_W  = 490
    local GAP         = 10
    local COL_SPACING = CARD_W + GAP
    local y           = -20
	local featuredIndex = 1
	local gridIndex     = 1
	local allItems = {}
	local snapPoints = {0}
	local currentOffset = 0
    
    if currentLayoutType=="featured_grid" and featuredEntry then
        if ShouldBeFeatured(featuredEntry) then
            featuredEntry.cardType = "featured"
            table.insert(allItems, featuredEntry)
        else
            featuredEntry.cardType = "grid"
        end
    end
    
    for _, item in ipairs(GetFilteredProducts()) do
        table.insert(allItems, item)
    end
    local rows = {}
    local pendingGrid = {}
    
    for _, item in ipairs(allItems) do
        local isFeaturedCard = ShouldBeFeatured(item)
        
        if isFeaturedCard then
            if #pendingGrid > 0 then
                table.insert(rows, {type="grid", items=pendingGrid})
                pendingGrid = {}
            end
            table.insert(rows, {type="featured", item=item})
        else
            table.insert(pendingGrid, item)
            if #pendingGrid == 3 then
                table.insert(rows, {type="grid", items=pendingGrid})
                pendingGrid = {}
            end
        end
    end
    if #pendingGrid > 0 then
        table.insert(rows, {type="grid", items=pendingGrid})
    end
    
			for rowIndex, row in ipairs(rows) do
			if row.type == "featured" then
				local card = FeaturedCards[featuredIndex]
				if card then
					card:ClearAllPoints()
					card:SetPoint("TOPLEFT", 0, y)

					FillCard(card, row.item, true)
					card:Show()
					featuredIndex = featuredIndex + 1
				end

				currentOffset = currentOffset + FEATURED_H + GAP
				table.insert(snapPoints, currentOffset)
				y = y - FEATURED_H - GAP
			else
				for col, item in ipairs(row.items) do
					local card = GridCards[gridIndex]
					if card then
						card:ClearAllPoints()
						card:SetPoint("TOPLEFT", (col-1) * COL_SPACING, y)

						FillCard(card, item, false)
						card:Show()
						gridIndex = gridIndex + 1
					end
				end

				currentOffset = currentOffset + CARD_H + GAP
				table.insert(snapPoints, currentOffset)
				y = y - CARD_H - GAP
			end
		end
    ScrollChild:SetHeight(math.abs(y) + 40)
	SetScrollSnapPoints(snapPoints)

    -- Aplicar scroll preservado AL FINAL, después de reconstruir todo
    local scrollBar = _G["FelStormStoreScrollFrameScrollBar"]
    if scrollBar then
        if preserveScroll then
            local maxScroll = ScrollFrame:GetVerticalScrollRange() or 0
            local target = previousScroll or 0
            if target < 0 then target = 0 end
            if target > maxScroll then target = maxScroll end

            -- Buscar el snap point más cercano
            local idx = GetNearestScrollSnapIndex(target)
            target = currentScrollSnapPoints[idx] or target

            if target > maxScroll then target = maxScroll end
            scrollBar:SetValue(target)
        else
            scrollBar:SetValue(0)
        end
    end
end

RightArrowButton:SetScript("OnClick", function() tabScrollOffset=math.min(maxTabScroll,tabScrollOffset+TAB_SCROLL_STEP) ; UpdateTabLayout() end)
LeftArrowButton:SetScript("OnClick",  function() tabScrollOffset=math.max(0,tabScrollOffset-TAB_SCROLL_STEP) ; UpdateTabLayout() end)

HeroArea:EnableMouse(true)
HeroArea:EnableMouseWheel(true)

HeroArea:SetScript("OnMouseDown", function(self, button)
    if activeHeroModelCount > 1 then return end

    if button == "LeftButton" then
        previewIsRotating = true
        previewLastX = GetCursorPosition()

    elseif button == "RightButton" then
        ResetSinglePreviewModel()
    end
end)

HeroArea:SetScript("OnMouseUp", function()
    previewIsRotating = false
end)

HeroArea:SetScript("OnLeave", function()
    previewIsRotating = false
end)

HeroArea:SetScript("OnUpdate", function()
    if not previewIsRotating then return end
    if activeHeroModelCount > 1 then return end
    if not activeHeroSingleModel then return end

    local x = GetCursorPosition()
    local diff = (x - previewLastX) * 0.006
    previewRotation = previewRotation + diff

    if activeHeroSingleModel.SetFacing then
        activeHeroSingleModel:SetFacing(previewRotation)
    end

    previewLastX = x
end)

HeroArea:SetScript("OnMouseWheel", function(self, delta)
    if activeHeroModelCount > 1 then return end

    local target = activeHeroSingleModel
    if not target then
        return
    end

    local objType = target:GetObjectType()
    if objType ~= "PlayerModel" and objType ~= "DressUpModel" then
        return
    end

    if delta > 0 then
        previewScale = math.min(CREATURE_PREVIEW_MAX_SCALE, previewScale + CREATURE_PREVIEW_STEP)
    else
        previewScale = math.max(CREATURE_PREVIEW_MIN_SCALE, previewScale - CREATURE_PREVIEW_STEP)
    end

    if target.SetModelScale then
        target:SetModelScale(previewScale)
    end
end)

SearchBox:SetScript("OnEditFocusGained", function() SearchLabel:Hide() end)
SearchBox:SetScript("OnEditFocusLost",   function(self) if self:GetText()=="" then SearchLabel:Show() end end)
SearchBox:SetScript("OnTextChanged", function(self)
    if self:GetText()=="" then SearchLabel:Show() else SearchLabel:Hide() end
    if not packageDetailsMode then RefreshCatalog() end
end)

local lastBuyClick = 0
local BUY_COOLDOWN = 2

BuyButton:SetScript("OnClick", function()
    local now = GetTime()
    if (now - lastBuyClick) < BUY_COOLDOWN then
        return
    end

    local buyTarget = nil
    if packageDetailsMode and currentPackageItem then
        buyTarget = currentPackageItem
    elseif selectedItem then
        buyTarget = selectedItem
    end

    if not buyTarget then
        return
    end

    local price = tonumber(buyTarget.price) or 0
    local itemName = buyTarget.name or "este artículo"
    local hasDiscount = (buyTarget.discount and buyTarget.discount > 0) or false
    local originalPrice = tonumber(buyTarget.originalPrice) or price

    local priceText = ""
    if hasDiscount and originalPrice > price then
        priceText = "|cff00ff00" .. price .. "|r   |cffff0000~~" .. originalPrice .. "~~|r"
    else
        priceText = tostring(price)
    end

    local msg = "¿Estás seguro de tu compra?\n\n"
        .. "Vas a gastar |cff00ff00" .. price .. "|r emblemas en:\n"
        .. "|cffffd24a" .. itemName .. "|r\n\n"
        .. "|cffff0000Recuerda que no hay reembolso.|r"

    ShowConfirmPopup("Confirmar compra", msg, function()
        lastBuyClick = now
        if packageDetailsMode and currentPackageItem then
            AIO.Handle("FelStormStore","BuyItemRequest",currentCategory,currentPackageItem.id)
        else
            AIO.Handle("FelStormStore","BuyItemRequest",currentCategory,selectedItem.id)
        end
    end)
end)


-- ============================================
-- POPUP DE CONFIRMACIÓN DE COMPRA/REGALO
-- ============================================

ConfirmPopup = CreateFrame("Frame", nil, MainFrame)
ConfirmPopup:SetSize(460, 260)
ConfirmPopup:SetPoint("CENTER", MainFrame, "CENTER", 0, 0)
ConfirmPopup:SetFrameStrata("DIALOG")
ConfirmPopup:SetFrameLevel(320)
ConfirmPopup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\border-tooltip-Noa",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left=10,right=10,top=12,bottom=12}
})
ConfirmPopup:SetBackdropColor(0.02,0.02,0.02,0.98)
ConfirmPopup:Hide()

ConfirmPopupTitle = ConfirmPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ConfirmPopupTitle:SetPoint("TOP", 0, -18)
ConfirmPopupTitle:SetText("")

ConfirmPopupText = ConfirmPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ConfirmPopupText:SetPoint("TOPLEFT", 24, -52)
ConfirmPopupText:SetPoint("TOPRIGHT", -24, -52)
ConfirmPopupText:SetJustifyH("CENTER")
ConfirmPopupText:SetJustifyV("TOP")
ConfirmPopupText:SetSpacing(4)
ConfirmPopupText:SetText("")

ConfirmPopupYesBtn = CreateFrame("Button", nil, ConfirmPopup, "UIPanelButtonTemplate")
ConfirmPopupYesBtn:SetSize(130, 28)
ConfirmPopupYesBtn:SetPoint("BOTTOMLEFT", 55, 22)
ConfirmPopupYesBtn:SetText("Sí, confirmar")
ConfirmPopupYesBtn:SetFrameLevel(ConfirmPopup:GetFrameLevel() + 5)
ConfirmPopupYesBtn:Raise()

ConfirmPopupNoBtn = CreateFrame("Button", nil, ConfirmPopup, "UIPanelButtonTemplate")
ConfirmPopupNoBtn:SetSize(130, 28)
ConfirmPopupNoBtn:SetPoint("BOTTOMRIGHT", -55, 22)
ConfirmPopupNoBtn:SetText("Cancelar")
ConfirmPopupNoBtn:SetFrameLevel(ConfirmPopup:GetFrameLevel() + 5)
ConfirmPopupNoBtn:Raise()

ConfirmPopupYesBtn:SetScript("OnClick", function()
    if ConfirmPopupCallback then
        ConfirmPopupCallback()
    end
    ConfirmPopup:Hide()
    ConfirmPopupCallback = nil
end)

ConfirmPopupNoBtn:SetScript("OnClick", function()
    ConfirmPopup:Hide()
    ConfirmPopupCallback = nil
end)

function ShowConfirmPopup(title, message, onConfirm)
    ConfirmPopupTitle:SetText(title or "Confirmar")
    ConfirmPopupText:SetText(message or "¿Estás seguro?")
    ConfirmPopupCallback = onConfirm
    ConfirmPopup:Show()
    ConfirmPopup:Raise()
    if ConfirmPopupYesBtn then ConfirmPopupYesBtn:Raise() end
    if ConfirmPopupNoBtn then ConfirmPopupNoBtn:Raise() end
end

function CloseConfirmPopup()
    ConfirmPopup:Hide()
    ConfirmPopupCallback = nil
end

-- ============================================
-- FUNCIONES PARA REGALOS
local function OpenGiftPopup()
    local giftTarget = nil

    if packageDetailsMode and currentPackageItem then
        giftTarget = currentPackageItem
    else
        giftTarget = selectedItem
    end

    if not giftTarget then
        return
    end

    if giftTarget.service then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[FelStorm Store]|r Los servicios no se pueden regalar.")
        return
    end

   local itemName = giftTarget.name or "este regalo"
if string.len(itemName) > 28 then
    itemName = string.sub(itemName, 1, 25) .. "..."
end

GiftPopupText:SetText("Escribe el nombre del personaje que recibirá\n|cffffd24a" .. itemName .. "|r.")
    GiftNameEditBox:SetText("")
    GiftPopup:Show()
    GiftNameEditBox:SetFocus()
end

local function CloseGiftPopup()
    if not GiftPopup then return end
    GiftPopup:Hide()
    if GiftNameEditBox then
        GiftNameEditBox:SetText("")
        GiftNameEditBox:ClearFocus()
    end
end

-- HANDLERS DE BOTONES DE REGALO
GiftButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Regalar este objeto", 1, 0.82, 0, 1)
    GameTooltip:Show()
end)

GiftButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

GiftButton:SetScript("OnClick", function()
    OpenGiftPopup()
end)

GiftCancelButton:SetScript("OnClick", function()
    CloseGiftPopup()
end)

GiftConfirmButton:SetScript("OnClick", function()
    local targetName = Trim(GiftNameEditBox:GetText() or "")
    if targetName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[FelStorm Store]|r Debes escribir un nombre de personaje.")
        return
    end

    local giftTarget = nil
    if packageDetailsMode and currentPackageItem then
        giftTarget = currentPackageItem
    else
        giftTarget = selectedItem
    end

    if not giftTarget then
        return
    end

    local price = tonumber(giftTarget.price) or 0
    local itemName = giftTarget.name or "este artículo"
    local hasDiscount = (giftTarget.discount and giftTarget.discount > 0) or false
    local originalPrice = tonumber(giftTarget.originalPrice) or price

    local priceText = ""
    if hasDiscount and originalPrice > price then
        priceText = "|cff00ff00" .. price .. "|r   |cffff0000~~" .. originalPrice .. "~~|r"
    else
        priceText = tostring(price)
    end

    local msg = "¿Estás seguro de enviar este regalo?\n\n"
        .. "Vas a gastar |cff00ff00" .. price .. "|r emblemas.\n"
        .. "El regalo |cffffd24a" .. itemName .. "|r\n"
        .. "será enviado a |cffffd24a" .. targetName .. "|r.\n\n"
        .. "|cffff0000Recuerda que no hay reembolso.|r"

    CloseGiftPopup()
    ShowConfirmPopup("Confirmar regalo", msg, function()
        AIO.Handle("FelStormStore", "GiftItemRequest", currentCategory, giftTarget.id, targetName)
    end)
end)

GiftNameEditBox:SetScript("OnEnterPressed", function()
    GiftConfirmButton:Click()
end)

GiftNameEditBox:SetScript("OnEscapePressed", function()
    CloseGiftPopup()
end)

function StoreHandlers.ShowStore(player)
    MainFrame:Show()
    currentCategory="Destacado"
    currentLayoutType="simple_grid"
    selectedItem=nil
    featuredEntry=nil
    productEntries={}
    editorialData=nil
    packageDetailsMode=false
    currentPackageItem=nil
    selectedRewardIndex=1
    selectedRewardData=nil
    
    ResetCategoryBackgroundSystem("Destacado")
    
    SearchBox:SetText("")
    SearchLabel:Show()
    tabScrollOffset=0
    UpdateCategoryButtonStates()
    UpdateTabLayout()
    ClearDetailPanel()
end

function StoreHandlers.LoadCategory(player, data, categoryName)
    currentCategory=tostring(categoryName or "Destacado")
    currentLayoutType=tostring((data and data.layoutType) or "simple_grid")
    featuredEntry=data and data.featured or nil
    productEntries=data and data.products or {}
    editorialData=data and data.editorial or nil
    packageDetailsMode=false
    currentPackageItem=nil
    selectedRewardIndex=1
    selectedRewardData=nil
    UpdateCategoryButtonStates()
    UpdateTabLayout()
    RefreshCatalog()
end

function StoreHandlers.ReceiveSelectedItem(player, item)
    if item and item.service then
        if (not item.icon or item.icon == "") and item.heroTexture and item.heroTexture ~= "" then
            local iconName = string.match(item.heroTexture, "Interface\\Icons\\(.+)")
            if iconName then
                item.icon = iconName
            end
        end

        if not item.icon or item.icon == "" then
            item.icon = "INV_Misc_Gear_01"
            item.heroTexture = "Interface\\Icons\\INV_Misc_Gear_01"
        end
    end

    packageDetailsMode = false
    currentPackageItem = nil
    selectedRewardIndex = 1
    selectedRewardData = nil

    RenderSelectedItem(item)
    RefreshCatalogSelectionOnly()
end

function StoreHandlers.UpdateCurrency(player, amount, currencyId)
    currentCurrencyAmount=tonumber(amount) or 0
    STORE_CURRENCY_ID=tonumber(currencyId) or 49426
    CurrencyIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    CurrencyText:SetText(tostring(currentCurrencyAmount))
    PriceIcon:SetTexture(GetItemIcon(STORE_CURRENCY_ID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    PlaySound("igBackPackCoinSelect")
    
    RefreshCatalog(true)
    if packageDetailsMode and selectedRewardData then
        RenderSelectedReward(selectedRewardData)
    elseif selectedItem then
        RenderSelectedItem(selectedItem)
    end
end

function StoreHandlers.BuyResponse(player, success, message)
    if success then
        local finalMessage = message or "Compra realizada con éxito. El artículo fue enviado a tu buzón."
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FelStorm Store]|r " .. finalMessage)
        UIErrorsFrame:AddMessage(finalMessage, 1.0, 0.82, 0.0, 1.0)
        PlaySound("TellMessage")
        PlaySoundFile("Sound\\Interface\\AuctionWindowOpen.wav")
    else
        local finalMessage = message or "No se pudo completar la compra"
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[FelStorm Store]|r " .. finalMessage)
        UIErrorsFrame:AddMessage(finalMessage, 1.0, 0.1, 0.1, 1.0)
        PlaySoundFile("Sound\\Interface\\Error.wav")
    end
end

function StoreHandlers.GiftResponse(player, success, message)
    if success then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FelStorm Store]|r "..(message or "Regalo enviado con éxito"))
        PlaySoundFile("Sound\\Interface\\AuctionWindowOpen.wav")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[FelStorm Store]|r "..(message or "No se pudo enviar el regalo"))
        PlaySoundFile("Sound\\Interface\\Error.wav")
    end
end

MainFrame:SetScript("OnHide", function()
    previewIsRotating = false
end)

MainFrame:SetScript("OnShow", function()
    local pd = GetActivePreviewData()
    if pd and pd.previewType == "creature3D" and pd.creatureid then
        local adj = GetCreatureAdjustment(pd.creatureid)
        previewRotation = adj.facing or 0.20
        previewPosX     = adj.x     or 0.0
        previewPosY     = adj.y     or 0.0
        previewPosZ     = adj.z     or 2.10
        previewScale    = adj.scale or 0.80
    end
    if PurchaseBox then PurchaseBox:Raise() end
    UpdateTabLayout()
end)

BackButton:SetScript("OnClick", function() ExitPackageDetailsView() end)

DetailsButton:SetScript("OnClick", function()
    if selectedItem and selectedItem.entryType=="package" then
        RenderPackageDetailsView(selectedItem)
    end
end)

UpdateCategoryButtonStates()
UpdateTabLayout()
ClearDetailPanel()

function ToggleStoreUI()
    if MainFrame:IsShown() then MainFrame:Hide() else AIO.Handle("FelStormStore", "RequestOpenStore") end
end

local function HookGameMenuButtonStore()
    local btn = _G["GameMenuButtonStore"]
    if not btn then return end
    btn:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(GameMenuFrame)
        ToggleStoreUI()
    end)
end

local gameMenuLoader = CreateFrame("Frame")
gameMenuLoader:RegisterEvent("PLAYER_LOGIN")
gameMenuLoader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        HookGameMenuButtonStore()
    end
end)

SlashCmdList["FELSTORMSTORE"] = ToggleStoreUI
MainFrame:Hide()