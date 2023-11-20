local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ClientComm = require(ReplicatedStorage.Packages.Comm).ClientComm
local clientComm = ClientComm.new(ReplicatedStorage.Packages, false, "ServerListService")
local comm = clientComm:BuildObject()

local Maid = require(ReplicatedStorage.Packages.Maid)
local Promise = require(ReplicatedStorage.Packages.Promise)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerScript = player:WaitForChild("PlayerScripts")
local MainRequirementUi = playerGui:WaitForChild("MainRequirementUi")
local coutainer = MainRequirementUi:WaitForChild("coutainer")
local Items = coutainer:WaitForChild("Items")
local ScrollingFrameForServerList = Items.servers.TitlesInventory.ScrollingFrame

local function templateFrameCloned()
	return script.Parent.Template.ServerNameFrame:Clone()
end

local function templateFriendsLabel()
	return script.Parent.Template.FriendsImages.ImageLabel:Clone()
end

local friendsList = {
	[player.UserId] = {}
}


local function loop()
	while true do
		local list = comm:GetServerForPlayers()
		if (type(list) == "table") then
			for i,v in pairs(list) do
				if type(v[i]) == "table" then
					local newlist = v[i]
					if (#newlist.FriendsInThisServer>0) then
						for index,id in pairs(newlist.FriendsInThisServer) do
							if (player:IsFriendsWith(id)) then
								if not (table.find(friendsList[player.UserId],id)) then
									table.insert(friendsList[player.UserId],id)
								end	
							end
						end
					end
				end				
			end			
		end
		task.wait(5)
	end
end

task.spawn(loop)


ReplicatedStorage.Packages.Menu.Configuration.Servers.ServerToClientAsync.OnClientEvent:Connect(function(Type,job,maxPlayer,place,region)
	local maid = Maid.new()
	if (Type == "remove") then
		for i,v in ScrollingFrameForServerList:GetChildren() do
			if v:GetAttribute("ServerID") == job then
				v:Destroy()
			end
		end
		if (maid) then
			maid:clean()
		end
	elseif (Type == "add") then
		for i,v in ScrollingFrameForServerList:GetChildren() do
			if v:GetAttribute("ServerID") == job then
				v:Destroy()
			end
			if (maid) then
				maid:clean()
			end
		end
		
				
		local addFrame = templateFrameCloned()
		addFrame.Parent = ScrollingFrameForServerList
		addFrame.Name = tostring(job)
		addFrame:SetAttribute("ServerID",job)
		
		if (not maid) then
			maid = Maid.new()
		else
			maid = Maid.new()
		end
		
		local numberFrame = 0
		for i,v in ScrollingFrameForServerList:GetChildren() do
			if (v:IsA("UIListLayout")) then
				continue
			end
			numberFrame += 1
		end
		
		local getFriend_N = #friendsList[player.UserId]
		
		if getFriend_N>0 then
			for i,friendId in ipairs(friendsList[player.UserId]) do
				if player:IsFriendsWith(friendId) then
					local image = templateFriendsLabel()
					image.Parent = addFrame.CanvasGroup
					image.Image = Players:GetUserThumbnailAsync(friendId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size420x420)
					
					task.delay(.35,function()
						if image.Image == "" then
							image.Image = Players:GetUserThumbnailAsync(friendId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size420x420)
						end
					end)
					
					image.Name = Players:GetNameFromUserIdAsync(friendId)
				end
			end
		end
		
		addFrame:WaitForChild("ServerIDLabel").Text = job
		addFrame:WaitForChild("FriendsInServer").Text = "Amis sur le serveur : ("..getFriend_N..")"
		addFrame:WaitForChild("ServerNameLabel").Text = "Serveur , Ville : ("..region.city..") ".." Pays : ("..region.country..")".." Region : ("..region.regionName..")"
		
		maid:giveTask(addFrame:WaitForChild("JoinButtons").MouseEnter:Connect(function()
			SoundService:PlayLocalSound(SoundService["RBLX UI Hover 03 (SFX)"])
			TweenService:Create(addFrame:WaitForChild("JoinButtons"),TweenInfo.new(.15),{BackgroundTransparency = 0,BackgroundColor3 = Color3.new(1,1,1)}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons").UIScale,TweenInfo.new(.15),{Scale = .95}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons"):FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons").UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
		end))
		
		maid:giveTask(addFrame:WaitForChild("JoinButtons").MouseLeave:Connect(function()
			TweenService:Create(addFrame:WaitForChild("JoinButtons"),TweenInfo.new(.15),{BackgroundTransparency = 0.35,BackgroundColor3 = Color3.new(0.20,0.20,0.20)}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons").UIScale,TweenInfo.new(.15),{Scale = 1}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons"):FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextColor3 = Color3.new(1,1,1)}):Play()
			TweenService:Create(addFrame:WaitForChild("JoinButtons").UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
		end))
		
		maid:giveTask(addFrame:WaitForChild("JoinButtons"):FindFirstChildOfClass("TextButton").MouseButton1Down:Connect(function()
			SoundService:PlayLocalSound(SoundService.ui_mission_tick)
			return TeleportService:TeleportToPlaceInstance(game.PlaceId,job)
		end))
		
		
		maid:giveTask(TeleportService.TeleportInitFailed:Connect(function()
			return Promise.new(function(resolve,reject,onCancel)
				warn("TeleportServiceError : [Main Teleportation] : Result : (failed) [<"..`{debug.traceback("__traceReturn",2)}>]`)
			end):catch(warn)
		end))
		
	end
end)
