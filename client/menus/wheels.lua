local WheelType = require('client.utils.enums.WheelType')
local VehicleClass = require('client.utils.enums.VehicleClass')
local installMod = require('client.utils.installMod')
local wheelsMenuId = 'customs-wheels'
local partsMenuId = 'customs-parts'

---@param wheelType WheelType
local function isWheelTypeAllowed(wheelType)
    local class = GetVehicleClass(vehicle)
    if class == VehicleClass.Cycles then return false end

    if class == VehicleClass.Motorcycles then
        return wheelType == WheelType.Bike
    end

    if class == VehicleClass.OpenWheels then
        return wheelType == WheelType.OpenWheel
    end
    return true
end

local registerWheelsContext -- forward declaration

registerWheelsContext = function()
    local options = {}
    local originalWheelType = GetVehicleWheelType(vehicle)
    local originalMod = GetVehicleMod(vehicle, 23)
    local originalRearWheel = GetVehicleMod(vehicle, 24)
    local bikeLabels = nil

    for _, category in ipairs(Config.Wheels) do
        if not isWheelTypeAllowed(category.id) then goto continue end

        SetVehicleWheelType(vehicle, category.id)
        local modCount = GetNumVehicleMods(vehicle, 23)
        local labels = {}
        for j = 1, modCount do
            labels[j] = GetLabelText(GetModTextLabel(vehicle, 23, j - 1))
        end

        if category.id == WheelType.Bike then
            bikeLabels = labels
        end

        local subContextId = ('%s-%d'):format(wheelsMenuId, category.id)
        local subOptions = {}
        for j, label in ipairs(labels) do
            local idx = j
            local isCurrent = (originalWheelType == category.id and idx - 1 == originalMod)
            subOptions[#subOptions + 1] = {
                title = isCurrent and ('✓ %s'):format(label) or label,
                onSelect = function()
                    SetVehicleWheelType(vehicle, category.id)
                    SetVehicleMod(vehicle, 23, idx - 1, false)
                    local duplicate = category.id == originalWheelType and idx - 1 == originalMod
                    local success = installMod(duplicate, 'cosmetic', {
                        description = ('%s %s installed'):format(category.label, label),
                    })
                    if not success then
                        SetVehicleWheelType(vehicle, originalWheelType)
                        SetVehicleMod(vehicle, 23, originalMod, false)
                    end
                    registerWheelsContext()
                    lib.showContext(wheelsMenuId)
                end,
            }
        end

        lib.registerContext({
            id = subContextId,
            title = category.label,
            menu = wheelsMenuId,
            onExit = onCustomsExit,
            options = subOptions,
        })

        local currentLabel = (originalWheelType == category.id and labels[originalMod + 1]) or 'None'
        options[#options + 1] = {
            title = category.label,
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

    -- Restore the original wheel type after iterating
    SetVehicleWheelType(vehicle, originalWheelType)

    -- Bike rear wheel (motorcycles only)
    if GetVehicleClass(vehicle) == VehicleClass.Motorcycles and bikeLabels and #bikeLabels > 0 then
        local rearSubId = wheelsMenuId .. '-rear'
        local rearSubOptions = {}
        for j, label in ipairs(bikeLabels) do
            local idx = j
            local isCurrent = (idx - 1 == originalRearWheel)
            rearSubOptions[#rearSubOptions + 1] = {
                title = isCurrent and ('✓ %s'):format(label) or label,
                onSelect = function()
                    SetVehicleWheelType(vehicle, WheelType.Bike)
                    SetVehicleMod(vehicle, 24, idx - 1, false)
                    local success = installMod(idx - 1 == originalRearWheel, 'cosmetic', {
                        description = ('Bike rear %s installed'):format(label),
                    })
                    if not success then
                        SetVehicleMod(vehicle, 24, originalRearWheel, false)
                    end
                    registerWheelsContext()
                    lib.showContext(wheelsMenuId)
                end,
            }
        end

        lib.registerContext({
            id = rearSubId,
            title = 'Bike rear wheel',
            menu = wheelsMenuId,
            onExit = onCustomsExit,
            options = rearSubOptions,
        })

        options[#options + 1] = {
            title = 'Bike rear wheel',
            description = ('%s | %s%s'):format(
                bikeLabels[originalRearWheel + 1] or 'Stock',
                Config.Currency, Config.Prices['cosmetic']
            ),
            onSelect = function()
                lib.showContext(rearSubId)
            end,
        }
    end

    table.sort(options, function(a, b)
        if a.title == 'Bike rear wheel' then return false end
        return a.title < b.title
    end)

    lib.registerContext({
        id = wheelsMenuId,
        title = 'Wheels',
        menu = partsMenuId,
        onExit = onCustomsExit,
        options = options,
    })
end

return function()
    registerWheelsContext()
    return wheelsMenuId
end
