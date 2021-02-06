ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
local vehicules = {}

RegisterServerEvent('Drago_VehChest:getOwnedVehicule')
AddEventHandler('Drago_VehChest:getOwnedVehicule', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner',
   		{
   			['@owner'] = xPlayer.identifier
   		},
    function(result)
      if result ~= nil and #result > 0 then
          for _,v in pairs(result) do
      			local vehicle = json.decode(v.vehicle)
      			table.insert(vehicules, {plate = vehicle.plate})
      		end
      end
    TriggerClientEvent('Drago_VehChest:setOwnedVehicule', _source, vehicules)
    end)
end)

AddEventHandler('onMySQLReady', function ()
	MySQL.Async.execute( 'DELETE FROM `VehChest` WHERE `count` = 0', {})
end)

ESX.RegisterServerCallback('Drago_VehChest:addInChest', function(source, cb, label, item, quantity, weight, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute('INSERT INTO VehChest (label,item,weight,count,plate) VALUES (@label,@item,@weight,@quantity,@plate) ON DUPLICATE KEY UPDATE count=count+ @quantity', {
      ['@label'] = label,
      ['@item'] = item,
      ['@weight'] = weight,
      ['@quantity'] = quantity,
      ['@plate'] = plate,
    })
    if xPlayer ~= nil then
      local ItemCount = xPlayer.getInventoryItem(item).count
      if ItemCount >= quantity then
        xPlayer.removeInventoryItem(item, quantity)
        cb(true)
      else
        cb(false)
      end
    end
end)

ESX.RegisterServerCallback('Drago_VehChest:getChestInventory', function(source, cb, plate)
  local inventory_ = {}
  MySQL.Async.fetchAll(
    'SELECT * FROM `VehChest` WHERE `plate` = @plate',{
      ['@plate'] = plate
    }, function(inventory)
      if inventory ~= nil and #inventory > 0 then
        for i=1, #inventory, 1 do
          if inventory[i].count > 0 then
            table.insert(inventory_, {
              label      = inventory[i].label,
              name      = inventory[i].item,
              count     = inventory[i].count,
              weight    = inventory[i].weight
            })
          end
        end
      end
      cb(inventory_)
    end)
end)

ESX.RegisterServerCallback('Drago_VehChest:removeInventory', function(source, cb, item, quantity, plate)
  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.fetchScalar('SELECT count FROM vehchest WHERE plate=@plate AND item=@item', {
    ['@plate'] = plate,
    ['@item'] = item
  }, function(countincar)
    if countincar >= quantity and xPlayer.canCarryItem(item, quantity) then
      MySQL.Async.execute('UPDATE vehchest SET count=count-@quantity WHERE plate=@plate AND item=@item', {
        ['@plate'] = plate,
        ['@quantity'] = quantity,
        ['@item'] = item
      })
      if xPlayer ~= nil then
        xPlayer.addInventoryItem(item, quantity)
      end
      cb(true)
    else
      cb(false)
    end
  end)
end)