local recent = {}
local last_timestamp = 0
local debug = false
local MSG_SAVE = "Saving information for %s in case they die..."
local MSG_DIED = "%s went splat!"

local function debugPrint(message)
    if debug then
        print(message)
    end
end

local function splat()
    local sounds = {2907665, 2907666, 2907667, 2907668, 2907669}
    PlaySoundFile(sounds[ math.random( #sounds ) ])
end

local function OnEvent(self, event)
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, recapID = CombatLogGetCurrentEventInfo()

    if subevent == "ENVIRONMENTAL_DAMAGE" then
        debugPrint(CombatLogGetCurrentEventInfo())
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, environmentalType, _, _, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = CombatLogGetCurrentEventInfo()
        if environmentalType == "Falling" then
            debugPrint(MSG_SAVE:format(destName))
            if (timestamp - last_timestamp) > 60 then
                debugPrint("Garbage collecting old events.")
                recent = {}
            end
            last_timestamp = timestamp
            recent[destGUID] = timestamp
        end
    end

    if subevent == "UNIT_DIED" then
        debugPrint(CombatLogGetCurrentEventInfo())
        if debug then
            for k, v in pairs(recent) do
                print(k, v)
            end
        end
        
        if recent[destGUID] == timestamp then
            print(MSG_DIED:format(destName))
            splat()
            recent[destGUID] = nil
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", OnEvent)
debugPrint("Loaded Splat!")
