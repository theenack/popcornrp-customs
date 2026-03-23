local installMod = require('client.utils.installMod')
local neonMenuId = 'customs-neon'

local registerNeonContext -- forward declaration

registerNeonContext = function()
    local options = {}

    -- 4 neon position toggles
    for i = 1, 4 do
        local neonPos = i - 1 -- 0-indexed for native calls
        local enabled = IsVehicleNeonLightEnabled(vehicle, neonPos)
        local posLabel = Config.Neon[i].label
        local subContextId = ('%s-pos-%d'):format(neonMenuId, i)

        lib.registerContext({
            id = subContextId,
            title = ('Neon %s'):format(posLabel),
            menu = neonMenuId,
            onExit = onCustomsExit,
            options = {
                {
                    title = (not enabled) and '✓ Disabled' or 'Disabled',
                    onSelect = function()
                        local prev = IsVehicleNeonLightEnabled(vehicle, neonPos)
                        SetVehicleNeonLightEnabled(vehicle, neonPos, false)
                        local success = installMod(prev == false, 'colors', {
                            description = ('Neon %s disabled'):format(posLabel),
                        })
                        if not success then SetVehicleNeonLightEnabled(vehicle, neonPos, prev) end
                        registerNeonContext()
                        lib.showContext(neonMenuId)
                    end,
                },
                {
                    title = enabled and '✓ Enabled' or 'Enabled',
                    onSelect = function()
                        local prev = IsVehicleNeonLightEnabled(vehicle, neonPos)
                        SetVehicleNeonLightEnabled(vehicle, neonPos, true)
                        local success = installMod(prev == true, 'colors', {
                            description = ('Neon %s enabled'):format(posLabel),
                        })
                        if not success then SetVehicleNeonLightEnabled(vehicle, neonPos, prev) end
                        registerNeonContext()
                        lib.showContext(neonMenuId)
                    end,
                },
            },
        })

        options[#options + 1] = {
            title = ('Neon %s'):format(posLabel),
            description = ('%s | %s%s'):format(
                enabled and 'Enabled' or 'Disabled',
                Config.Currency, Config.Prices['colors']
            ),
            onSelect = function()
                lib.showContext(subContextId)
            end,
        }
    end

    -- Neon color
    local r, g, b = GetVehicleNeonLightsColour(vehicle)
    local currentColorIndex = 1
    for i, v in ipairs(Config.NeonColors) do
        if v.r == r and v.g == g and v.b == b then
            currentColorIndex = i
            break
        end
    end

    local colorSubId = neonMenuId .. '-color'
    local colorSubOptions = {}
    for i, colorData in ipairs(Config.NeonColors) do
        local index = i
        local isCurrent = (i == currentColorIndex)
        colorSubOptions[#colorSubOptions + 1] = {
            title = isCurrent and ('✓ %s'):format(colorData.label) or colorData.label,
            onSelect = function()
                local prevR, prevG, prevB = GetVehicleNeonLightsColour(vehicle)
                SetVehicleNeonLightsColour(vehicle, colorData.r, colorData.g, colorData.b)
                local success = installMod(currentColorIndex == index, 'colors', {
                    description = ('%s neon installed'):format(colorData.label),
                })
                if not success then
                    SetVehicleNeonLightsColour(vehicle, prevR, prevG, prevB)
                end
                registerNeonContext()
                lib.showContext(neonMenuId)
            end,
        }
    end

    lib.registerContext({
        id = colorSubId,
        title = 'Neon color',
        menu = neonMenuId,
        onExit = onCustomsExit,
        options = colorSubOptions,
    })

    local currentColorLabel = Config.NeonColors[currentColorIndex] and Config.NeonColors[currentColorIndex].label or 'Unknown'
    options[#options + 1] = {
        title = 'Neon color',
        description = ('%s | %s%s'):format(
            currentColorLabel,
            Config.Currency, Config.Prices['colors']
        ),
        onSelect = function()
            lib.showContext(colorSubId)
        end,
    }

    lib.registerContext({
        id = neonMenuId,
        title = 'Neon',
        menu = 'customs-colors',
        onExit = onCustomsExit,
        options = options,
    })
end

return function()
    registerNeonContext()
    return neonMenuId
end
