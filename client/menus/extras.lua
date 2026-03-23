local installMod = require('client.utils.installMod')
local extrasMenuId = 'customs-extras'

local registerExtrasContext -- forward declaration

registerExtrasContext = function()
    local options = {}

    for i = 1, 14 do
        if not DoesExtraExist(vehicle, i) then goto continue end

        local extraIndex = i
        local extraOn = IsVehicleExtraTurnedOn(vehicle, i)
        local subContextId = ('%s-%d'):format(extrasMenuId, i)

        lib.registerContext({
            id = subContextId,
            title = ('Extra %d'):format(i),
            menu = extrasMenuId,
            onExit = onCustomsExit,
            options = {
                {
                    title = extraOn and '✓ Enabled' or 'Enabled',
                    onSelect = function()
                        local prev = IsVehicleExtraTurnedOn(vehicle, extraIndex)
                        SetVehicleExtra(vehicle, extraIndex, 0) -- 0 = on
                        local success = installMod(prev == true, 'cosmetic', {
                            description = ('Extra %d enabled'):format(extraIndex),
                        })
                        if not success then
                            SetVehicleExtra(vehicle, extraIndex, prev and 0 or 1)
                        end
                        registerExtrasContext()
                        lib.showContext(extrasMenuId)
                    end,
                },
                {
                    title = (not extraOn) and '✓ Disabled' or 'Disabled',
                    onSelect = function()
                        local prev = IsVehicleExtraTurnedOn(vehicle, extraIndex)
                        SetVehicleExtra(vehicle, extraIndex, 1) -- 1 = off
                        local success = installMod(prev == false, 'cosmetic', {
                            description = ('Extra %d disabled'):format(extraIndex),
                        })
                        if not success then
                            SetVehicleExtra(vehicle, extraIndex, prev and 0 or 1)
                        end
                        registerExtrasContext()
                        lib.showContext(extrasMenuId)
                    end,
                },
            },
        })

        options[#options + 1] = {
            title = ('Extra %d'):format(i),
            description = ('%s | %s%s'):format(
                extraOn and 'Enabled' or 'Disabled',
                Config.Currency, Config.Prices['cosmetic']
            ),
            onSelect = function()
                lib.showContext(subContextId)
            end,
        }

        ::continue::
    end

    lib.registerContext({
        id = extrasMenuId,
        title = 'Extras',
        menu = mainMenuId,
        onExit = onCustomsExit,
        options = options,
    })
end

return function()
    registerExtrasContext()
    return extrasMenuId
end
