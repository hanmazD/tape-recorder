local cacheSpeaker = {}
local placedSpeaker = {}
local placedSpeakerCoords = nil
local onSongPick = false
local currentId = nil

-- Citizen.CreateThread(
-- 	function()
-- 		while ESX == nil do
-- 			if (Config.UsingESX) then
-- 				TriggerEvent(
-- 					"esx:getSharedObject",
-- 					function(obj)
-- 						ESX = obj
-- 					end
-- 				)
-- 			end
-- 			Citizen.Wait(0)
-- 		end
-- 	end
-- )

AddEventHandler(
	"onResourceStop",
	function(resource)
		if resource == GetCurrentResourceName() then
			SetNuiFocus(false, false)
		end
	end
)



Citizen.CreateThread(function()
	while not NetworkIsSessionStarted() do Wait(0) end
	if (Config.UsingESX) then
		while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Wait(0) end
		while ESX.GetPlayerData().job == nil do Wait(0) end
	end
	TriggerServerEvent("esx_kepo_speaker:joined")
end)



RegisterNUICallback("loadServer",function(data, cb)
	local plyrcoords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())
	local spawncoords = (plyrcoords + forward * 1.0)

	local tempTable = {
		[1] = {id = data.id, coords = cacheSpeaker[currentId].coords, time = data.time, speaker = currentId, startTime = data.time, speakerid = cacheSpeaker[currentId].speakerid}
	}
		TriggerServerEvent("esx_kepo_speaker:loadSpeaker", tempTable[1])
end)


RegisterNetEvent("esx_kepo_speaker:loadSpeakerClient")
AddEventHandler("esx_kepo_speaker:loadSpeakerClient", function(speaker)
	cacheSpeaker[speaker.speaker] = speaker
end)


RegisterNetEvent("esx_kepo_speaker:joined")
AddEventHandler("esx_kepo_speaker:joined", function(speaker)
	cacheSpeaker = speaker
end)

RegisterNetEvent("esx_kepo_speaker:removeClient")
AddEventHandler("esx_kepo_speaker:removeClient", function(speaker)
	cacheSpeaker[speaker] = nil
	SendNUIMessage({close = true})
end)

local speaker
local started = false
local playing
local onSwitch = false
local onVolChange = false
local volchange = 0
local videoStatus = "play"
local newTime = 0

RegisterNUICallback("switchVideo",function(data, cb)
	onSwitch = true
	videoStatus = data.videoStatus
	newTime = data.pausedTime
end)

RegisterNUICallback("changeVol",function(data, cb)
	onVolChange = true
	volchange = data.vol
end)

RegisterNetEvent("esx_kepo_speaker:switchVideoClient")
AddEventHandler("esx_kepo_speaker:switchVideoClient", function(id, videoStatus, time)
	if id ~= nil then
	cacheSpeaker[id].switch = true
	cacheSpeaker[id].videoStatus = videoStatus
	if time ~= nil then
	cacheSpeaker[id].time = time - cacheSpeaker[id].time
	else
	cacheSpeaker[id].time = 0 
	end
	end
end)

RegisterNetEvent("esx_kepo_speaker:changeVolClient")
AddEventHandler("esx_kepo_speaker:changeVolClient", function(id, vol)
	if id ~= nil then
	cacheSpeaker[id].volval = vol
	cacheSpeaker[id].volchange = true
	end
end)

local vol = 100

Citizen.CreateThread(function()
	while true do
		local wait = 100
		local plyr = PlayerPedId()
		local plyrcoords = GetEntityCoords(plyr)

		if #cacheSpeaker > 0 then
			for k, v in pairs(cacheSpeaker) do
                local dist = #(v.coords - plyrcoords)
                
                if v.id ~= nil then
                    
					if dist < 20.0 then

						vol = v.volval - (dist * 5)

						if not v.playing then

							v.playing = true

							playing = k

							SendNUIMessage({start = true, time = v.time, id = v.id, videoStatus = v.videoStatus, startTime = v.startTime})

							videoStatus = v.videoStatus

						elseif playing == k and onSwitch then

							TriggerServerEvent("esx_kepo_speaker:switchVideo", k, videoStatus, newTime)

							onSwitch = false

						elseif playing == k and v.switch then

							v.switch = false

							SendNUIMessage({switch = true, videoStatus = v.videoStatus, time = v.time})

						elseif playing == k and onVolChange then

							TriggerServerEvent("esx_kepo_speaker:changeVol", k, volchange)

							onVolChange = false

						elseif playing == k and v.volchange then

							v.volchange = false

						end

					elseif dist > 20.0 and playing == k and v.playing then

						SendNUIMessage({type = "reset"})

						v.playing = false

						SendNUIMessage({close = true})

					end

					

					if playing == k and v.playing then

						if IsPedInAnyVehicle(plyr, false) then

							vol = vol / 5

						end

						SendNUIMessage({volume = vol, setVol = true, volval = v.volval})

					end

				end

			end

		end

		Wait(wait)

	end

end)

local checkWhile = 500

