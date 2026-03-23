local getModLabel = require('client.utils.getModLabel')
local VehicleClass = require('client.utils.enums.VehicleClass')
local buildValueSubContext = require('client.utils.buildValueSubContext')
local installMod = require('client.utils.installMod')
local partsMenuId = 'customs-parts'

local registerPartsContext -- forward declaration

registerPartsContext = function()
    local options = {}

    for _, mod in ipairs(Config.Mods) do
        local modCount = GetNumVehicleMods(vehicle, mod.id)

        if mod.category ~= 'parts'
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
        local subContextId = ('%s-%d'):format(partsMenuId, mod.id)

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
                    local success = installMod(prevMod == modIndex, 'cosmetic', {
                        description = ('%s installed'):format(label),
                    })
                    if not success then
                        SetVehicleMod(vehicle, mod.id, prevMod, false)
                    end
                    registerPartsContext()
                    lib.showContext(partsMenuId)
                end,
            }
        end

        lib.registerContext({
            id = subContextId,
            title = mod.label,
            menu = partsMenuId,
            onExit = onCustomsExit,
            options = subOptions,
        })

        options[#options + 1] = {
            title = mod.label,
            description = ('%s | %s%s'):format(
                currentLabel,
                Config.Currency, Config.Prices['cosmetic']
            ),
            onSelect = function()
                lib.showContext(subContextId)
            end,
        }

        ::continue::
    end

    -- Wheels (non-cycles only)
    if GetVehicleClass(vehicle) ~= VehicleClass.Cycles then
        options[#options + 1] = {
            title = 'Wheels',
            icon = 'fa-solid fa-circle',
            onSelect = function()
                local menuId = require('client.menus.wheels')()
                lib.showContext(menuId)
            end,
        }
    end

    -- Plate index
    local plateOption = require('client.options.plateindex')()
    local plateSubId = partsMenuId .. '-plate'
    buildValueSubContext(plateSubId, partsMenuId, plateOption, 'cosmetic', nil, registerPartsContext)
    options[#options + 1] = {
        title = plateOption.label,
        description = plateOption.description,
        onSelect = function()
            lib.showContext(plateSubId)
        end,
    }

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = partsMenuId,
        title = 'Cosmetics - Parts',
        menu = mainMenuId,
        onExit = onCustomsExit,
        options = options,
    })
end

return function()
    registerPartsContext()
    return partsMenuId
end
