ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

xSound = exports.xsound

Citizen.CreateThread(function()
    sleep = 300
    while true do
        Citizen.Wait(sleep)
        for k,v in pairs(Config.Speakers) do
            if not v.boombox then
                local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.pos.x, v.pos.y, v.pos.z, true)
                local distance2 = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), v.pos.x, v.pos.y, v.pos.z, true)
                if distance <= 4 then
                    if distance2 <= 3 then
                        sleep = 0
                        if IsControlPressed(0, 38) then
                            openMenu(v.id)
                        end
                        TriggerEvent('cd_drawtextui:ShowUI', 'show', '[E] Speaker')
                    else
                        TriggerEvent('cd_drawtextui:ShowUI', 'hide')
                    end
                else
                    sleep = 300
                end
            end
        end
    end
end)

RegisterNetEvent("kn:speaker:soundStatus")
AddEventHandler("kn:speaker:soundStatus", function(type, musicId, data)
    Citizen.CreateThread(function()
        if type == "position" then
            if xSound:soundExists(musicId) then
                xSound:Position(musicId, data.position)
            end
        end
    
        if type == "play" then
            xSound:PlayUrlPos(musicId, data.link, data.volume, data.position)
            xSound:Distance(musicId, data.distance)
            xSound:setVolume(musicId, data.volume)
        end

        if type == "volume" then
            xSound:setVolume(musicId, data.volume)
        end
    
        if type == "stop" then
            xSound:Destroy(musicId)
        end
    end)
end)

local cooldown = false

function openMenu(id2)
    if not cooldown then 
        cooldown = true
        if not Config.Speakers[id2].data.playing then 
            local elements = {}
            table.insert(elements, {id = 1, header = "Speaker (id: "..id2..")", txt = '', params = {event = "kn:speaker:playMenu", args = {type = 'play', id = id2}}})
            table.insert(elements, {id = 2, header = 'Play Music', txt = 'Play Music On Speaker', params = {event = "kn:speaker:playMenu", args = {type = 'play', id = id2}}})
            TriggerEvent('nh-context:sendMenu', elements)
        else
            local elements = {}
            table.insert(elements, {id = 1, header = "Speaker (id: "..id2..")", txt = '', params = {event = "kn:speaker:playMenu", args = {type = 'play', id = id2}}})
            table.insert(elements, {id = 1, header = "Stop Music", txt = 'Stop Music', params = {event = "kn:speaker:playMenu", args = {type = 'stop', id = id2}}})
            table.insert(elements, {id = 2, header = "Change Volume", txt = 'Change Music Volume', params = {event = "kn:speaker:playMenu", args = {type = 'volume', id = id2}}})
            table.insert(elements, {id = 3, header = "Change Distance", txt = 'Change Music Distance', params = {event = "kn:speaker:playMenu", args = {type = 'distance', id = id2}}})      
            TriggerEvent('nh-context:sendMenu', elements)
        end
        cooldown = false
    end
end

RegisterNetEvent('kn:speaker:playMenu')
AddEventHandler('kn:speaker:playMenu',function(data)
    local musicId = 'id_'..data.id
    if data.type == 'play' then
        local keyboard, url, distance, volume = exports["nh-keyboard"]:Keyboard({
            header = "Play Music", 
            rows = {"Youtube URL", "Distance (Max 40)", "Volume (0.0 -1.0)"}
        })
    
        if keyboard then
            if url and tonumber(distance) and tonumber(volume) then
                TriggerServerEvent("kn:speaker:soundStatus", "play", musicId, { position = Config.Speakers[data.id].pos, link = url, volume = volume, distance = distance })
                Config.Speakers[data.id].data = {playing = true, currentId = 'id_'..PlayerId()}
                TriggerServerEvent('kn:speaker:syncConfig', Config)
            end
        end
    elseif data.type == 'stop' then
        TriggerServerEvent("kn:speaker:soundStatus", "stop", musicId, {})
        Config.Speakers[data.id].data = {playing = false}
        TriggerServerEvent('kn:speaker:syncConfig', Config)
    elseif data.type == 'volume' then
        local keyboard, volume = exports["nh-keyboard"]:Keyboard({
            header = "Change Volume", 
            rows = {"Volume (0.0 -1.0)"}
        })
    
        if keyboard then
            if tonumber(volume) and tonumber(volume) <= 1.0 then
                TriggerServerEvent("kn:speaker:soundStatus", "volume", musicId, {volume = volume})
            end
        end
    elseif data.type == 'distance' then
        local keyboard, distance = exports["nh-keyboard"]:Keyboard({
            header = "Change Distance", 
            rows = {"Distance (Max 40)"}
        })
    
        if keyboard then
            if tonumber(distance) and tonumber(distance) <= 40 then
                TriggerServerEvent("kn:speaker:soundStatus", "distance", musicId, {distance = distance})
            end
        end
    end
end)

RegisterNetEvent('kn:speaker:syncConfig')
AddEventHandler('kn:speaker:syncConfig', function(config)
    Config = config
end)

--[[BOOM BOX Coming soon!

RegisterNetEvent('kn:speaker:settings')
AddEventHandler('kn:speaker:settings',function(data)
    openMenu(data.entity)
end)

RegisterNetEvent('kn:speaker:boombox')
AddEventHandler('kn:speaker:boombox',function()
    startAnimation("anim@heists@money_grab@briefcase","put_down_case")
    Citizen.Wait(1000)
    ClearPedTasks(PlayerPedId())
    ESX.Game.SpawnObject("prop_boombox_01", GetEntityCoords(PlayerPedId()), function(obj)
        SetEntityHeading(obj, GetEntityHeading(PlayerPedId()))
        PlaceObjectOnGroundProperly(obj)
        TriggerServerEvent('kn:extraitems:useSpeaker', false)

        Config.Speakers[obj] = {
            id = obj,
            pos = GetEntityCoords(obj),
            boombox = true,
            data = {playing = false}
        }

        TriggerServerEvent('kn:speaker:syncConfig', Config)
    end)
end)

RegisterNetEvent('kn:speaker:pickUp')
AddEventHandler('kn:speaker:pickUp',function(data)
    ESX.Game.DeleteObject(data.entity)
    Config.Speakers[data.entity] = nil
    TriggerEvent('kn:speaker:playMenu', {id = data.entity, type = 'stop'})
    TriggerServerEvent('kn:extraitems:useSpeaker', true)
end)

function startAnimation(lib,anim)
    ESX.Streaming.RequestAnimDict(lib, function()
        TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end)
end]]