Citizen.CreateThread(function()

	while true do

		Wait(checkWhile)
		checkWhile = 500
		if #cacheSpeaker > 0 then

			for k, v in pairs(cacheSpeaker) do



				if #(v.coords - GetEntityCoords(PlayerPedId())) < 2.0 then
					checkWhile = 8

					local fixedCoords = vector3(v.coords.x, v.coords.y, v.coords.z - 1.5)

					currentId = v.speaker

				--	HelpText(Config["translations"].pickUp, fixedCoords)



					if IsControlJustPressed(1,252) then

						SetNuiFocus(true, true)

						SendNUIMessage({type = "openSpeaker"})

					end

					if IsControlJustPressed(0, 47) then

						TriggerServerEvent("esx_kepo_speaker:removeSpeaker", currentId)

						SendNUIMessage({type = "reset"})

						print(v.speakerid)

						DeleteEntity(v.speakerid)

						while DoesEntityExist(v.speakerid) do

							Wait(0)

							DeleteEntity(v.speakerid)

						end

						started = false

						placedSpeakerCoords = nil

					end

				end

			end

		end

	end

end)



-- RegisterCommand("speaker",function(source, args, rawCommand)
-- 	if not IsPedInAnyVehicle(PlayerPedId(), true) and Config.EnableCommand then
-- 		TriggerEvent("kepo_speaker:place")
-- 	end
-- end)

RegisterNetEvent("kepo_speaker:Removevrp")
AddEventHandler("kepo_speaker:Removevrp", function()
    if #cacheSpeaker > 0 then

        for k, v in pairs(cacheSpeaker) do
            currentId = v.speaker
            TriggerServerEvent("esx_kepo_speaker:removeSpeaker", currentId)

            SendNUIMessage({type = "reset"})

            print(v.speakerid)

            DeleteEntity(v.speakerid)

            while DoesEntityExist(v.speakerid) do

                Wait(0)

                DeleteEntity(v.speakerid)

            end

            started = false

            placedSpeakerCoords = nil
        end
    end
end)



RegisterNetEvent("kepo_speaker:place")
AddEventHandler("kepo_speaker:place", function()
	local plyrcoords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())
	local spawncoords = (plyrcoords + forward * 1.0)
	tooClose = false
	if #cacheSpeaker > 0 then
		for k, v in pairs(cacheSpeaker) do
			if #(plyrcoords - v.coords) < 40.0 then
				tooClose = true
			end
		end
		if not tooClose then
			speaker = CreateObject(GetHashKey("prop_el_tapeplayer_01"), spawncoords, true, true, true)
			FreezeEntityPosition(speaker, true)
			SetEntityAsMissionEntity(speaker)
			SetEntityCollision(speaker, false, true)
			PlaceObjectOnGroundProperly(speaker)
			TriggerServerEvent("esx_kepo_speaker:placedSpeaker", spawncoords, speaker)
			SetEntityHeading(speaker, GetEntityHeading(PlayerPedId()))
		else
			--ESX.ShowNotification(Config["translations"].tooClose, false, false)
		end
	else
		speaker = CreateObject(GetHashKey("prop_el_tapeplayer_01"), spawncoords, true, true, true)
		FreezeEntityPosition(speaker, true)
		SetEntityAsMissionEntity(speaker)
		SetEntityCollision(speaker, false, true)
		PlaceObjectOnGroundProperly(speaker)
		TriggerServerEvent("esx_kepo_speaker:placedSpeaker", spawncoords, speaker)
		SetEntityHeading(speaker, GetEntityHeading(PlayerPedId()))
	end
end)

RegisterNetEvent("kepo_speaker:Atach")
AddEventHandler("kepo_speaker:Atach", function()
	AttachEntityToEntity(speaker, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.30, 0, 0, 0, 260.0, 60.0, true, true, false, true, 1, true)
end)

RegisterNetEvent("kepo_speaker:Detach")
AddEventHandler("kepo_speaker:Detach", function()
	PlaceObjectOnGroundProperly(speaker)
	TriggerServerEvent("esx_kepo_speaker:placedSpeaker", GetEntityCoords(PlayerPedId()), speaker)
end)



RegisterNUICallback("escape",function(data, cb)
	SetNuiFocus(false, false)
end)



local function DrawText3d(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.0, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(209, 211, 212, 160)
        SetTextDropshadow(0, 0, 0, 0, 120)
        --SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        SetDrawOrigin(x,y,z, 0)
        DrawText(0.0, 0.0)
        DrawRect(0.0, 0.0 + 0.014, 0.048, 0.03, 30,29,45, 100)
        ClearDrawOrigin()
    end
end

HelpText = function(msg, coords)
    if not coords or not Config.Enable3DText then
        AddTextEntry(GetCurrentResourceName(), msg)
        DisplayHelpTextThisFrame(GetCurrentResourceName(), false)
    else
        DrawText3d(coords.x,coords.y,coords.z, string.gsub(msg, "~INPUT_CONTEXT~", "~r~[~w~E~r~]~w~"))
    end
end





