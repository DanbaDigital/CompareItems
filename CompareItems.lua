-- CompareItems Addon for WoW Vanilla
-- Allows comparing items by holding shift while hovering over items in bags

local addonName = "CompareItems"

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == addonName then
        -- Initialize the addon
        CompareItems_Init()
    end
end)

function CompareItems_Init()
    -- Create comparison tooltip
    ComparisonTooltip = CreateFrame("GameTooltip", "CompareItemsTooltip", UIParent, "GameTooltipTemplate")
    ComparisonTooltip:SetFrameStrata("DIALOG")  -- Higher strata to ensure visibility

    -- Hook GameTooltip's OnTooltipSetItem
    local origOnTooltipSetItem = GameTooltip:GetScript("OnTooltipSetItem")
    GameTooltip:SetScript("OnTooltipSetItem", function(self)
        -- Call original function
        if origOnTooltipSetItem then
            origOnTooltipSetItem(self)
        end

        -- Check if shift is held
        if IsShiftKeyDown() then
            local name, link = self:GetItem()
            if link then
                local slots = CompareItems_GetSlotForItem(link)
                if slots then
                    for _, slot in ipairs(slots) do
                        local equippedLink = GetInventoryItemLink("player", slot)
                        if equippedLink then
                            DEFAULT_CHAT_FRAME:AddMessage("CompareItems: Showing comparison for slot " .. slot)
                            CompareItems_ShowComparisonTooltip(equippedLink)
                            break  -- Show the first equipped item
                        end
                    end
                else
                    DEFAULT_CHAT_FRAME:AddMessage("CompareItems: No slots found for item")
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("CompareItems: No item link found")
            end
        end
    end)

    -- Hook OnHide to hide comparison tooltip
    local origOnHide = GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide", function(self)
        if origOnHide then
            origOnHide(self)
        end
        CompareItems_HideComparisonTooltip()
    end)
end

function CompareItems_GetSlotForItem(link)
    local equipLoc = select(9, GetItemInfo(link))
    if not equipLoc then return nil end

    local slotMap = {
        ["INVTYPE_HEAD"] = {1},
        ["INVTYPE_NECK"] = {2},
        ["INVTYPE_SHOULDER"] = {3},
        ["INVTYPE_BODY"] = {4},
        ["INVTYPE_CHEST"] = {5},
        ["INVTYPE_WAIST"] = {6},
        ["INVTYPE_LEGS"] = {7},
        ["INVTYPE_FEET"] = {8},
        ["INVTYPE_WRIST"] = {9},
        ["INVTYPE_HAND"] = {10},
        ["INVTYPE_FINGER"] = {11, 12},
        ["INVTYPE_TRINKET"] = {13, 14},
        ["INVTYPE_BACK"] = {15},
        ["INVTYPE_WEAPON"] = {16, 17},  -- One-hand weapons can go in main or off-hand
        ["INVTYPE_2HWEAPON"] = {16},     -- Two-hand weapons
        ["INVTYPE_SHIELD"] = {17},
        ["INVTYPE_HOLDABLE"] = {17},
        ["INVTYPE_RANGED"] = {18},
        ["INVTYPE_TABARD"] = {19},
    }

    return slotMap[equipLoc]
end

function CompareItems_ShowComparisonTooltip(link)
    ComparisonTooltip:SetOwner(GameTooltip, "ANCHOR_LEFT")
    ComparisonTooltip:SetHyperlink(link)
    ComparisonTooltip:Show()
end

function CompareItems_HideComparisonTooltip()
    ComparisonTooltip:Hide()
end