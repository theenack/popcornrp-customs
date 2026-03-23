mainMenuId = 'customs-main'
vehicle = 0
local QBCore
local inMenu = false
local dragcam = require('client.dragcam')
local startDragCam = dragcam.startDragCam
local stopDragCam = dragcam.stopDragCam

if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local openMainMenu -- forward declaration

onCustomsExit = function()
    inMenu = false
    stopDragCam()
    if not lib.callback.await('customs:server:adminMenuOpened') then
        lib.showTextUI('Press [E] to tune your car', {
            icon = 'fa-solid fa-car',
            position = 'left-center',
        })
    end
    if QBCore then
        TriggerServerEvent("customs:server:saveVehicleProps")
    end
end

local function disableControls()
    inMenu = true
    CreateThread(function()
        while inMenu do
            Wait(0)
            DisableControlAction(0, 71, true) -- accelerating
            DisableControlAction(0, 72, true) -- decelerating
            for i = 81, 85 do -- radio stuff
                DisableControlAction(0, i, true)
            end
            DisableControlAction(0, 106, true) -- turning vehicle wheels
        end
    end)
end

local function repair()
    local success = lib.callback.await('customs:server:repair', false, GetVehicleBodyHealth(vehicle))
    if success then
        lib.notify({
            title = 'Customs',
            description = 'Vehicle repaired!',
            position = 'top',
            type = 'success'
        })
        SendNUIMessage({sound = true})
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        local fuelLevel = GetVehicleFuelLevel(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleFuelLevel(vehicle, fuelLevel)
    else
        lib.notify({
            title = 'Customs',
            description = 'You don\'t have enough money!',
            position = 'top',
            type = 'error'
        })
    end
    openMainMenu()
end

openMainMenu = function()
    local options = {}

    if GetVehicleBodyHealth(vehicle) < 1000.0 then
        options[#options + 1] = {
            title = 'Repair',
            description = ('%s%d'):format(Config.Currency, math.ceil(1000 - GetVehicleBodyHealth(vehicle))),
            icon = 'fa-solid fa-wrench',
            onSelect = function()
                repair()
            end,
        }
    else
        options[#options + 1] = {
            title = 'Performance',
            icon = 'fa-solid fa-gauge-high',
            onSelect = function()
                local menuId = require('client.menus.performance')()
                if menuId then lib.showContext(menuId) end
            end,
        }
        options[#options + 1] = {
            title = 'Cosmetics - Parts',
            icon = 'fa-solid fa-car-side',
            onSelect = function()
                local menuId = require('client.menus.parts')()
                if menuId then lib.showContext(menuId) end
            end,
        }
        options[#options + 1] = {
            title = 'Cosmetics - Colors',
            icon = 'fa-solid fa-palette',
            onSelect = function()
                local menuId = require('client.menus.colors')()
                if menuId then lib.showContext(menuId) end
            end,
        }
        if DoesExtraExist(vehicle, 1) then
            options[#options + 1] = {
                title = 'Extras',
                icon = 'fa-solid fa-sliders',
                onSelect = function()
                    local menuId = require('client.menus.extras')()
                    if menuId then lib.showContext(menuId) end
                end,
            }
        end
    end

    lib.registerContext({
        id = mainMenuId,
        title = 'Popcorn Customs',
        onExit = onCustomsExit,
        options = options,
    })
    lib.showContext(mainMenuId)
end

lib.callback.register('customs:client:vehicleProps', function()
    return QBCore.Functions.GetVehicleProperties(vehicle)
end)

return function()
    if not cache.vehicle or inMenu then return end
    vehicle = cache.vehicle
    SetVehicleModKit(vehicle, 0)
    openMainMenu()
    disableControls()
    startDragCam(vehicle)
end
