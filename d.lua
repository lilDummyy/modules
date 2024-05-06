local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local MarketPlaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Thread = require(ReplicatedStorage.Packages.Thread)
local Option = require(ReplicatedStorage.Packages.Option)
local ProfilesAttach = require(ServerScriptService.Server_Refs.Profiles.DataComponent.ProfilesComponents).ProfilesAttach

local module = Knit.CreateService{
	Name = "CookingSystem|PathfindingSystem",
	Client = {
		AnimationUiSignal = Knit.CreateSignal(),
	},
}

local function CreateCollection(player)
	CollectionService:AddTag(player,`{player.UserId}..CollectionTag`)
end

local function CreateTableCollection(player)
	CollectionService:AddTag(nil,`{player.UserId}..CollectionTag@Table`)
end

local function CreateNPCCollection(player)
	CollectionService:AddTag(player,`{player.UserId}..CollectionNpcTag`)
end

local function HowManyTableHasBeenReleased(player):number
	local count = 0
	for i,v in pairs(CollectionService:GetTagged(`{player.UserId}..CollectionTag@Table`)) do
		count += 1
	end
	return count
end

local function PlayerFriends(player)
	local t = {}
	local succes, page = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if (succes) then
		repeat
			local info = page:GetCurrentPage()
			for i,friendInfo in pairs(info) do
				table.insert(t,friendInfo.Id)
			end
			if not page.IsFinished then
				page:AdvanceToNextPageAsync()
			end
		until page.IsFinished
	end
	return t
end

