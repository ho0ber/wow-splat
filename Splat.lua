local recent = {}
local last_timestamp = 0
local debug = false

local MSG_SAVE = "Saving information for %s in case they die..."
local MSG_DIED = "%s went splat!"
local SOUND_CHANNELS = {"Master", "SFX"}

local function debugPrint(...)
    if debug or (splatSettings ~= nil and splatSettings["debugMessages"]) then
        print(...)
    end
end

local function splat(destName)
    local sounds = {2907665, 2907666, 2907667, 2907668, 2907669}
    if splatSettings["chatMessage"] ~= false then
        print(MSG_DIED:format(destName))
    end
    if splatSettings["soundChannel"] ~=3 then
        debugPrint("Playing in sound channel", SOUND_CHANNELS[splatSettings["soundChannel"]])
        PlaySoundFile(sounds[ math.random( #sounds ) ], SOUND_CHANNELS[splatSettings["soundChannel"]])
    end
end

local function OnSettingChanged(setting, value)
    debugPrint("Setting changed:", setting:GetVariable(), tostring(value))
end

local function configureSettings() 
    local category = Settings.RegisterVerticalLayoutCategory("Splat")
    
    do
        local variable = "chatMessage"
        local name = "Chat Message"
        local tooltip = "Show a message in chat when someone splats"
        local variableKey = "chatMessage"
        local variableTbl = splatSettings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    
    do
        local variable = "soundChannel"
        local defaultValue = 1
        local name = "Sound Channel"
        local tooltip = "Which sound channel the splat sound uses"
        local variableKey = "soundChannel"
        local variableTbl = splatSettings
    
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(1, "Master")
            container:Add(2, "SFX")
            container:Add(3, "Disabled")
            return container:GetData()
        end
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateDropdown(category, setting, GetOptions, tooltip)
    end

    do
        local variable = "debugMessages"
        local name = "Show Debug Message"
        local tooltip = "Shows debug messages for addon troubleshooting"
        local variableKey = "debugMessages"
        local variableTbl = splatSettings
        local defaultValue = false
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    Settings.RegisterAddOnCategory(category)
end    

local function OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
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
                splat(destName)
                recent[destGUID] = nil
            end
        end
    elseif event == "ADDON_LOADED" then
        local addon = ...
        if addon == "Splat" then
            if splatSettings == nil then
                splatSettings = {}
            end
            configureSettings()
            debugPrint("Loaded Splat!")
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)
