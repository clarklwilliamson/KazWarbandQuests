-- KazWarbandQuests: Makes Dugi treat warband-completed quests as done
-- Hooks C_QuestLog.IsQuestFlaggedCompleted so ALL code paths (Dugi's
-- direct API calls + wrapper) return true for warband-completed quests.
-- Toggle: /kwbq or /kaz warband

local addonName = ...
local KazUtil = LibStub("KazUtil-1.0")
local Print = KazUtil.CreatePrinter("KazWarbandQuests")
local enabled = true

-- Hook the Blizzard API directly — Dugi calls it in 7+ places, not just
-- through IsQuestTurnedIn. This catches every code path.
local origIsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = function(questId)
    -- Profession KP quests: per-character, NOT warband.
    -- In 12.0, origIsQuestFlaggedCompleted includes account-wide flags,
    -- so profession quests show as done on alts. Use our own per-character
    -- tracking (KAZ_CHAR_QUEST_DONE from KazWeeklyKnowledge) instead.
    if questId and KAZ_PROFESSION_QUEST_IDS and KAZ_PROFESSION_QUEST_IDS[questId] then
        if KAZ_CHAR_QUEST_DONE and KAZ_CHAR_QUEST_DONE[questId] then
            return true
        end
        return false
    end
    if origIsQuestFlaggedCompleted(questId) then
        return true
    end
    if enabled and questId then
        -- Skip campaign quests — character-specific progression chain
        if C_CampaignInfo and C_CampaignInfo.IsCampaignQuest(questId) then
            return false
        end
        return C_QuestLog.IsQuestFlaggedCompletedOnAccount(questId)
    end
    return false
end

local frame, handlers, register = KazUtil.CreateEventHandler()

function handlers.ADDON_LOADED(addon)
    if addon ~= addonName then return end
    local db = KazUtil.InitDB("KazWarbandQuestsDB", { enabled = true })
    enabled = db.enabled
    frame:UnregisterEvent("ADDON_LOADED")
end

register("ADDON_LOADED")

-- Slash commands
local function PrintStatus()
    local state = enabled and "|cff00ff00ON|r" or "|cffff4444OFF|r"
    Print(state .. " — warband-completed quests count as done")
end

SLASH_KAZWARBANDQUESTS1 = "/kwbq"
SlashCmdList["KAZWARBANDQUESTS"] = function(msg)
    local cmd = KazUtil.ParseCommand(msg)
    if cmd == "on" then
        enabled = true
        KazWarbandQuestsDB.enabled = true
        PrintStatus()
    elseif cmd == "off" then
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
