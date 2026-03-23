local buildValueSubContext = require('client.utils.buildValueSubContext')
local colorsMenuId = 'customs-colors'

local registerColorsContext -- forward declaration

registerColorsContext = function()
    local options = {}

    options[#options + 1] = {
        title = 'Paint primary',
        icon = 'fa-solid fa-spray-can',
        onSelect = function()
            local menuId = require('client.menus.paint')(true)
            lib.showContext(menuId)
        end,
    }

    options[#options + 1] = {
        title = 'Paint secondary',
        icon = 'fa-solid fa-spray-can',
        onSelect = function()
            local menuId = require('client.menus.paint')(false)
            lib.showContext(menuId)
        end,
    }

    options[#options + 1] = {
        title = 'Neon',
        icon = 'fa-solid fa-lightbulb',
        onSelect = function()
            local menuId = require('client.menus.neon')()
            lib.showContext(menuId)
        end,
    }

    local function addValueOption(option, subId)
        buildValueSubContext(subId, colorsMenuId, option, 'colors', 'fa-solid fa-spray-can', registerColorsContext)
        options[#options + 1] = {
            title = option.label,
            description = option.description,
            onSelect = function()
                lib.showContext(subId)
            end,
        }
    end

    addValueOption(require('client.options.xenon')(),      colorsMenuId .. '-xenon')
    addValueOption(require('client.options.pearlescent')(), colorsMenuId .. '-pearlescent')
    addValueOption(require('client.options.wheelcolor')(),  colorsMenuId .. '-wheelcolor')
    addValueOption(require('client.options.windowtint')(),  colorsMenuId .. '-windowtint')
    addValueOption(require('client.options.tyresmoke')(),   colorsMenuId .. '-tyresmoke')
    addValueOption(require('client.options.dashboard')(),   colorsMenuId .. '-dashboard')
    addValueOption(require('client.options.interior')(),    colorsMenuId .. '-interior')

    local liveryOption = require('client.options.livery')()
    if #liveryOption.values > 0 then
        addValueOption(liveryOption, colorsMenuId .. '-livery')
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = colorsMenuId,
        title = 'Cosmetics - Colors',
        menu = mainMenuId,
        onExit = onCustomsExit,
        options = options,
    })
end

return function()
    registerColorsContext()
    return colorsMenuId
end
