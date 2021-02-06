local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
local PlayerData = {}
local PersonalMenu = {
	ItemSelected = {},
    ItemIndex = {},
    ItemQuantity = 0,
}
local currentWeight, vehiclePlate, vehicleChest, maxPod, podChest, Weight = 0, {}, {}, 0, 0, 0
local currentVehicle

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
        ESX.PlayerData = ESX.GetPlayerData()
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
  ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('Drago_VehChest:setOwnedVehicule')
AddEventHandler('Drago_VehChest:setOwnedVehicule', function(vehicle)
    vehiclePlate = vehicle
end)

function VehicleInFront()
    local playerPed = GetPlayerPed(-1)
    local pos = GetEntityCoords(playerPed)
    local entityWorld = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 4.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, playerPed, 0)
    local _, _, _, _, result = GetRaycastResult(rayHandle)
    return result
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLength)
    AddTextEntry("FMMC_KEY_TIP1", TextEntry .. "")
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLength)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end

function CheckQuantity(number)
	number = tonumber(number)

	if type(number) == 'number' then
		number = ESX.Math.Round(number)

		if number > 0 then
			return true, number
		end
	end

	return false, number
end

RMenu.Add('main', 'menu', RageUI.CreateMenu("Coffre", "Contenu"))
RMenu:Get('main', 'menu'):DisplayGlare(false)
RMenu:Get('main', 'menu').Closed = function()
    local playerVehicle = VehicleInFront()
    SetVehicleDoorShut(playerVehicle, 5, false)
