local NewTimer, UnitAura, GetTime, table = C_Timer.NewTimer, UnitAura, GetTime, table
local MSG_ADDON = "CHAT_MSG_ADDON"
local MSG_BN_ADDON = "BN_CHAT_MSG_ADDON"
local DBM_PREFIX = "D4"
local DBM_PULLTIMER_MESSAGE = "PT"
local SPELL_ASPECT_PACK = "Aspect of the Pack"

local enabled = true
local mainFrame = CreateFrame("Frame")
local ticker
local spamTick = 1
local timerEnd

local function cancelSpam()
    if not ticker then return end

    ticker:Cancel()
    ticker = nil
end

local function packBuffers()
    local buffers = {}
    for i=1,40 do
        local _, _, _, _, _, _, _, unitCaster, _, _, spellId = UnitAura("unit", SPELL_ASPECT_PACK)
        if unitCaster then
            table.insert(buffers, unitCaster)
        end
    end

    return buffers
end

local function doSpam()
    if not enabled or GetTime() > timerEnd then
        cancelSpam()
        return
    end

    local buffers = packBuffers()
    if #buffers == 0 then
        cancelSpam()
        return
    end

    buffers = table.concat(buffers, " ")

    local msg = ">> PLUTOPLS " .. buffers .. " <<"
    print(msg)
    SendChatMessage(msg, "RAID_WARNING")

    ticker = NewTimer(spamTick, doSpam)
end

local function startSpam(timer)
    if ticker then return end

    local buffers = packBuffers()
    if #buffers == 0 then
        return
    end

    ticker = NewTimer(spamTick, doSpam)
end

local function handlePullTimer(sender, message, timer)
    local DBM = _G.DBM

    -- DBM validation from DBM core
    if message ~= DBM_PULLTIMER_MESSAGE then return end
    if not DBM then return end
    if select(2, IsInInstance()) == "pvp" or IsEncounterInProgress() then
        return
    end

    timer = tonumber(timer or 0)
    if timer > 60 then
        return
    end

    print("WE HAVE A TIMER OMG " .. timer)

    if timer == 0 then
        cancelSpam()
    else
        timerEnd = GetTime() + timer
        startSpam()
    end
end

local function OnEvent(self, event, prefix, message, channel, sender, ...)
    -- Conditions to ignore on
    if not enabled then return end
    if prefix ~= DBM_PREFIX then return end
    if event ~= MSG_ADDON and event ~= MSG_BN_ADDON then return end

    handlePullTimer(sender, strsplit("\t", message))
end

do
    -- Register the DBM timer event
    mainFrame:SetScript("OnEvent", OnEvent)
    mainFrame:RegisterEvent(MSG_ADDON)
    mainFrame:RegisterEvent(MSG_BN_ADDON)

    _G.SLASH_PLUTOPLS1,  _G.SLASH_PLUTOPLS2 = "/plutopls", "/pls"
    function SlashCmdList.PLUTOPLS()
        enabled = not enabled
        print("PlutoPls has been " .. (enabled and 'enabled' or 'disabled'))
    end
end

