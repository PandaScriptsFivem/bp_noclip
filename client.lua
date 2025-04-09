local noclipActive = false
local camera = nil
local speedMultipliers = { normal = 1.0, slow = 0.5, fast = 4.0 }
local sleep = 250
local controls = {
    slow = 19,    -- Left Alt
    fast = 21,    -- Left Shift
    forward = 32, -- W
    backward = 33,-- S
    up = 44,      -- Q
    down = 46,    -- Z
    left = 34,    -- A
    right = 30,   -- D
    exit = 23     -- F
}

local function playCameraTransition()
    if not DoesCamExist(camera) then return end
    
    local camCoords = GetCamCoord(camera)
    local camRot = GetCamRot(camera, 2)
    local playerPed = PlayerPedId()
    
    local targetCoords = GetEntityCoords(playerPed)
    local targetHeading = GetEntityHeading(playerPed)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetCamCoord(camera, targetCoords.x, targetCoords.y, targetCoords.z + 0.5)
    SetCamRot(camera, 0.0, 0.0, targetHeading, 2)
    
    DoScreenFadeIn(500)
end

local function showTextUI()
    lib.showTextUI(
    '[WASD] - Mozgás  [Q/E] - Magasság\n'..
    '\n\n[SHIFT/ALT] - Sebesség  [F] - Kilépés', {
        position = "right-center",
        icon = 'hand'
    })
end

local function hideTextUI()
    lib.hideTextUI()
end

local function createCamera()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, GetEntityHeading(playerPed), 70.0)
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 1000, true, true)
    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
end

local function destroyCamera()
    RenderScriptCams(false, false, 1000, true, true)
    DestroyCam(camera, false)
    ClearFocus()
    camera = nil
end

local function placeCharacter()
    local playerPed = PlayerPedId()
    local camCoords = GetCamCoord(camera)
    local camRot = GetCamRot(camera, 2)
    
    playCameraTransition()
    
    local _, groundZ = GetGroundZFor_3dCoord(camCoords.x, camCoords.y, camCoords.z, false)
    SetEntityCoords(playerPed, camCoords.x, camCoords.y, groundZ or camCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, camRot.z)
    FreezeEntityPosition(playerPed, false)
    SetEntityAlpha(playerPed, 255, false)
end

local function handleMouseRotation()
    local mouseX = GetDisabledControlNormal(0, 1) * 8.0
    local mouseY = GetDisabledControlNormal(0, 2) * 8.0
    local camRot = GetCamRot(camera, 2)
    
    camRot = vector3(
        math.max(-89.0, math.min(89.0, camRot.x - mouseY)),
        camRot.y,
        camRot.z - mouseX
    )
    
    SetCamRot(camera, camRot.x, camRot.y, camRot.z, 2)
end

local function handleNoclipMovement()
    local camCoords = GetCamCoord(camera)
    local camRot = GetCamRot(camera, 2)
    
    local forwardVector = vector3(
        -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.sin(math.rad(camRot.x))
    )
    local rightVector = vector3(math.cos(math.rad(camRot.z)), math.sin(math.rad(camRot.z)), 0.0)
    
    local speed = IsControlPressed(0, controls.slow) and speedMultipliers.slow 
                or IsControlPressed(0, controls.fast) and speedMultipliers.fast 
                or speedMultipliers.normal
    
    if IsControlPressed(0, controls.forward) then camCoords += forwardVector * speed end
    if IsControlPressed(0, controls.backward) then camCoords -= forwardVector * speed end
    if IsControlPressed(0, controls.up) then camCoords += vector3(0, 0, speed) end
    if IsControlPressed(0, controls.down) then camCoords -= vector3(0, 0, speed) end
    if IsControlPressed(0, controls.right) then camCoords += rightVector * speed end
    if IsControlPressed(0, controls.left) then camCoords -= rightVector * speed end
    
    SetCamCoord(camera, camCoords.x, camCoords.y, camCoords.z)
    SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
end

RegisterNetEvent("bp_noclip:togglefly", function(isinfly)
    local playerId = GetPlayerServerId(PlayerId())

    local isAuthorized = lib.callback.await('bp_noclip:validatefly', playerId)

    if not isAuthorized then
        lib.notify({ title = "Nincs jogosultságod!", type = "error" })
        return
    end

    noclipActive = not noclipActive
    local playerPed = PlayerPedId()
    if isinfly then
        FreezeEntityPosition(playerPed, true)
        SetEntityAlpha(playerPed, 0, false)
        createCamera()
        showTextUI()
        lib.notify({ title = "NoClip bekapcsolva", type = "success" })
        TriggerServerEvent("bp_noclip:adminlog", isinfly)
    else
        placeCharacter()
        destroyCamera()
        hideTextUI()
        lib.notify({ title = "NoClip kikapcsolva", type = "error" })
        TriggerServerEvent("bp_noclip:adminlog", isinfly)
    end
end)



CreateThread(function()
    while true do
        if noclipActive then
            sleep = 10
            DisableAllControlActions(0)
            for _, control in pairs(controls) do
                EnableControlAction(0, control, true)
            end
            
            handleNoclipMovement()
            handleMouseRotation()
            
            if IsControlJustPressed(0, controls.exit) then
                TriggerEvent("bp_noclip:togglefly")
            end
        end
        Wait(sleep)
    end
end)
