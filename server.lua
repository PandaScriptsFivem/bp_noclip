
RegisterCommand("fly", function(source)
    local playerId = source
    local useVillamosAdutyv2 = GetResourceState('villamos_adutyv2') == 'started'
    if useVillamosAdutyv2 then
        if exports["villamos_adutyv2"]:IsInDuty(source) then
            TriggerClientEvent("bp_noclip:togglefly", playerId, true)
        else
            TriggerClientEvent("ox_lib:notify", playerId, { title = "Nem vagy Admin Szolgálatba!!", type = "error" })
        end
    elseif Config.AutoAdminGroup then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer.getGroup() ~= "user" then
            TriggerClientEvent("bp_noclip:togglefly", playerId, true)
        else
            TriggerClientEvent("ox_lib:notify", playerId, { title = "Nincs jogosultságod!", type = "error" })
        end
    else
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer.getGroup() and table.contains(Config.admingroups, xPlayer.getGroup()) then
            TriggerClientEvent("bp_noclip:togglefly", playerId, true)
        else
            TriggerClientEvent("ox_lib:notify", playerId, { title = "Nincs jogosultságod!", type = "error" })
        end
    end
end, false)

RegisterNetEvent("bp_noclip:adminlog", function(isinfly)
    local useVillamosAdutyv2 = GetResourceState('villamos_adutyv2') == 'started'
    if useVillamosAdutyv2 then
        if exports["villamos_adutyv2"]:IsInDuty(source) then
            exports['villamos_adutyv2']:sendAdminLog(source, "Admin Log", isinfly and "Bekapcsolta a repülést" or "Kikapcsolta a repülést", -1)
        end
    end
end)

lib.callback.register('bp_noclip:validatefly', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    if Config.AutoAdminGroup and xPlayer.getGroup() ~= "user" or
        table.contains(Config.admingroups, xPlayer.getGroup()) then
        return true 
    else
        return false
    end
end)

function table.contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end
