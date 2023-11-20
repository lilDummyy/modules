--[[
Dummy -- ProfilServiceDataStore

02/09/23
DataStoreModule / ProfilsService

i used some bindable event and some remote event to update some data value directly
btw remoteComponentData are just some table module to get some client information (table only)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfilsModulesFolder = ReplicatedStorage:WaitForChild("ProfilsModules")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(Knit.Util.Promise)
local Thread = require(Knit.Util.Thread)
local Option = require(Knit.Util.Option)
local Maid = require(Knit.Util.Maid)

local LoadComponent = require(script:WaitForChild("LoadComponent"))
local ProfilesComponents = require(script:WaitForChild("ProfilesComponents"))
local ProfilService = require(ProfilsModulesFolder:FindFirstChild("ProfileService"))
local RemoteComponentData = require(script:WaitForChild("RemoteComponentData"))

local remoteLoader = RemoteComponentData.new()

local ProfilsTask = Maid.new()

ProfilStore = ProfilService.GetProfileStore("GlobalDataStore1",LoadComponent)
local Profils = {}

function Profils:playerJoined(player)
	if (player) then
		local profil = ProfilStore:LoadProfileAsync("Player_"..player.UserId)
		if (profil) == nil then
			player:Kick("Profil perdu , essayé de rejoindre le jeux une nouvelle fois pour chargé correctement vos données.")
		end
		
		profil:AddUserId(player.UserId)
		profil:Reconcile()
		profil:ListenToRelease(function()
			player:Kick("Profil perdu , essayé de rejoindre le jeux une nouvelle fois pour chargé correctement vos données.")
			ProfilesComponents.ProfilesAttach[player.UserId] = nil
		end)
		if player:IsDescendantOf(Players) == true then
			ProfilesComponents.ProfilesAttach[player.UserId] = profil
			print(ProfilesComponents.ProfilesAttach[player.UserId].Data) -- currentDataTable
			ReplicatedStorage.Packages.Remotes.SynchroniseSettings:FireClient(player,ProfilesComponents.ProfilesAttach[player.UserId].Data)
			ReplicatedStorage.Packages.Remotes._remote.AutomaticSettingsLoad:FireClient(player,ProfilesComponents.ProfilesAttach[player.UserId].Data)
		end
	end
end

local function changeData(value)
	if (value.p) and (value.SavingMode == true) then
		if (value.Timer ~= nil) then
			if (value.dragPercentage) then ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.PercentageForUi.dragPercentageClockTime = value.dragPercentage end
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.LightingClockTime = value.Timer
		elseif (value.VolumeClient ~= nil) then
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.VolumeSynchroniseClient = value.VolumeClient
		elseif (value.GetSaturationValue) and (value.CurrentSaturationPercentage) then
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others[value.Name] = value.GetSaturationValue
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others.percentages[value.Name] = value.CurrentSaturationPercentage
		elseif (value.GetContrastValue ~= nil) and (value.CurrentContrastPercentage) then
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others[value.Name] = value.GetContrastValue
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others.percentages[value.Name] = value.CurrentContrastPercentage
		elseif(value.GetBrightnessValue ~= nil) and (value.CurrentBrightnessPercentage) then
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others[value.Name] = value.GetBrightnessValue
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others.percentages[value.Name] = value.CurrentBrightnessPercentage
		elseif (value.value ~= nil) and (value.ShadowsName) then
			ProfilesComponents.ProfilesAttach[value.p.UserId].Data.Settings.Others[value.ShadowsName] = value.value
		end
	end
end

local function CurrentStats(value)
	if (value.p) then
		return ProfilesComponents.ProfilesAttach[value.p.UserId].Data
	else
		warn(value)
	end
end

local function setInventoryItemToData(data)
	assert(type(data) == "table", `data must be a table value {debug.traceback("data error",2)}`)
	if ((data.GetAll.InventoryName)) then
		return Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].__bindable.__Function:Invoke(data)
	end	
	error("can't find [InventoryName] from data",2)
end

local function ReleaseBindable()
	return Promise.new(function(resolve,reject,onCancel)
		Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].__bindable.__Function.OnInvoke = function(data)
			if (data.p) and (data.SavingMode == true)  then
				local function checkIfAlreadyExistFromData()
					if ((ProfilesComponents.ProfilesAttach[data.p.UserId].Data.Settings)) then
						local Settings = ProfilesComponents.ProfilesAttach[data.p.UserId].Data.Settings
						if (not table.find(Settings.InventoryClass.Item,data.GetAll.item)) then
							table.insert(Settings.InventoryClass.Item,data.GetAll.item)
							return 'Succès'
						end
					else
						return error("Data User is NUL  (<%s>) !"..`{debug.traceback("data error",2)}`,2)
					end
				end
				local result = checkIfAlreadyExistFromData()
				if (result == 'Succès') then
					return print("<[Tools Saved]> : State <(",string.format(result,data.GetAll.item)..")>")
				end
			else
				return reject("[Knit (Server)] Player is nil or SavingMethods is Disable")
			end
		end
	end):catch(warn)
