local noclipActive = false
local playerPed = PlayerPedId()

local function startParachuteAnimation()
    RequestAnimDict("skydive@base")
    while not HasAnimDictLoaded("skydive@base") do
        Wait(10)
    end
    TaskPlayAnim(playerPed, "skydive@base", "free_idle", 8.0, 8.0, -1, 3, 0, false, false, false)
end

local function stopParachuteAnimation()
    ClearPedTasks(playerPed)
end

local function toggleNoclip()
    noclipActive = not noclipActive
    local playerPed = PlayerPedId()

    if noclipActive then
        startParachuteAnimation()
        SetEntityInvincible(playerPed, true)
        FreezeEntityPosition(playerPed, true)
        lib.notify({ title = "Noclip aktiválva", type = "success" })
    else
        stopParachuteAnimation()
        SetEntityInvincible(playerPed, false)
        FreezeEntityPosition(playerPed, false)
        lib.notify({ title = "Noclip kikapcsolva", type = "error" })
    end
end

local function handleNoclipMovement()
    local playerPed = PlayerPedId()
    local camRot = GetGameplayCamRot(0)
    local forwardVector = RotationToDirection(camRot)

    local speed = 1.0
    if IsControlPressed(0, 21) then 
        speed = 2.5
    end

    if IsControlPressed(0, 32) then 
        local pos = GetEntityCoords(playerPed) + forwardVector * speed
        SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 33) then 
        local pos = GetEntityCoords(playerPed) - forwardVector * speed
        SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 44) then 
        local pos = GetEntityCoords(playerPed) + vector3(0, 0, speed)
        SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 46) then 
        local pos = GetEntityCoords(playerPed) + vector3(0, 0, -speed)
        SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)
    end

    local camRotZ = camRot.z
    SetEntityHeading(playerPed, camRotZ)
end

function RotationToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local num = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * num, math.cos(radZ) * num, math.sin(radX))
end

CreateThread(function()
    while true do
        Wait(0)
        if noclipActive then
            handleNoclipMovement()
        end
    end
end)

RegisterCommand("fly", function()
    if ESX.PlayerData.group ~= "user" then
        toggleNoclip()
    else
        lib.notify({ title = "Nincsen jogosultságod", type = "error" })
    end
end, false)