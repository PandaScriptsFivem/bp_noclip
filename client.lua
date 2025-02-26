local noclipActive = false
local playerPed = PlayerPedId()
local playerPositions = {}
local function startParachuteAnimation()
    lib.playAnim(playerPed, "skydive@base", "free_idle", 8.0, 8.0, -1, 3)
end

local function stopParachuteAnimation()
    ClearPedTasks(playerPed)
end

local function placeOnGround()
    local entity = playerPed
    if IsPedInAnyVehicle(playerPed, false) then
        entity = GetVehiclePedIsIn(playerPed, false)
    end

    local pos = GetEntityCoords(entity)
    local foundGround, groundZ = false, nil
    local zCoord = pos.z

    for i = 0, 1000, 1 do
        foundGround, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, zCoord - i, false)
        if foundGround then
            break
        end
    end

    if foundGround then
        SetEntityCoords(entity, pos.x, pos.y, groundZ, true, true, true)
    else
        lib.notify({ title = "Nem sikerült földet találni", type = "error" })
    end
end

local function toggleNoclip()
    noclipActive = not noclipActive
    playerPed = PlayerPedId()

    if noclipActive then
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            FreezeEntityPosition(vehicle, true)
        else
            startParachuteAnimation()
            FreezeEntityPosition(playerPed, true)
        end
        SetLocalPlayerAsGhost(true)
        SetGhostedEntityAlpha(0)
        NetworkSetPlayerIsPassive(true)
        lib.notify({ title = "Noclip aktiválva", type = "success" })
    else
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            FreezeEntityPosition(vehicle, false)
        else
            stopParachuteAnimation()
            FreezeEntityPosition(playerPed, false)
        end
        placeOnGround()
        SetLocalPlayerAsGhost(false)
        NetworkSetPlayerIsPassive(false)
        lib.notify({ title = "Noclip kikapcsolva", type = "error" })
    end
end
local function handleNoclipMovement()
    playerPed = PlayerPedId()
    local entity = playerPed
    if IsPedInAnyVehicle(playerPed, false) then
        entity = GetVehiclePedIsIn(playerPed, false)
    end

    local camRot = GetGameplayCamRot(0)
    local forwardVector = RotationToDirection(camRot)
    local rightVector = RotationToRightDirection(camRot)
    local speed = 1.0

    if IsControlPressed(0, 19) then 
        speed = 0.5
    elseif IsControlPressed(0, 21) then 
        speed = 2.5
    end

    if IsControlPressed(0, 32) then 
        local pos = GetEntityCoords(entity) + forwardVector * speed
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 33) then 
        local pos = GetEntityCoords(entity) - forwardVector * speed
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 44) then 
        local pos = GetEntityCoords(entity) + vector3(0, 0, speed)
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 46) then 
        local pos = GetEntityCoords(entity) + vector3(0, 0, -speed)
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 30) then 
        local pos = GetEntityCoords(entity) + rightVector * speed
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    if IsControlPressed(0, 34) then 
        local pos = GetEntityCoords(entity) - rightVector * speed
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
    end

    local camRotZ = camRot.z
    SetEntityHeading(entity, camRotZ)
end

function RotationToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local num = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * num, math.cos(radZ) * num, math.sin(radX))
end

function RotationToRightDirection(rotation)
    local radZ = math.rad(rotation.z)
    return vector3(math.cos(radZ), math.sin(radZ), 0)
end

CreateThread(function()
    while true do
        Wait(0)
        if noclipActive then
            if not IsPedInAnyVehicle(playerPed, false) and not IsEntityPlayingAnim(playerPed, "skydive@base", "free_idle", 3) then
                startParachuteAnimation()
            end
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
