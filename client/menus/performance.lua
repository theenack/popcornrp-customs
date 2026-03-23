local getModLabel = require('client.utils.getModLabel')
local VehicleClass = require('client.utils.enums.VehicleClass')
local installMod = require('client.utils.installMod')
local performanceMenuId = 'customs-performance'

local function priceLabel(price)
    if type(price) ~= 'table' then
        return ('%s%s'):format(Config.Currency, price)
    end
    local copy = table.clone(price)
    table.remove(copy, 1)
    for i = 1, #copy do
        copy[i] = ('%d: %s%s'):format(i, Config.Currency, copy[i])
    end
    return table.concat(copy, ' | ')
end

local registerPerformanceContext -- forward declaration

registerPerformanceContext = function()
    local options = {}

    for _, mod in ipairs(Config.Mods) do
        local modCount = GetNumVehicleMods(vehicle, mod.id)
        if mod.category ~= 'performance'
            or mod.enabled == false
            or modCount == 0
        then
            goto continue
        end

        local modLabels = { 'Stock' }
        for i = -1, modCount - 1 do
            modLabels[i + 2] = getModLabel(vehicle, mod.id, i)
        end

        local currentMod = GetVehicleMod(vehicle, mod.id)
        local currentLabel = modLabels[currentMod + 2] or 'Stock'
        local subContextId = ('%s-%d'):format(performanceMenuId, mod.id)

        local subOptions = {}
        for i, label in ipairs(modLabels) do
            local index = i
            local modIndex = index - 2
            local isCurrent = modIndex == currentMod
            subOptions[#subOptions + 1] = {
                title = isCurrent and ('✓ %s'):format(label) or label,
                onSelect = function()
                    local prevMod = GetVehicleMod(vehicle, mod.id)
                    SetVehicleMod(vehicle, mod.id, modIndex, false)
                    local success = installMod(prevMod == modIndex, mod.id, {
                        description = ('%s installed'):format(label),
                    }, index)
                    if not success then
                        SetVehicleMod(vehicle, mod.id, prevMod, false)
                    end
                    registerPerformanceContext()
                    lib.showContext(performanceMenuId)
                end,
            }
        end

        lib.registerContext({
            id = subContextId,
            title = mod.label,
            menu = performanceMenuId,
            onExit = onCustomsExit,
            options = subOptions,
        })

        options[#options + 1] = {
            title = mod.label,
            description = ('%s | %s'):format(currentLabel, priceLabel(Config.Prices[mod.id])),
            onSelect = function()
                lib.showContext(subContextId)
            end,
        }

        ::continue::
    end

    -- Turbo
    if GetVehicleClass(vehicle) ~= VehicleClass.Cycles then
        local turboEnabled = IsToggleModOn(vehicle, 18)
        local turboSubId = performanceMenuId .. '-turbo'

        lib.registerContext({
            id = turboSubId,
            title = 'Turbo',
            menu = performanceMenuId,
            onExit = onCustomsExit,
            options = {
                {
                    title = (not turboEnabled) and '✓ Disabled' or 'Disabled',
                    onSelect = function()
                        local prev = IsToggleModOn(vehicle, 18)
                        ToggleVehicleMod(vehicle, 18, false)
                        local success = installMod(prev == false, 18, {
                            description = 'Turbo disabled',
                        }, 1)
                        if not success then ToggleVehicleMod(vehicle, 18, prev) end
                        registerPerformanceContext()
                        lib.showContext(performanceMenuId)
                    end,
                },
                {
                    title = turboEnabled and '✓ Enabled' or 'Enabled',
                    onSelect = function()
                        local prev = IsToggleModOn(vehicle, 18)
                        ToggleVehicleMod(vehicle, 18, true)
                        local success = installMod(prev == true, 18, {
                            description = 'Turbo enabled',
                        }, 2)
                        if not success then ToggleVehicleMod(vehicle, 18, prev) end
                        registerPerformanceContext()
                        lib.showContext(performanceMenuId)
                    end,
                },
            },
        })

        options[#options + 1] = {
            title = 'Turbo',
            description = ('%s | %s%s'):format(
                turboEnabled and 'Enabled' or 'Disabled',
                Config.Currency, Config.Prices[18]
            ),
            onSelect = function()
                lib.showContext(turboSubId)
            end,
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = performanceMenuId,
        title = 'Performance',
        menu = mainMenuId,
        onExit = onCustomsExit,
        options = options,
    })

    return #options > 0
end

return function()
    local hasOptions = registerPerformanceContext()
    if not hasOptions then
        lib.notify({
            title = 'Customs',
            description = 'This vehicle has no performance upgrades available',
            position = 'top',
            type = 'info'
        })
        return mainMenuId
    end
    return performanceMenuId
end
