-- KazWarbandQuests: Makes Dugi treat warband-completed quests as done
-- Hooks C_QuestLog.IsQuestFlaggedCompleted so ALL code paths (Dugi's
-- direct API calls + wrapper) return true for warband-completed quests.
-- Toggle: /kwbq or /kaz warband

local addonName = ...
local enabled = true

-- Hook the Blizzard API directly — Dugi calls it in 7+ places, not just
-- through IsQuestTurnedIn. This catches every code path.
local origIsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = function(questId)
    if origIsQuestFlaggedCompleted(questId) then
        return true
    end
    if enabled and questId then
        -- Skip profession KP quests — they're per-character, every crafter
        -- needs to do them even if another toon already completed them
        if KAZ_PROFESSION_QUEST_IDS and KAZ_PROFESSION_QUEST_IDS[questId] then
            return false
        end
        return C_QuestLog.IsQuestFlaggedCompletedOnAccount(questId)
    end
    return false
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addon)
    if addon ~= addonName then return end

    -- SavedVariables
    KazWarbandQuestsDB = KazWarbandQuestsDB or { enabled = true }
    enabled = KazWarbandQuestsDB.enabled

    f:UnregisterEvent("ADDON_LOADED")
end)

-- Slash commands
local function PrintStatus()
    local state = enabled and "|cff00ff00ON|r" or "|cffff4444OFF|r"
    print("|cffC8AA64KazWarbandQuests:|r " .. state .. " — warband-completed quests count as done")
end

SLASH_KAZWARBANDQUESTS1 = "/kwbq"
SlashCmdList["KAZWARBANDQUESTS"] = function(msg)
    msg = strtrim(msg):lower()
    if msg == "on" then
        enabled = true
        KazWarbandQuestsDB.enabled = true
        PrintStatus()
    elseif msg == "off" then
        enabled = false
        KazWarbandQuestsDB.enabled = false
        PrintStatus()
    else
        enabled = not enabled
        KazWarbandQuestsDB.enabled = enabled
        PrintStatus()
    end
end

-- Register with /kaz dispatcher
if KAZ_COMMANDS then
    KAZ_COMMANDS["warband"] = {
        handler = function(args) SlashCmdList["KAZWARBANDQUESTS"](args) end,
        alias = "/kwbq",
        desc = "Toggle warband quest completion in Dugi",
    }
end
