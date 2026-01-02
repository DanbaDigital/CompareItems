-- CompareItems Addon for WoW Vanilla
-- Shows equipped items in tooltips when hovering over items

local function print_msg(msg)
    DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE .. "<CompareItems> " .. msg)
end

-- Test if file is loading
if DEFAULT_CHAT_FRAME then
    print_msg("FILE LOADING - DEFAULT_CHAT_FRAME exists")
else
    print("ERROR: DEFAULT_CHAT_FRAME does not exist!")
end

local frame = CreateFrame("Frame")
print_msg("Frame created")

frame:RegisterEvent("VARIABLES_LOADED")
print_msg("Registered VARIABLES_LOADED")

frame:RegisterEvent("ADDON_LOADED")
print_msg("Registered ADDON_LOADED")

frame:SetScript("OnEvent", function(self)
    print_msg("EVENT FIRED: " .. tostring(event) .. " arg1=" .. tostring(arg1))
    if event == "ADDON_LOADED" and arg1 == "CompareItems" then
        print_msg(">>> ADDON_LOADED CompareItems triggered")
    elseif event == "VARIABLES_LOADED" then
        print_msg(">>> VARIABLES_LOADED triggered - calling Init")
        CompareItems_Init()
    end
end)

print_msg("Event handler setup complete")

function CompareItems_Init()
    -- Hook SetHyperlink (used when showing items by link)
    origSetHyperlink = GameTooltip.SetHyperlink
    GameTooltip.SetHyperlink = function(self, link)
        origSetHyperlink(self, link)
        if link then
            CompareItems_AddEquippedInfo(self, link)
        end
    end

    -- Hook SetBagItem (used when hovering over bag items)
    origSetBagItem = GameTooltip.SetBagItem
    GameTooltip.SetBagItem = function(self, bag, slot)
        local link = GetContainerItemLink(bag, slot)
        origSetBagItem(self, bag, slot)
        if link then
            CompareItems_AddEquippedInfo(self, link)
        end
    end

    -- Hook SetItem (used for equipment)
    origSetItem = GameTooltip.SetItem
    GameTooltip.SetItem = function(self, itemID)
        origSetItem(self, itemID)
    end

    print_msg("CompareItems initialized")
end

function CompareItems_AddEquippedInfo(tooltip, link)
    local itemInfo = GetItemInfo(link)
    if not itemInfo then
        print_msg("GetItemInfo returned nil for: " .. tostring(link))
        return
    end
    
    -- Try to unpack the return values properly
    local name = itemInfo[1]
    local itemLink = itemInfo[2]
    local quality = itemInfo[3]
    local iLevel = itemInfo[4]
    local reqLevel = itemInfo[5]
    local itemType = itemInfo[6]
    local subType = itemInfo[7]
    local stackCount = itemInfo[8]
    local equipSlot = itemInfo[9]
    
    print_msg("GetItemInfo: name=" .. tostring(name) .. " equipSlot=" .. tostring(equipSlot))
    
    if not equipSlot or equipSlot == "" then 
        print_msg("No equipSlot for: " .. tostring(name))
        return 
    end

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
        ["INVTYPE_WEAPON"] = {16, 17},
        ["INVTYPE_2HWEAPON"] = {16},
        ["INVTYPE_SHIELD"] = {17},
        ["INVTYPE_HOLDABLE"] = {17},
        ["INVTYPE_RANGED"] = {18},
        ["INVTYPE_TABARD"] = {19},
    }

    local slots = slotMap[equipSlot]
    if not slots then 
        print_msg("No slots mapped for: " .. tostring(equipSlot))
        return 
    end

    print_msg("Adding equipped items to tooltip")
    tooltip:AddLine(" ")
    tooltip:AddLine("Equipped:", 1, 1, 0)
    for _, slot in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slot)
        if equippedLink then
            local equippedName = GetItemInfo(equippedLink)
            print_msg("Slot " .. slot .. ": " .. tostring(equippedName))
            tooltip:AddLine(equippedName, 1, 1, 1)
        else
            print_msg("Slot " .. slot .. ": empty")
            tooltip:AddLine("None", 0.5, 0.5, 0.5)
        end
    end
end