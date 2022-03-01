ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent("kn:speaker:soundStatus")
AddEventHandler("kn:speaker:soundStatus", function(type, musicId, data)
    TriggerClientEvent("kn:speaker:soundStatus", -1, type, musicId, data)
end)

RegisterNetEvent("kn:speaker:syncConfig")
AddEventHandler("kn:speaker:syncConfig", function(config)
    TriggerClientEvent("kn:speaker:syncConfig", -1, config)
end)