local function LoadRandomFriend(player)
	local Friends = PlayerFriends(player)
	local getFriendId = Friends[math.random(1,#Friends)]
	return getFriendId
end

local function CreateRandomCommand(t)
	local flavorType = "none"
	if (t) then
		if #t > 0 then
			local _index = t[math.random(1,#t)]
			flavorType = _index.Name
		end
	end
	return flavorType
end

local function CreateToolGiver(character)
	if (character) then
		local cloneGlassCup = ReplicatedStorage.Packages.Lib.Instance:FindFirstChild("Glass Cup"):Clone()
		cloneGlassCup.Anchored = false
		cloneGlassCup.Parent = character
		cloneGlassCup.CanCollide = false
		local motor6D = Instance.new("Motor6D",cloneGlassCup)
		motor6D.Part0 = character:WaitForChild("HumanoidRootPart")
		motor6D.Part1 = cloneGlassCup
		motor6D.C1 = CFrame.new(0,0,3) * CFrame.fromEulerAnglesXYZ(0,0,math.rad(90))
	end
end

local function makeToolForRig(rig:Model,GlassCup)
	if (rig) then
		for i,motor in GlassCup:GetDescendants() do
			if motor:IsA("Motor6D") then
				motor:Destroy()
			end
		end
		
		local rad = math.rad
		local toolAnim = Instance.new("Animation",rig)
		toolAnim.AnimationId = "http://www.roblox.com/asset/?id=507768375"
		toolAnim.Name = "ToolsAnimation"
		
		local tool = Instance.new("Tool",rig)
		tool.Enabled = true
		tool.Grip = tool.Grip * CFrame.Angles(rad(-86.07), rad(-161.227), rad(75.509))
		
		local cloneGlassCup = GlassCup:Clone()
		cloneGlassCup.Anchored = false
		cloneGlassCup.Parent = tool
		cloneGlassCup.Name = "Handle"
		cloneGlassCup.CanCollide = false
		local hum = rig:FindFirstChildOfClass("Humanoid")
		hum:EquipTool(tool)
		hum:LoadAnimation(toolAnim):Play()
		
	end
end

local function FindToolGiver(character)
	if (character) then
		if (character:FindFirstChild("Glass Cup")) then
			return character:FindFirstChild("Glass Cup")
		else
			return false
		end
	end
end

function module:FindOriginalPoint(player,point)
	if not self[player.UserId.."_OriginalPoint"] then
		if (point) then
			self[player.UserId.."_OriginalPoint"] = point
			return self[player.UserId.."_OriginalPoint"]
		end
	else
		return nil
	end
end

function module:GetOriginalPoint(player)
	return self[player.UserId.."_OriginalPoint"] or nil
end

function module:UpdatePlayerFlavor(player,flavor)
	if not self[player.UserId.."flavor"] then
		self[player.UserId.."flavor"] = {}
		for i,fl in pairs(flavor) do
			if (fl) then
				if not table.find(self[player.UserId.."flavor"],fl) then
					table.insert(self[player.UserId.."flavor"],fl)
				else
				end
			end
		end
	else
		for i,fl in pairs(flavor) do
			if (fl) then
				if not table.find(self[player.UserId.."flavor"],fl) then
					table.insert(self[player.UserId.."flavor"],fl)
				else
				end
			end
		end
	end
end

function module:AddTableToPlayerCollection(player,tycoon)
	if (tycoon) then
		local getTableFolder = tycoon:FindFirstChild(tycoon.Name)
		if (getTableFolder) then
			for _,model in getTableFolder:GetChildren() do
				if model:IsA("Model") then
					for i,seat in model:GetDescendants() do
						if seat:IsA("Seat") then
							if (CollectionService:HasTag(seat,`{player.UserId}..CollectionTag@Table`) == false) then
								CollectionService:AddTag(seat,`{player.UserId}..CollectionTag@Table`)
							end
						end
					end
				end
			end
		end
	end
end

function module:AutoUpdateTableCollection(player,tycoon)
	if (tycoon) then
		local getTableFolder = tycoon:FindFirstChild(tycoon.Name)
		if (getTableFolder) then
			if self[player.UserId.."promiseForChildAddedConnection"]  then return end
			self[player.UserId.."promiseForChildAddedConnection"] = false
			self[player.UserId.."lockSignal"] = false
			self[player.UserId.."promiseForChildAddedConnection"] = Promise.new(function(resolve,reject,onCancel)
				local rbx = getTableFolder.ChildAdded:Connect(function(instance)
					if (instance:IsA("Model")) then
						for i,seat in instance:GetDescendants() do
							if seat:IsA("Seat") then
								if (CollectionService:HasTag(seat,`{player.UserId}..CollectionTag@Table`) == false) then
									CollectionService:AddTag(seat,`{player.UserId}..CollectionTag@Table`)
								end
							end
						end
					end
				end)
				
				local _holder_rbx_v = CollectionService:GetInstanceRemovedSignal(`{player.UserId}..CollectionTag@Table`):Connect(function(...)
					if HowManyTableHasBeenReleased(player) <= 0 then
						self[player.UserId.."lockSignal"] = true
						Thread.Delay(2,function()
							self.Client.AnimationUiSignal:Fire(player,"All table has been taken, please wait",Color3.new(0.917647, 0.611765, 0),Color3.new(0.666667, 0, 0),"Warning")
						end)
					end
				end)
				
				onCancel(function()
					rbx:Disconnect()
					rbx = nil
					_holder_rbx_v:Disconnect()
					_holder_rbx_v = nil
					self[player.UserId.."promiseForChildAddedConnection"] = nil
				end)
			end):catch(warn)
		end
	end
end

function module:RemoveFlavorFromPlayer(player,flavor)
	if self[player.UserId.."flavor"] then
		for i,fl in pairs(flavor) do
			if table.find(self[player.UserId.."flavor"],fl) then
				table.remove(self[player.UserId.."flavor"],table.find(self[player.UserId.."flavor"],fl))
			else
				continue
			end
		end
	end
end

function module:ShouldLoadCollectionInstanceAddedSignal(player)
	if not self[player.UserId.."CollectionInstance"] then
		self[player.UserId.."CollectionInstance"] = Promise.new(function(resolve,reject,onCancel)
			local rbx 
			rbx = CollectionService:GetInstanceAddedSignal(`{player.UserId}_Flavors`):Connect(function(...)
				self:UpdatePlayerFlavor(player,{...})
			end)
			
			onCancel(function()
				rbx:Disconnect()
				rbx = nil
			end)
		end):catch(warn)
		return self[player.UserId.."CollectionInstance"]
	end
end

function module:ShouldLoadCollectionInstanceRemovedSignal(player)
	if not self[player.UserId.."CollectionRemovedInstance"] then
		self[player.UserId.."CollectionRemovedInstance"] = Promise.new(function(resolve,reject,onCancel)
			local rbx 
			rbx = CollectionService:GetInstanceRemovedSignal(`{player.UserId}_Flavors`):Connect(function(...)
				self:RemoveFlavorFromPlayer(player,{...})
			end)
			
			onCancel(function()
				rbx:Disconnect()
				rbx = nil
			end)
		end):catch(warn)
		return self[player.UserId.."CollectionRemovedInstance"]
	end
end

function module:Create(player,point,tycoon)
	if (player) then
		CreateCollection(player)
		CreateTableCollection(player)
		CreateNPCCollection(player)
		if not self[player.UserId.."_signal"] then
			self:ShouldLoadCollectionInstanceAddedSignal(player)
			self:ShouldLoadCollectionInstanceRemovedSignal(player)
			self:AddTableToPlayerCollection(player,tycoon)
			self:AutoUpdateTableCollection(player,tycoon)
			self:UpdatePlayerFlavor(player,CollectionService:GetTagged(`{player.UserId}_Flavors`))
			
			self[player.UserId.."_signal"] = Signal.new()
			self[player.UserId.."tycoon"] = tycoon
			
			local getOriginalPoint = self:FindOriginalPoint(player,point)
			self:SignalMarkerConnection(player,tycoon)

			if (getOriginalPoint ~= nil) then
				if not self[player.UserId.."PointPosition"] then
					self[player.UserId.."PointPosition"] = getOriginalPoint.Position
				end
				
				local promiseForRigBuilder = Promise.delay(5):andThenCall(function()
					local cf = getOriginalPoint.Position +  getOriginalPoint.CFrame.LookVector * -45
					local getRandomFriendId = LoadRandomFriend(player)
					local ShouldGetAHumanoidDescription 

					local s,e = pcall(function()
						ShouldGetAHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(getRandomFriendId)
					end)
					
					local getNameFromId = Players:GetNameFromUserIdAsync(getRandomFriendId)
					
					if (ShouldGetAHumanoidDescription) and (s) then
						local rig = ReplicatedStorage.Packages.Rig:Clone()
						rig.Parent = tycoon
						rig.Name = tostring(HttpService:GenerateGUID(false))

						for i, part in rig:GetDescendants() do
							if part:IsA("BasePart") then
								part.CollisionGroup = "NPC"
							end
						end
						
						self.Client.AnimationUiSignal:Fire(player,"@"..getNameFromId.." has entered to your restaurant",Color3.new(1,1,1),Color3.new(0,0,0),"Welcome")

						rig:PivotTo(CFrame.new(cf))

						if not self[player.UserId.. "/" .. rig.Name] then
							self[player.UserId.. "/" .. rig.Name] = {
								model = rig,
								CurrentWalksSpeed = rig.Humanoid.WalkSpeed,
								DefaultCFrame = rig:GetPivot(),
								DefaultPosition = rig.PrimaryPart.Position,
								readyToStartPathfinding = true,
								animations = {
									WalkAnimations = "http://www.roblox.com/asset/?id=507777826",
									IdleAnimations = "http://www.roblox.com/asset/?id=507766666",
									JumpAnimations = "http://www.roblox.com/asset/?id=507765000",
									SeatAnimations = "http://www.roblox.com/asset/?id=2506281703",
								},
								sitted = false,
								orderClaimed = false,
								isFirstOnCommand = false
							}
						end
						
						if CollectionService:HasTag(rig,`{player.UserId}..CollectionNpcTag`) == false then
							CollectionService:AddTag(rig,`{player.UserId}..CollectionNpcTag`)
						end

						Thread.Delay(0.05,function()
							Promise.new(function()
								rig.Humanoid:ApplyDescription(ShouldGetAHumanoidDescription)
								if self[player.UserId.. "/" .. rig.Name].readyToStartPathfinding == true then
									self:ComputeRigPathfinding(player,rig,tycoon)
								end
							end):catch(warn)
						end)
						
					end
				end):catch(warn)
			end			
		end
	end
end

function module:SignalMarkerConnection(player,tycoon)
	if self[player.UserId.."_signal"] then
		if not self[player.UserId.."_signalMarker"] then
			self[player.UserId.."_signalMarker"] = self[player.UserId.."_signal"]:Connect(function()	
				local promiseForRigBuilder = Promise.new(function()
					local getOriginalPoint = self:GetOriginalPoint(player)
					if not getOriginalPoint then return end
					local cf = getOriginalPoint.Position + getOriginalPoint.CFrame.LookVector * -45
					
					local getRandomFriendId = LoadRandomFriend(player)
					local ShouldGetAHumanoidDescription 
					
					local s,e = pcall(function()
						ShouldGetAHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(getRandomFriendId)
					end)
					
					local getNameFromId = Players:GetNameFromUserIdAsync(getRandomFriendId)
					
					if (ShouldGetAHumanoidDescription) and (s) then
						local rig = ReplicatedStorage.Packages.Rig:Clone()
						rig.Parent = tycoon
						rig.Name = tostring(HttpService:GenerateGUID(false))

						for i, part in rig:GetDescendants() do
							if part:IsA("BasePart") then
								part.CollisionGroup = "NPC"
							end
						end
						
						self.Client.AnimationUiSignal:Fire(player,"@"..getNameFromId.." has entered to your restaurant",Color3.new(1,1,1),Color3.new(0,0,0),"Welcome")
						rig:PivotTo(CFrame.new(cf))

						if not self[player.UserId.. "/" .. rig.Name] then
							self[player.UserId.. "/" .. rig.Name] = {
								model = rig,
								CurrentWalksSpeed = rig.Humanoid.WalkSpeed,
								DefaultCFrame = rig:GetPivot(),
								DefaultPosition = rig.PrimaryPart.Position,
								readyToStartPathfinding = true,
								animations = {
									WalkAnimations = "http://www.roblox.com/asset/?id=507777826",
									IdleAnimations = "http://www.roblox.com/asset/?id=507766666",
									JumpAnimations = "http://www.roblox.com/asset/?id=507765000",
									SeatAnimations = "http://www.roblox.com/asset/?id=2506281703",
								},
								sitted = false,
								orderClaimed = false,
								isFirstOnCommand = false
							}
						end
						
						if CollectionService:HasTag(rig,`{player.UserId}..CollectionNpcTag`) == false then
							CollectionService:AddTag(rig,`{player.UserId}..CollectionNpcTag`)
						end
						
						Thread.Delay(0.05,function()
							Promise.new(function()
								rig.Humanoid:ApplyDescription(ShouldGetAHumanoidDescription)
								if self[player.UserId.. "/" .. rig.Name].readyToStartPathfinding == true then
									self:ComputeRigPathfinding(player,rig,tycoon)
								end
							end):catch(warn)
						end)
		
					end
				end):catch(warn):finally(function()
					
				end)
			end)
			
		end 
	end
end

function module:Remove(player)
	if (player) then
		local succes , error = pcall(function()
			CollectionService:RemoveTag(player,`{player.UserId}..CollectionTag`)
		end)		
		if (succes) then
			if self[player.UserId.."_signal"] then
				self[player.UserId.."_signal"] = nil
				if self[player.UserId.."rigInPath"] then
					local OriginalPoint = self:GetOriginalPoint(player)

					Thread.SpawnNow(function()
						for i,rig in self[player.UserId.."rigInPath"] do
							if (rig) then
								if self[player.UserId.."/"..rig.Name] then
									self[player.UserId.."/"..rig.Name] = nil
								end
							end
						end
					end)
					
					Thread.SpawnNow(function()
						for i,rig in CollectionService:GetTagged(`{player.UserId}..CollectionNpcTag`) do
							if rig then
								if self[player.UserId.."/"..rig.Name] then
									table.clear(self[player.UserId.."/"..rig.Name])
									self[player.UserId.."/"..rig.Name] = nil
								end
								CollectionService:RemoveTag(rig,`{player.UserId}..CollectionNpcTag`)
							end
						end
					end)
					
					if self[player.UserId.."_signalMarker"] then
						self[player.UserId.."_signalMarker"]:Disconnect()
						self[player.UserId.."_signalMarker"] = nil
					end
					
					Thread.SpawnNow(function()
						for i,model in CollectionService:GetTagged(`{player.UserId}..CollectionTag@Table`) do
							if (CollectionService:HasTag(model,`{player.UserId}..CollectionTag@Table`)) then
								CollectionService:RemoveTag(model,`{player.UserId}..CollectionTag@Table`)
							end
						end
					end)
					
					if (OriginalPoint) then
						OriginalPoint.Position = self[player.UserId.."PointPosition"]
						self[player.UserId.."_OriginalPoint"] = nil
						OriginalPoint = nil	
					end
					
					table.clear(self[player.UserId.."rigInPath"])
					table.clear(self[player.UserId.."flavor"])
					
					if self[player.UserId.."CreateProximity"] then
						self[player.UserId.."CreateProximity"]:Destroy()
						self[player.UserId.."CreateProximity"] = nil
					end
					
					self[player.UserId.."lockSignal"] = nil
					self[player.UserId.."flavor"] = nil
					self[player.UserId.."_Owner@"..self[player.UserId.."tycoon"].Name] = nil
					self[player.UserId.."rigInPath"] = nil
					self[player.UserId.."PointPosition"] = nil
					self[player.UserId.."CollectionRemovedInstance"]:cancel()
					self[player.UserId.."CollectionInstance"]:cancel()
					self[player.UserId.."promiseForChildAddedConnection"]:cancel()
					self[player.UserId.."CollectionInstance"] = nil
					self[player.UserId.."CollectionRemovedInstance"] = nil
					self[player.UserId.."tycoon"] = nil
					
					for i,qt in self do
						if i == string.match(tostring(i),tostring(player.UserId)) then
							if self[i] then
								table.clear(self[i])
								self[i] = nil
							end
						elseif i == string.find(i,tostring(player.UserId)) then
							if self[i] then
								table.clear(self[i])
								self[i] = nil
							end
						elseif string.find(i,tostring(player.UserId)) then
							if self[i] then
								table.clear(self[i])
								self[i] = nil
							end
						end
					end
					
				end
				print(self)
			end
		end
	end
end

function module:KnitStart()
	self._PlayerRemovedPromise = Promise.new(function(resolve,reject,onCancel)
		local plrRemovedConnection
		plrRemovedConnection = Players.PlayerRemoving:Connect(function(player)
			self:Remove(player)
		end)
	end):catch(warn)
end

function module:ComputeRigPathfinding(player,rig,tycoon)
	
	if not (player) or not (rig) then return end
	if not self[player.UserId.."rigInPath"] then
		self[player.UserId.."rigInPath"] = {}
	end

	local humanoid = rig:WaitForChild("Humanoid")
	local humanoidRootPart = rig:WaitForChild("HumanoidRootPart")

	local WalkAnimations = Instance.new("Animation",rig)
	local IdleAnimations = Instance.new("Animation",rig)
	local JumpAnimations = Instance.new("Animation",rig)
	local SeatAnimations = Instance.new("Animation",rig)

	WalkAnimations.Name = "WalkAnimations"
	IdleAnimations.Name = "IdleAnimations"
	JumpAnimations.Name = "JumpAnimations"
	SeatAnimations.Name = "SeatAnimations"

	WalkAnimations.AnimationId = self[player.UserId.. "/" .. rig.Name].animations.WalkAnimations
	IdleAnimations.AnimationId = self[player.UserId.. "/" .. rig.Name].animations.IdleAnimations
	JumpAnimations.AnimationId = self[player.UserId.. "/" .. rig.Name].animations.JumpAnimations
	SeatAnimations.AnimationId = self[player.UserId.. "/" .. rig.Name].animations.SeatAnimations

	local createPath = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 6,
		AgentCanJump = true,
	})

	local succes , pathMalformed = pcall(function()
		createPath:ComputeAsync(humanoidRootPart.Position,self:GetOriginalPoint(player).Position)
	end)
	
	local currentWaypoints = 1
	local waypoints = createPath:GetWaypoints()	
	
	if (succes) then
		local reachedConnection 

		local idleTrack
		local walkTrack
		local jumpTrack

		humanoid:MoveTo(waypoints[currentWaypoints].Position)

		walkTrack = humanoid:LoadAnimation(WalkAnimations)
		walkTrack:Play()

		reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
			if reached and currentWaypoints < #waypoints then
				if waypoints[currentWaypoints].Action == Enum.PathWaypointAction.Jump then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
				currentWaypoints += 1					
				humanoid:MoveTo(waypoints[currentWaypoints].Position)
			else
				if walkTrack then
					walkTrack:Stop()
					walkTrack = nil
					idleTrack = humanoid:LoadAnimation(IdleAnimations)
					idleTrack:Play()
				else
					idleTrack = humanoid:LoadAnimation(IdleAnimations)
					idleTrack:Play()
				end
				if not table.find(self[player.UserId.."rigInPath"],rig) then
					table.insert(self[player.UserId.."rigInPath"],rig)
				end
				self:GetOriginalPoint(player).Position = self:GetOriginalPoint(player).Position + self:GetOriginalPoint(player).CFrame.LookVector * -5
				reachedConnection:Disconnect()
				if not tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then
					if not self[player.UserId.."_Owner@"..tycoon.Name]  then
						self[player.UserId.."_Owner@"..tycoon.Name] = player
					end
					self:CreateCommand(player,rig,tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart,tycoon)
				end
			end
		end)
	else
		rig:Destroy()
		warn(pathMalformed,debug.traceback("Pathfinding failed for: @_"..rig.Name,2))
	end
end

function module:CreateBlenderProximity(player,rig,flavor,tycoon)
	local DefaultTycoonFlavor = tycoon:FindFirstChild(tycoon.Name.."|Flavors")
	local CurrentTycoonFlavor = tycoon:FindFirstChild("Flavors")
	local TycoonBlender = tycoon:FindFirstChild(tycoon.Name.."|Blender")
	
	if (TycoonBlender) then
		local Blender = TycoonBlender:FindFirstChild("Blender")
		if (Blender) then
			local ParticlePart = Blender.ParticlePart
			local ParticleEmitter = ParticlePart.ParticleEmitter
			self[player.UserId.."CreateProximity"] = Instance.new("ProximityPrompt",ParticlePart:FindFirstChild("Attachment"))
			self[player.UserId.."CreateProximity"].ActionText = "Use"
			self[player.UserId.."CreateProximity"].ObjectText = ""
			self[player.UserId.."CreateProximity"].KeyboardKeyCode = "F"
			
			local LockBlender = false
			
			local ProxyTriggered 
			
			ProxyTriggered = Promise.new(function(resolve,reject,onCancel)
				local trigger = self[player.UserId.."CreateProximity"].Triggered:Connect(function(whoTriggered)
					if (self[player.UserId.."_Owner@"..tycoon.Name] == whoTriggered) then
						if LockBlender == true then return end
						local Cup = FindToolGiver(whoTriggered.Character)
						if (Cup) then
							Cup.Parent = ServerStorage
							ParticleEmitter:Emit(5)
							ParticleEmitter.Enabled = true
							LockBlender = true
							self[player.UserId.."CreateProximity"].Enabled = false
							
							Thread.Delay(5,function()
								ParticleEmitter.Enabled = false
								Cup.Parent = whoTriggered.Character
								ProxyTriggered:cancel()
							end)
						end
					end
				end)
				
				onCancel(function()
					if (tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart) then
						if tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then
							local proxi = tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
							if proxi.Enabled == false then
								proxi.Enabled = true
							end
							
							self[player.UserId.."CreateProximity"] = nil
							
							trigger:Disconnect()
							trigger = nil
							
							local ProxyPromise 
							ProxyPromise = Promise.new(function(resolve,reject,cancelled)
								local connection 
								connection = proxi.Triggered:Connect(function(plr)
									if self[player.UserId.."_Owner@"..tycoon.Name] == plr then
										local Cup = FindToolGiver(plr.Character)
										if (Cup) then
											connection = nil
											ProxyPromise:cancel()
										end
									end
								end)
								
								cancelled(function()
									if HowManyTableHasBeenReleased(player) > 0 then
										local Cup = FindToolGiver(player.Character)
										if (Cup) then
											makeToolForRig(rig,Cup)
											Cup:Destroy()
										end
										
										local GetARandomSeat = CollectionService:GetTagged(`{player.UserId}..CollectionTag@Table`)[math.random(1,#CollectionService:GetTagged(`{player.UserId}..CollectionTag@Table`))]
										if (GetARandomSeat) then
											GetARandomSeat.CanCollide = false
											if CollectionService:HasTag(GetARandomSeat,`{player.UserId}..CollectionTag@Table`) then
												CollectionService:RemoveTag(GetARandomSeat,`{player.UserId}..CollectionTag@Table`)
											end
											self:MooveRigToASeat(player,rig,GetARandomSeat)
											if tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then
												tycoon:FindFirstChild(tycoon.Name.."|Counter").PrincipalCounter.Cashier.PrimaryPart:FindFirstChildOfClass("ProximityPrompt"):Destroy()
											end
											local cashGained = math.random(100,350)
											self.Client.AnimationUiSignal:Fire(player,"Order successful, cash gained: "..tostring(cashGained).."$",Color3.new(0.333333, 1, 0.498039),Color3.new(0, 0, 0),"Succes")
											if (player:FindFirstChild("leaderstats")) then
												player:FindFirstChild("leaderstats"):FindFirstChild("Cash").Value += cashGained
											end
											
											self:GetOriginalPoint(player).Position = self:GetOriginalPoint(player).Position + self:GetOriginalPoint(player).CFrame.LookVector * 5
											if HowManyTableHasBeenReleased(player) <= 0 then
											else
												if self[player.UserId.."_signal"] then
													self[player.UserId.."_signal"]:Fire()
												end
											end
										end
									else

									end
								end)
							end):catch(warn)
							
						end
					end
				end)
			end):catch(warn)
			
		end	
	end
end

function module:MooveRigToASeat(player,rig,seat)
	local hum = rig:FindFirstChild("Humanoid")
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	
	if (hum) and (hrp) then
		local WalkAnimations = rig:FindFirstChild("WalkAnimations")
		local SeatAnimations = rig:FindFirstChild("SeatAnimations")
		
		if CollectionService:HasTag(rig,`{player.UserId}..CollectionNpcTag`) then
			CollectionService:RemoveTag(rig,`{player.UserId}..CollectionNpcTag`)
			if self[player.UserId.."/"..rig.Name] then
				table.clear(self[player.UserId.."/"..rig.Name])
				self[player.UserId.."/"..rig.Name] = nil
			end
		end

		local idleTrack
		local walkTrack
		local jumpTrack
		
		local countSeat = HowManyTableHasBeenReleased(player)

		idleTrack = hum:LoadAnimation(SeatAnimations)
		idleTrack:Play()
		hrp.Anchored = true
		hrp.CFrame = seat.CFrame * CFrame.new(0,1.5,0)
		hum.Sit = true
		Promise.delay(50):andThenCall(function()
			if (rig) then
				if not self[player.UserId.."rigInPath"] then return end
				if table.find(self[player.UserId.."rigInPath"],rig) then
					table.remove(self[player.UserId.."rigInPath"],table.find(self[player.UserId.."rigInPath"],rig))
					rig:Destroy()
					if self[player.UserId.."lockSignal"] == true then
						if self[player.UserId.."_signal"] then
							self[player.UserId.."_signal"]:Fire()
							self[player.UserId.."lockSignal"] = false
						end
					end
					if CollectionService:HasTag(seat,`{player.UserId}..CollectionTag@Table`) == false then
						CollectionService:AddTag(seat,`{player.UserId}..CollectionTag@Table`)
					end
				end
			end
		end):catch(warn)
	end
end

function module:NextStepForCurrentCommand(player,rig,flavor,tycoon)
	local DefaultTycoonFlavor = tycoon:FindFirstChild(tycoon.Name.."|Flavors")
	local CurrentTycoonFlavor = tycoon:FindFirstChild("Flavors")
	
	local CurrentModel = nil
	
	if DefaultTycoonFlavor:FindFirstChild(flavor) then
		CurrentModel = DefaultTycoonFlavor:FindFirstChild(flavor)
		local attachment = CurrentModel.Tittle:FindFirstChildOfClass("Attachment")
		
		if (attachment) then
			local proximity = Instance.new("ProximityPrompt",attachment)
			proximity.ActionText = "Insert"
			proximity.ObjectText = flavor
			proximity.HoldDuration = 0.2
			
			local ProxyTriggered 

			ProxyTriggered = Promise.new(function(resolve,reject,onCancel)
				local trigger = proximity.Triggered:Connect(function(whoTriggered)
					if (self[player.UserId.."_Owner@"..tycoon.Name] == whoTriggered) then
						local Cup = FindToolGiver(whoTriggered.Character)
						if (Cup) then
							Cup.FlavorPart.Transparency = 0
							Cup.FlavorPart.Color = CurrentModel.Tittle.Color
							proximity.Enabled = false
							ProxyTriggered:cancel()
						end
					end
				end)
				
				onCancel(function()
					self:CreateBlenderProximity(player,rig,flavor,tycoon)
				end)
			end):catch(warn)
			
		end
	elseif CurrentTycoonFlavor:FindFirstChild(flavor) then
		CurrentModel = CurrentTycoonFlavor:FindFirstChild(flavor)		
		local attachment = CurrentModel.Tittle:FindFirstChildOfClass("Attachment")

		if (attachment) then
			local proximity = Instance.new("ProximityPrompt",attachment)
			proximity.ActionText = "Insert"
			proximity.ObjectText = flavor
			proximity.HoldDuration = 0.2
			proximity.KeyboardKeyCode = "F"

			local ProxyTriggered 
			
			ProxyTriggered = Promise.new(function(resolve,reject,onCancel)
				local trigger = proximity.Triggered:Connect(function(whoTriggered)
					if (self[player.UserId.."_Owner@"..tycoon.Name] == whoTriggered) then
						local Cup = FindToolGiver(whoTriggered.Character)
						if (Cup) then
							Cup.FlavorPart.Transparency = 0
							Cup.FlavorPart.Color = CurrentModel.Tittle.Color
							proximity.Enabled = false
							ProxyTriggered:cancel()
						end
					end
				end)
				
				onCancel(function()
					self:CreateBlenderProximity(player,rig,flavor,tycoon)
				end)
			end):catch(warn)
			
		end
	else
		print("failed")
	end
end

function module:CreateCommand(player,rig,parent,tycoon)
	local proximity = Instance.new("ProximityPrompt",parent)
	proximity.ActionText = "Take"
	proximity.ObjectText = "Command"
	proximity.HoldDuration = 0.2
	proximity.KeyboardKeyCode = "F"
	
	local LockedCommand = false
	
	local ProxyTriggered 
	ProxyTriggered = Promise.new(function(resolve,reject,onCancel)
		local trigger 
		trigger = proximity.Triggered:Connect(function(whoTriggered)
			if (self[player.UserId.."_Owner@"..tycoon.Name] == whoTriggered) then
				if LockedCommand == true then return end
				proximity.Enabled = false
				LockedCommand = true
				CreateToolGiver(whoTriggered.Character)
				ProxyTriggered:cancel()
			else
				warn("your are not the owner")
			end
		end)
		
		onCancel(function()
			local flavor = CreateRandomCommand(self[player.UserId.."flavor"])
			if (flavor ~= "none") then
				self:NextStepForCurrentCommand(player,rig,flavor,tycoon)
			end
			trigger:Disconnect() 
			LockedCommand = false
			trigger = nil
		end)
	end):catch(warn)
end

function module.Client:Create(player,point,tycoon)
	return self.Server:Create(player,point,tycoon)
end

return module