end

local function loadBindable(plr)
	return Promise.new(function(resolve,reject,onCancel)
		local Settings = ProfilesComponents.ProfilesAttach[plr.UserId].Data.Settings	
		Knit.Util.Menu["InventoryModule.all"]["inventory.emitter"].LoadComponent:InvokeClient(plr,Settings.DeathsEffects.purchased)
		Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].__bindable.ClientService.__ReceiveServer:InvokeClient(plr,Settings.InventoryClass)
		return "All Bindable Event has been loaded.. <OverStackPackages> Begin"		
	end)
end

local function OnComponentRemoved(data)
	local function wrapData()
		local Settings = ProfilesComponents.ProfilesAttach[data.p.UserId].Data.Settings
		if (Settings) then
			return Option.Wrap(Settings)
		else
			return Option.None
		end
	end
	wrapData():Match{
		Some = function(lastData)
			if (table.find(lastData.InventoryClass.Item,data.Component)) then
				table.remove(lastData.InventoryClass.Item,table.find(lastData.InventoryClass.Item,data.Component))
			elseif table.find(lastData.InventoryClass.Item,tostring(data.Component)) then
				table.remove(lastData.InventoryClass.Item,table.find(lastData.InventoryClass.Item,tostring(data.Component)))
			else
				warn(lastData,data.Component)
			end
		end,
		
		None = function() end,
	}
end

if RunService:IsServer() then
	for i,players in ipairs(Players:GetPlayers()) do
		task.spawn(Profils.playerJoined,Profils,players)
	end
	remoteLoader:ConnectSingleEvent(ReplicatedStorage.Packages.Menu.Setting.setting_Option.DragClockTime._drag.GetLastClockTimer,false,changeData)
	remoteLoader:ConnectSingleEvent(ReplicatedStorage.Packages.Remotes._remote.AutoLoadSettingsValue,false,changeData)
	remoteLoader:ConnectSingleEvent(ReplicatedStorage.Packages.Remotes._remote:WaitForChild('AutomaticSettingsLoad'),true,CurrentStats)
	remoteLoader:ConnectSingleEvent(Knit.Util.Remotes._remote.InventoryLoaded,false,setInventoryItemToData)
	remoteLoader:ConnectSingleEvent(Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].__bindable.ClientService.RemoveItem,false,OnComponentRemoved)
	local function loadedComponent(player)
		Profils:playerJoined(player)
		local function leaderstats()
			local leaderstats = Instance.new("Folder",player)
			leaderstats.Name = "leaderstats"
			local Minute = Instance.new("IntValue",leaderstats)
			Minute.Name = "Minute(s)"
			Minute.Value = ProfilesComponents.ProfilesAttach[player.UserId].Data.Settings.leaderstats.Minutes
			local Argents = Instance.new("IntValue",leaderstats)
			Argents.Value = ProfilesComponents.ProfilesAttach[player.UserId].Data.Settings.leaderstats.Argents
			Argents.Name = "Argent(s)"
		end
		local loadInventoryEvent = loadBindable(player)
		task.spawn(leaderstats)
		return "ProfilService Started for : <("..player.DisplayName..")>"
	end
	local function removedComponent(player)
		local profil = ProfilesComponents.ProfilesAttach[player.UserId]
		if not profil then return end
		return profil:Release()
	end
	local ReleaseInventoryPromise = ReleaseBindable()
	ProfilsTask:giveTask(Players.PlayerAdded:Connect(loadedComponent))
	ProfilsTask:giveTask(Players.PlayerRemoving:Connect(removedComponent))
end

return Profils