end
RMenu.Add('put', 'submenu', RageUI.CreateSubMenu(RMenu:Get('main', 'menu'), "Coffre", "Votre inventaire"))
RMenu:Get('put', 'submenu'):DisplayGlare(false)
RMenu:Get('put', 'submenu').Closed = function()
    podChest = 0
    ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
        vehicleChest = chestInv
        for i=1, #vehicleChest do
            podChest = podChest + (vehicleChest[i].weight * vehicleChest[i].count)
        end
    end, vehiclePlate)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local Px, Py, Pz = table.unpack(GetEntityCoords(PlayerPedId(),true))
        local Vx, Vy, Vz = table.unpack(GetEntityCoords(currentVehicle,true))
        if GetDistanceBetweenCoords(Px, Py, Pz, Vx, Vy, Vz, true) > 3 then
            SetVehicleDoorShut(currentVehicle, 5, false)
            RageUI.Visible(RMenu:Get('main', 'menu'), false)
            currentVehicle = nil
        end
        if not Config.UseDragoMenu then
            if IsControlJustPressed(0, Keys[Config.Shortcut]) then
                local playerPed = GetPlayerPed(-1)
                local x,y,z = table.unpack(GetEntityCoords(playerPed,true))
                local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 1)
                local playerVehicle = VehicleInFront()
                local typeVeh = GetVehicleClass(playerVehicle)
                maxPod = Config.VehicleLimit[typeVeh]
                vehiclePlate = GetVehicleNumberPlateText(playerVehicle)
                local lock = GetVehicleDoorLockStatus(playerVehicle)
                ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
                    vehicleChest = chestInv
                    for i=1, #vehicleChest do
                        podChest = 0
                        podChest = podChest + (vehicleChest[i].weight * vehicleChest[i].count)
                    end
                end, vehiclePlate)
                if playerVehicle > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= playerPed and lock ~= 2 then
                    SetVehicleDoorOpen(playerVehicle, 5, false, false)
                    currentVehicle = playerVehicle
                    RageUI.Visible(RMenu:Get('main', 'menu'), not RageUI.Visible(RMenu:Get('main', 'menu')))
                elseif playerVehicle < 0 and closecar ~= nil then
                    Visual.Popup("Quelqu'un regarde dans le coffre")
                else
                    Visual.Popup("Impossible d'ouvrir ce coffre")
                end
            end
        end
        RageUI.IsVisible(RMenu:Get('main', 'menu'), function()
            RageUI.Button("Déposer dans le coffre", "Poids total dans le véhicule :\n"..tonumber(podChest/1000).."Kg/"..tonumber(maxPod/1000).."Kg", {}, true, {
                onSelected = function()
                    for i=1, #ESX.PlayerData.inventory, 1 do
                        local item = ESX.PlayerData.inventory[i]
                        if item.count > 0 then
                            currentWeight = currentWeight + (item.weight * item.count)
                        end
                    end
                end
            }, RMenu:Get('put', 'submenu'))
            RageUI.Separator("Argents")
            for _,v in pairs(vehicleChest) do
                if v.name == 'money' then
                    RageUI.Button(v.label, "Poids total dans le véhicule :\n"..tonumber(podChest/1000).."Kg/"..tonumber(maxPod/1000).."Kg", {RightLabel = "~g~"..v.count.."$"}, true, {
                        onSelected = function()
                            local post, quantity = CheckQuantity(KeyboardInput("Quantité", '', 3))
                            if post then
                                ESX.TriggerServerCallback('Drago_VehChest:removeInventory', function(success)
                                    if success then
                                        Visual.Popup("Vous avez pris ~y~"..quantity.."x "..v.label.." ~w~dans le coffre")
                                        ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
                                            vehicleChest = chestInv
                                            for _,v2 in pairs(vehicleChest) do
                                                podChest = podChest + (v2.weight * v2.count)
                                            end
                                        end, vehiclePlate)
                                        podChest = 0
                                        ESX.PlayerData = ESX.GetPlayerData()
                                    else
                                        Visual.Popup("Vous portez trop de chose")
                                    end
                                end, v.name, quantity, vehiclePlate)
                            else
                                Visual.Popup("Quantité invalide")
                            end
                        end
                    })
                end
                if v.name == 'black_money' then
                    RageUI.Button(v.label, "Poids total dans le véhicule :\n"..tonumber(podChest/1000).."Kg/"..tonumber(maxPod/1000).."Kg", {RightLabel = "~r~"..v.count.."$"}, true, {
                        onSelected = function()
                            local post, quantity = CheckQuantity(KeyboardInput("Quantité", '', 3))
                            if post then
                                ESX.TriggerServerCallback('Drago_VehChest:removeInventory', function(success)
                                    if success then
                                        Visual.Popup("Vous avez pris ~y~"..quantity.."x "..v.label.." ~w~dans le coffre")
                                        ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
                                            vehicleChest = chestInv
                                            for _,v2 in pairs(vehicleChest) do
                                                podChest = podChest + (v2.weight * v2.count)
                                            end
                                        end, vehiclePlate)
                                        podChest = 0
                                        ESX.PlayerData = ESX.GetPlayerData()
                                    else
                                        Visual.Popup("Vous portez trop de chose")
                                    end
                                end, v.name, quantity, vehiclePlate)
                            else
                                Visual.Popup("Quantité invalide")
                            end
                        end
                    })
                end
            end
            RageUI.Separator("Objets")
            for _,v in pairs(vehicleChest) do
                if v.name ~= 'money' and v.name ~= 'black_money' and not string.match(tostring(v.name), 'WEAPON_') then
                    RageUI.Button(v.label.." ("..v.count..")", "Poids total dans le véhicule :\n"..tonumber(podChest/1000).."Kg/"..tonumber(maxPod/1000).."Kg", {}, true, {
                        onSelected = function()
                            local post, quantity = CheckQuantity(KeyboardInput("Quantité", '', 3))
                            if post then
                                ESX.TriggerServerCallback('Drago_VehChest:removeInventory', function(success)
                                    if success then
                                        Visual.Popup("Vous avez pris ~y~"..quantity.."x "..v.label.." ~w~dans le coffre")
                                        ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
                                            vehicleChest = chestInv
                                            for _,v2 in pairs(vehicleChest) do
                                                podChest = podChest + (v2.weight * v2.count)
                                            end
                                        end, vehiclePlate)
                                        podChest = 0
                                        ESX.PlayerData = ESX.GetPlayerData()
                                    else
                                        Visual.Popup("Vous portez trop de chose")
                                    end
                                end, v.name, quantity, vehiclePlate)
                            else
                                Visual.Popup("Quantité invalide")
                            end
                        end
                    })
                end
            end
            RageUI.Separator("Armes")
            for _,v in pairs(vehicleChest) do
                if string.match(tostring(v.name), 'WEAPON_') then
                    RageUI.Button(v.label.." ("..v.count..")", "Poids total dans le véhicule :\n"..tonumber(podChest/1000).."Kg/"..tonumber(maxPod/1000).."Kg",{},true,{
                        onSelected = function()
                            ESX.TriggerServerCallback('Drago_VehChest:removeInventory', function(success)
                                if success then
                                    Visual.Popup("Vous avez pris un(e) ~b~"..v.label.."~s~ avec ~y~"..v.count.." munitions~s~ dans le coffre")
                                    ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
                                        vehicleChest = chestInv
                                    end, vehiclePlate)
                                    ESX.PlayerData = ESX.GetPlayerData()
                                else
                                    Visual.Popup("Vous avez déjà cette arme")
                                end
                            end, v.name, v.count, vehiclePlate)
                        end
                    })
                end
            end
        end)
        RageUI.IsVisible(RMenu:Get('put', 'submenu'), function()
            ESX.PlayerData = ESX.GetPlayerData()
            ESX.TriggerServerCallback('Drago_menuperso:getPlayerWeight', function(weight)
                currentWeight = weight
            end)
            RageUI.Separator("Argent")
            for _,v in pairs(ESX.PlayerData.accounts) do
                if v.name == 'money' and v.money > 0 then
                    RageUI.Button(v.label, nil, {RightLabel = "~g~"..v.money.."$"}, true, {
                        onSelected = function()
                            local post, amount = CheckQuantity(KeyboardInput("Montant", '', 12))
                            if post then
                                if amount > 0 and amount <= v.money then
                                    ESX.TriggerServerCallback('Drago_VehChest:addInChest', function(success)
                                        if success then
                                            Visual.Popup("Vous avez déposé ~y~"..quantity.."x "..PersonalMenu.ItemSelected.label.." ~w~dans le coffre")
                                            ESX.PlayerData = ESX.GetPlayerData()
                                        end
                                    end, v.label, v.name, 'account', amount, 0, vehiclePlate)
                                else
                                    Visual.Popup("Montant invalide")
                                end
                            else
                                Visual.Popup("Entrer invalide")
                            end
                        end
                    })
                end
                if v.name == 'black_money' and v.money > 0 then
                    RageUI.Button(v.label, nil, {RightLabel = "~r~"..v.money.."$"}, true, {
                        onSelected = function()
                            local post, amount = CheckQuantity(KeyboardInput("Montant", '', 12))
                            if post then
                                if amount > 0 and amount <= v.money then
                                    ESX.TriggerServerCallback('Drago_VehChest:addInChest', function(success)
                                        if success then
                                            Visual.Popup("Vous avez déposé ~y~"..quantity.."x "..PersonalMenu.ItemSelected.label.." ~w~dans le coffre")
                                            ESX.PlayerData = ESX.GetPlayerData()
                                        end
                                    end, v.label, v.name, 'account', amount, 0, vehiclePlate)
                                else
                                    Visual.Popup("Montant invalide")
                                end
                            else
                                Visual.Popup("Entrer invalide")
                            end
                        end
                    })
                end
            end
            RageUI.Separator("Objets")
            for _,v in pairs(ESX.PlayerData.inventory) do
                if v.count > 0 then
                    RageUI.Button(v.label .. ' (' .. v.count .. ')', "Poids total : "..tonumber(currentWeight/1000)..'Kg/'..tonumber(ESX.PlayerData.maxWeight/1000)..'Kg', {}, true, {
                        onSelected = function()
                            local post, quantity = CheckQuantity(KeyboardInput('Quantité', '', 3))
                            PersonalMenu.ItemSelected = v
                            if post then
                                weight = (PersonalMenu.ItemSelected.weight * quantity)
                                local futurWeight = podChest + Weight
                                if  futurWeight > maxPod then
                                    Visual.Popup("Ce coffre est plein")
                                else
                                    ESX.TriggerServerCallback('Drago_VehChest:addInChest', function(success)
                                        if success then
                                            Visual.Popup("Vous avez déposé ~y~"..quantity.."x "..PersonalMenu.ItemSelected.label.." ~w~dans le coffre")
                                            ESX.PlayerData = ESX.GetPlayerData()
                                            currentWeight = currentWeight - Weight
                                            podChest = podChest + Weight
                                        end
                                    end, PersonalMenu.ItemSelected.label, PersonalMenu.ItemSelected.name, 'item', quantity, PersonalMenu.ItemSelected.weight, vehiclePlate)
                                end
                            else
                                Visual.Popup("Montant invalide")
                            end
                        end
                    })
                end
            end
            RageUI.Separator("Armes")
            local weaponList = ESX.GetWeaponList()
            for _,v in pairs(weaponList) do
                local weaponHash = GetHashKey(v.name)
                local ammo = GetAmmoInPedWeapon(PlayerPedId(), weaponHash)
                if HasPedGotWeapon(PlayerPedId(), weaponHash, false) and v.name ~= 'WEAPON_UNARMED' then
                    RageUI.Button(v.label.." ("..ammo..")", nil, {}, true, {
                        onSelected = function()
                            ESX.TriggerServerCallback('Drago_VehChest:addInChest', function(success)
                                if success then
                                    Visual.Popup("Vous avez déposé un(e) ~b~"..v.label.."~s~ avec "..ammo.." munition~s~ dans le coffre")
                                    ESX.PlayerData = ESX.GetPlayerData()
                                end
                            end, v.label, v.name, 'weapon', ammo, 0, vehiclePlate)
                        end
                    })
                end
            end
        end)
    end
