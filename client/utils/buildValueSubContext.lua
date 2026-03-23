---Creates and registers a sub-context for a scrollable option (values list).
---Each item in the sub-context applies the mod and processes payment on click.
---@param subContextId string Unique ID for the sub-context
---@param parentContextId string Parent context ID (back button target)
---@param option table Option data with values, set, restore, defaultIndex
---@param modType string|number Mod type for installMod payment
---@param icon string? Font Awesome icon class for the install notification
---@param onSuccess function? Called after a successful install to refresh the parent
return function(subContextId, parentContextId, option, modType, icon, onSuccess)
    local subOptions = {}
    for i, label in ipairs(option.values) do
        local index = i
        local isCurrent = (i == option.defaultIndex)
        subOptions[#subOptions + 1] = {
            title = isCurrent and ('✓ %s'):format(label) or label,
            onSelect = function()
                local duplicate, desc = option.set(index)
                local success = require('client.utils.installMod')(duplicate, modType, {
                    description = desc,
                    icon = icon,
                })
                if not success then option.restore() end
                if onSuccess then onSuccess() end
                lib.showContext(parentContextId)
            end,
        }
    end

    lib.registerContext({
        id = subContextId,
        title = option.label,
        menu = parentContextId,
        onExit = onCustomsExit,
        options = subOptions,
    })
end
