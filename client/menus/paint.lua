local originalPaint = {}
local primaryPaint
local paintMenuId = 'customs-paint'

local registerPaintContext -- forward declaration

local function paintMods()
    local options = {}
    local primary, secondary = GetVehicleColours(vehicle)
    originalPaint.primary = primary
    originalPaint.secondary = secondary

    for category, values in pairs(Config.Paints) do
        local labels = {}
        local ids = {}
        local selectedIndex = 1

        for i, paint in ipairs(values) do
            labels[i] = paint.label
            ids[i] = paint.id
            if paint.id == (primaryPaint and primary or secondary) then
                selectedIndex = i
            end
        end

        local subContextId = ('%s-%s'):format(paintMenuId, category:lower())
        local subOptions = {}
        for i, label in ipairs(labels) do
            local idx = i
            local colorId = ids[i]
            local isCurrent = (i == selectedIndex)
            subOptions[#subOptions + 1] = {
                title = isCurrent and ('✓ %s'):format(label) or label,
                onSelect = function()
                    if primaryPaint then
                        SetVehicleColours(vehicle, colorId, originalPaint.secondary)
                    else
                        SetVehicleColours(vehicle, originalPaint.primary, colorId)
                    end
                    local duplicate = colorId == originalPaint[primaryPaint and 'primary' or 'secondary']
                    local success = require('client.utils.installMod')(duplicate, 'colors', {
                        description = ('%s applied'):format(label),
                        icon = 'fas fa-paint-brush',
                    })
                    if not success then
                        SetVehicleColours(vehicle, originalPaint.primary, originalPaint.secondary)
                    end
                    registerPaintContext(primaryPaint)
                    lib.showContext(paintMenuId)
                end,
            }
        end

        lib.registerContext({
            id = subContextId,
            title = category,
            menu = paintMenuId,
            onExit = onCustomsExit,
            options = subOptions,
        })

        options[#options + 1] = {
            title = category,
            description = ('%s | %s%s'):format(
                labels[selectedIndex],
                Config.Currency, Config.Prices['colors']
            ),
            onSelect = function()
                lib.showContext(subContextId)
            end,
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    return options
end

registerPaintContext = function(primary)
    primaryPaint = primary
    lib.registerContext({
        id = paintMenuId,
        title = primary and 'Primary paint' or 'Secondary paint',
        menu = 'customs-colors',
        onExit = onCustomsExit,
        options = paintMods(),
    })
end

---@param primary boolean
return function(primary)
    registerPaintContext(primary)
    return paintMenuId
end