end)

RegisterNetEvent('Drago_menuperso:openVehChest')
AddEventHandler('Drago_menuperso:openVehChest', function()
    local playerPed = GetPlayerPed(-1)
    local x,y,z = table.unpack(GetEntityCoords(playerPed,true))
    local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 1)
    local playerVehicle = VehicleInFront()
    local typeVeh = GetVehicleClass(playerVehicle)
    maxPod = Config.VehicleLimit[typeVeh]
    vehiclePlate = GetVehicleNumberPlateText(playerVehicle)
    local lock = GetVehicleDoorLockStatus(playerVehicle)
    ESX.TriggerServerCallback('Drago_VehChest:getChestInventory', function(chestInv)
        vehicleChest = chestInv
        for i=1, #vehicleChest do
            podChest = 0
            podChest = podChest + (vehicleChest[i].weight * vehicleChest[i].count)
        end
    end, vehiclePlate)
    if playerVehicle > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= playerPed and lock ~= 2 then
        SetVehicleDoorOpen(playerVehicle, 5, false, false)
        currentVehicle = playerVehicle
        RageUI.Visible(RMenu:Get('main', 'menu'), not RageUI.Visible(RMenu:Get('main', 'menu')))
    elseif playerVehicle < 0 and closecar ~= nil then
        Visual.Popup("Quelqu'un regarde dans le coffre")
    else
        Visual.Popup("Impossible d'ouvrir ce coffre")
    end
end)
