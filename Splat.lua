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
    PlaySoundFile(sounds[ math.random( #sounds ) ], "Master")
end

local function OnSettingChanged(setting, value)
    -- This callback will be invoked whenever a setting is modified.
    print("Setting changed:", setting:GetVariable(), value)
end

local function configureSettings() 
    local category = Settings.RegisterVerticalLayoutCategory("Splat")
    
    do
        local variable = "toggle"
        local name = "Test Checkbox"
        local tooltip = "This is a tooltip for the checkbox."
        local variableKey = "toggle"
        local variableTbl = splatSettings
        local defaultValue = false
    
        -- local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
        -- Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
    end
    
    do
        local variable = "slider"
        local name = "Test Slider"
        local tooltip = "This is a tooltip for the slider."
        local variableKey = "slider"
        local variableTbl = splatSettings
        local defaultValue = 180
        local minValue = 90
        local maxValue = 360
        local step = 10
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateSlider(category, setting, options, tooltip)
        -- Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
    end
    
    do
        local variable = "selection"
        local defaultValue = 2  -- Corresponds to "Option 2" below.
        local name = "Test Dropdown"
        local tooltip = "This is a tooltip for the dropdown."
        local variableKey = "selection"
        local variableTbl = splatSettings
    
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(1, "Option 1")
            container:Add(2, "Option 2")
            container:Add(3, "Option 3")
            return container:GetData()
        end
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateDropdown(category, setting, GetOptions, tooltip)
        -- Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
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
                print(MSG_DIED:format(destName))
                splat()
                recent[destGUID] = nil
            end
        end
    elseif event == "ADDON_LOADED" then
        local addon = ...
        print("Loaded", addon)
        if addon == "Splat" then
            print("Splat loaded!")
            -- if splatSettings == nil then
            --     splatSettings = {}
            -- end
            splatSettings = {}
            configureSettings()
            print(splatSettings[toggle])
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)
debugPrint("Loaded Splat!")
