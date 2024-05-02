--NPC , cooking system [Client]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Thread = require(ReplicatedStorage.Packages.Thread)
local Option = require(ReplicatedStorage.Packages.Option)
local Quaternion = require(ReplicatedStorage.Packages.Quaternion)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UI_IMAGE_CONFIG = require(ReplicatedStorage.Packages.Lib.UI_IMAGE_CONFIG)
local Value = Fusion.Value
local Observer = Fusion.Observer

local PlayerTakeOrderModule = {}
PlayerTakeOrderModule.__index = PlayerTakeOrderModule

PlayerTakeOrderModule.global_ingredients = {
	[1] = "Apple",
	[2] = "Orange",
	[3] = "Strawberry"
}

local function CreateRandomTakeOrderTable(self)
	local ingredients = {
		current_global_ingredients = "none",
	}
	
	local randomNumber = math.random(1,#self.global_ingredients)
	
	if self.global_ingredients[randomNumber] then
		ingredients["current_global_ingredients"] = self.global_ingredients[randomNumber]
	end
	
	return ingredients
end

local function HowManySeatIsRelease():number
	local t = {}
	for _,v in CollectionService:GetTagged("Seat") do
		if not v then return end
		table.insert(t,v)
	end
	return #t
end

local function PlayerFriends()
	local t = {}
	local succes, page = pcall(function()
		return Players:GetFriendsAsync(Players.LocalPlayer.UserId)
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

local function CreateBillboard(_index,parent)
	if (UI_IMAGE_CONFIG[_index]) then
		local getImageId = UI_IMAGE_CONFIG[_index]
		local billboard = ReplicatedStorage.Packages.Lib.UI_IMAGE_CONFIG.Instance.BillboardGui:Clone()
		billboard.Parent = parent
		billboard.Main.ImageLabel.Image = getImageId
	end
end

local function CreateRig(position:Vector3)
	local FriendTable = PlayerFriends()
	local GetFriendFromIndex = FriendTable[math.random(1,#FriendTable)]
	if (GetFriendFromIndex) then
		print(Players:GetNameFromUserIdAsync(GetFriendFromIndex))
	end
	
	local Rig = ReplicatedStorage.Packages.Rig:Clone()
	local GetHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(GetFriendFromIndex)
	Rig.Parent = workspace

	for i,v in Rig:GetChildren() do
		if v:IsA("BasePart") then
			v.CollisionGroup = "NPC_System"
		end
	end
	
	if (position) then
		Rig:PivotTo(CFrame.new(position))
	end
	return Rig
end

function PlayerTakeOrderModule:ShouldCreateEndPointForNPC(position:Vector3)
	if workspace:FindFirstChild("EndFor_ShouldCreateEndPointForNPC_client_fn") then return end
	local part = Instance.new("Part",workspace.TakeOrderModel)	
	part.Size = Vector3.one
	part.Material = "Neon"
	part.Position = workspace.TakeOrderModel.OrderPart.Position + position
	part.Name = "EndFor_ShouldCreateEndPointForNPC_client_fn"
	part.Anchored = true
	part.CanCollide = false
end

function PlayerTakeOrderModule:GetEndPointForNPC()
	if workspace.TakeOrderModel:FindFirstChild("EndFor_ShouldCreateEndPointForNPC_client_fn") then
		return workspace.TakeOrderModel:FindFirstChild("EndFor_ShouldCreateEndPointForNPC_client_fn")
	end
end

function PlayerTakeOrderModule:CreateNewOrder(UIDFromServer,OrderData)
	if not UIDFromServer or not OrderData then return end
	if not workspace.TakeOrderModel:FindFirstChild("EndFor_ShouldCreateEndPointForNPC_client_fn") then
		self:ShouldCreateEndPointForNPC(Vector3.new(0,0,5))
	end
	
	self.CopyOrderData = OrderData
	self.UpcomingOrderData = {}
	self._signal = Signal.new()
	self._allSeatCompletedSignal = Signal.new()
	
	self:MakeNewOrderSignal()
	self:CheckUnlockedSeat_signal_fn()
	
	self.FirstInOrderList = 1
	self.EndPointCanMoove = Value(true)
	
	if #self.CopyOrderData <= 0 then
		local rigMaxNumberPerOrder = 4
		local rigNumber = math.random(1,2)
		
		Thread.SpawnNow(function()
			for i = 1,rigNumber,1 do
				table.insert(self.UpcomingOrderData,rigNumber)
			end
		end)
		
		local modelIngredientsOrder =  CreateRandomTakeOrderTable(self)
		local makeRig = CreateRig(self:GetEndPointForNPC().Position + Vector3.new(0,0,20))
		makeRig.Name = UIDFromServer..tostring("/Rig-Value-Data: "..self.UpcomingOrderData[rigNumber])
		

		if not self[makeRig.Name] then
			self.CopyOrderData[makeRig.Name] = modelIngredientsOrder
			CreateBillboard(modelIngredientsOrder.current_global_ingredients,makeRig:FindFirstChild("Head"))
			self[makeRig.Name] = {
				model = makeRig,
				CurrentWalksSpeed = makeRig.Humanoid.WalkSpeed,
				DefaultCFrame = makeRig:GetPivot(),
				DefaultPosition = makeRig.PrimaryPart.Position,
				readyToStartPathfinding = true,
				animations = {
					WalkAnimations = "http://www.roblox.com/asset/?id=507777826",
					IdleAnimations = "http://www.roblox.com/asset/?id=507766666",
					JumpAnimations = "http://www.roblox.com/asset/?id=507765000",
					SeatAnimations = "http://www.roblox.com/asset/?id=2506281703",
				},
				client_ingredients = modelIngredientsOrder,
				sitted = false,
				rigId = self.UpcomingOrderData[rigNumber],
				orderClaimed = false,
				isFirstOnCommand = false
			}
		end

		if self[makeRig.Name].readyToStartPathfinding == true then
			self:ComputeRigPathfinding(self[makeRig.Name].model,self.CopyOrderData)
		end
		
	else
		
	end
	
end

function PlayerTakeOrderModule:CreateProxiForGlassCup(action,object,rigFlavor:string)
	if (action) and (object) then
		self._attachment = Instance.new("Attachment",workspace.Pickup:FindFirstChild("Glass Cup"))
		local proxy = Instance.new("ProximityPrompt",self._attachment)
		
		proxy.Triggered:Connect(function()
			local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
			if (character) then
				local cloneGlassCup = ReplicatedStorage.Packages.Lib.UI_IMAGE_CONFIG.Instance:FindFirstChild("Glass Cup"):Clone()
				cloneGlassCup.Anchored = false
				cloneGlassCup.Parent = character
				cloneGlassCup.CanCollide = false
				local motor6D = Instance.new("Motor6D",cloneGlassCup)
				motor6D.Part0 = character:WaitForChild("HumanoidRootPart")
				motor6D.Part1 = cloneGlassCup
				motor6D.C1 = CFrame.new(0,0,3) * CFrame.fromEulerAnglesXYZ(0,0,math.rad(90))
				proxy.Enabled = false
				
				if (workspace:FindFirstChild(rigFlavor.."Flavor")) then
					self:CreateProxiForRigOrderFlavor(rigFlavor,workspace:FindFirstChild(rigFlavor.."Flavor"))
				end
				
				if self._attachment then
					self._attachment:Destroy()
					self._attachment = nil
				else
					proxy:Destroy()
				end
			end
		end)
	end
end

function PlayerTakeOrderModule:CreateProxiForRigOrderFlavor(flavorName,parent)
	if (flavorName) then
		local attachment = Instance.new("Attachment",parent.OrderPart)
		attachment.CFrame = attachment.CFrame * CFrame.new(0,3,0)
		local proxi = Instance.new("ProximityPrompt",attachment)
		proxi.ActionText = "Pick Up"
		proxi.ObjectText = flavorName
		
		proxi.Triggered:Connect(function()
			local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
			if (character) then
				local getGlassCup = character:FindFirstChild("Glass Cup")
				if (getGlassCup) then
					local FlavorPart = getGlassCup.FlavorPart
					FlavorPart.Transparency = 0
					FlavorPart.Color = parent.OrderPart.Color
					if not self[Players.LocalPlayer.UserId.."Order"] then
						self[Players.LocalPlayer.UserId.."Order"] = flavorName
					else
						self[Players.LocalPlayer.UserId.."Order"] = flavorName
					end
					
					attachment:Destroy()
				else
					return
				end
			end
		end)
	end
end

function PlayerTakeOrderModule:DestroyGlassCup()
	local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	if character then
		local getGlassCup = character:FindFirstChild("Glass Cup")
		if (getGlassCup) then
			getGlassCup:Destroy()
		end
	end
end

function PlayerTakeOrderModule:MakeNewOrderSignal()	
	self._signal:Connect(function()
		if HowManySeatIsRelease() <= 0 then return end
		print("Connected Signal")
		local UID = HttpService:GenerateGUID(false)
		
		
		local rigMaxNumberPerOrder = 4
		local rigNumber = math.random(1,2)
		
		Thread.SpawnNow(function()
			for i = 1,rigNumber,1 do
				table.insert(self.UpcomingOrderData,rigNumber)
			end
		end)

		if workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt") then
			local proxi = workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt")
			if proxi.Enabled == false then
				proxi.Enabled = true
			end
		end

		local modelIngredientsOrder =  CreateRandomTakeOrderTable(self)
		local makeRig = CreateRig(self:GetEndPointForNPC().Position + Vector3.new(0,0,20))
		makeRig.Name = UID..tostring("/Rig-Value-Data: "..self.UpcomingOrderData[rigNumber])

		if not self[makeRig.Name] then
			self.CopyOrderData[makeRig.Name] = modelIngredientsOrder
			CreateBillboard(modelIngredientsOrder.current_global_ingredients,makeRig:FindFirstChild("Head"))
			self[makeRig.Name] = {
				model = makeRig,
				CurrentWalksSpeed = makeRig.Humanoid.WalkSpeed,
				DefaultCFrame = makeRig:GetPivot(),
				DefaultPosition = makeRig.PrimaryPart.Position,
				readyToStartPathfinding = true,
				animations = {
					WalkAnimations = "http://www.roblox.com/asset/?id=507777826",
					IdleAnimations = "http://www.roblox.com/asset/?id=507766666",
					JumpAnimations = "http://www.roblox.com/asset/?id=507765000",
					SeatAnimations = "http://www.roblox.com/asset/?id=2506281703",
				},
				client_ingredients = modelIngredientsOrder,
				sitted = false,
				orderClaimed = false,
				rigId = self.UpcomingOrderData[rigNumber],
				isFirstOnCommand = false
			}
		end

		if self[makeRig.Name].readyToStartPathfinding == true then
			self:ComputeRigPathfinding(self[makeRig.Name].model,self.CopyOrderData)
		end
	end)
end

function PlayerTakeOrderModule:ComputeRigPathfinding(rig,gridPlacementData)
	if (rig) then
		
		if not self.rigInPath then
			self.rigInPath = {}
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
		
		WalkAnimations.AnimationId = self[rig.Name].animations.WalkAnimations
		IdleAnimations.AnimationId = self[rig.Name].animations.IdleAnimations
		JumpAnimations.AnimationId = self[rig.Name].animations.JumpAnimations
		SeatAnimations.AnimationId = self[rig.Name].animations.SeatAnimations

		local createPath = PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = true,
		})
				
		local succes , pathMalformed = pcall(function()
		 	createPath:ComputeAsync(humanoidRootPart.Position,self:GetEndPointForNPC().Position)
		end)
		
		local currentWaypoints = 1
		local waypoints = createPath:GetWaypoints()	
		
		
		if (succes) and (createPath.Status == Enum.PathStatus.Success) then
			local waypoints = createPath:GetWaypoints()	
			local reachedConnection 
			
			local idleTrack
			local walkTrack
			local jumpTrack
		
			humanoid:MoveTo(waypoints[currentWaypoints].Position)
			
			walkTrack = humanoid:LoadAnimation(WalkAnimations)
			walkTrack:Play()
			
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				if reached and currentWaypoints < #waypoints then
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
					if (#gridPlacementData >= 1) then
						self:GetEndPointForNPC().Position = self:GetEndPointForNPC().Position + Vector3.new(0,0,5)
					else
						self:GetEndPointForNPC().Position = self:GetEndPointForNPC().Position + Vector3.new(0,0,5)
					end
					
					if not table.find(self.rigInPath,rig.Name) then
						table.insert(self.rigInPath,rig.Name)
					end
					
					if not workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt") then
						local proxi = Instance.new("ProximityPrompt",workspace.TakeOrderModel.OrderPart.Attachment)
						proxi.ActionText = ""
						proxi.KeyboardKeyCode = Enum.KeyCode.F
						self.EndPointCanMoove:set(true)
						self:ProximityTriggered(proxi)
					else
						if workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt") then
							local proxi = workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt")
							if proxi.Enabled == false then
								proxi.Enabled = true
							end
						end
					end
					self:CreateProxiForGlassCup("Take","Glass cup",self:GetOrder(rig.Name).client_ingredients.current_global_ingredients)
					reachedConnection:Disconnect()
				end
			end)
		end
		
	end
end

function PlayerTakeOrderModule:GetOrder(UID)
	if self[UID] then
		return self[UID]
	else
		return nil
	end
end

function PlayerTakeOrderModule:CheckUnlockedSeat_signal_fn()
	self._allSeatCompletedSignal:Connect(function()
		Thread.SpawnNow(function()
			repeat
				task.wait()
			until HowManySeatIsRelease() > 0
			warn("signal fired for @[allseat Completed Signal]")
			self._signal:Fire()
		end)
	end)
end

function PlayerTakeOrderModule:ProximityTriggered(proxi)
	if (proxi) then
		if not self[proxi] then
			self[proxi] = proxi.Triggered:Connect(function()
				local getOrder = self:GetOrder(self.rigInPath[1])
				if (getOrder) then
					if self[Players.LocalPlayer.UserId.."Order"] == nil then return end
					if getOrder.orderClaimed == false then
						getOrder.orderClaimed = true
						--print("Should load a new pathfinding")

						if (getOrder.client_ingredients.current_global_ingredients == self[Players.LocalPlayer.UserId.."Order"]) then
							self[Players.LocalPlayer.UserId.."Order"] = nil
							proxi.Enabled = false
							self:DestroyGlassCup()
							
							if getOrder.model:FindFirstChild("Head"):FindFirstChildOfClass("BillboardGui") then
								getOrder.model:FindFirstChild("Head"):FindFirstChildOfClass("BillboardGui"):Destroy()
							end
							
							if (self.rigInPath[2]) then
								local offsetY = self:GetEndPointForNPC().Position.Y
								self:GetEndPointForNPC().Position = getOrder.model:GetPivot().Position + Vector3.new(0,offsetY,0)
								local NextRigPath = self:GetOrder(self.rigInPath[2]).model
								Thread.Delay(0.5,function()
									self.EndPointCanMoove:set(true)
									self:MoveRigToNewOrderPath(NextRigPath)
								end)
							else
								self:GetEndPointForNPC().Position = self:GetEndPointForNPC().Position - Vector3.new(0,0,5)
							end

							table.remove(self.rigInPath,table.find(self.rigInPath,getOrder.model.Name))
							self:MoveRigToASeatInstance(getOrder.model)
								
							if (HowManySeatIsRelease() <= 0) then
								warn("all seat has been taken")
								self._allSeatCompletedSignal:Fire()
							else
								self._signal:Fire()
							end
						end
					end
				else
					if (HowManySeatIsRelease() <= 0) then
						warn("all seat has been taken")
					else

					end
				end
			end)
		else
			return self[proxi]
		end
	end
end

function PlayerTakeOrderModule:CleanUpRigPathfinding(rig,rigSeat)
	if (rig) and (rigSeat) then
		if HowManySeatIsRelease() <= 0 then
			
		else
			
		end
		
		CollectionService:AddTag(rigSeat.currentSeat,"Seat")
		table.clear(rigSeat)
		
		if (self[rig]) then
			self[rig] = nil
		end
		if self[rig.Name] then
			table.clear(self[rig.Name])
			self[rig.Name] = nil
		end
		rig:Destroy()
	end
end

function PlayerTakeOrderModule:MoveRigToNewOrderPath(rig)
	local humanoidRootPart = rig:FindFirstChild("HumanoidRootPart")
	local humanoid = rig:FindFirstChild("Humanoid")
	
	local createPath = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 6,
		AgentCanJump = true,
	})
	
	local currentWaypoints = 1
	
	local succes , pathMalformed = pcall(function()
		createPath:ComputeAsync(humanoidRootPart.Position,self:GetEndPointForNPC().Position)
	end)	
	
	if (succes) and (createPath.Status == Enum.PathStatus.Success) then
		local waypoints = createPath:GetWaypoints()	
		local reachedConnection 
		local IdleTrack
		local walkTrack
		local jumpTrack

		humanoid:MoveTo(waypoints[currentWaypoints].Position)

		walkTrack = humanoid:LoadAnimation(rig:FindFirstChild("WalkAnimations"))
		walkTrack:Play()

		reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
			if reached and currentWaypoints < #waypoints then
				currentWaypoints += 1					
				humanoid:MoveTo(waypoints[currentWaypoints].Position)
			else
				if walkTrack then
					walkTrack:Stop()
					walkTrack = nil
					IdleTrack = humanoid:LoadAnimation(rig.IdleAnimations)
					IdleTrack:Play()
				else
					IdleTrack = humanoid:LoadAnimation(rig.IdleAnimations)
					IdleTrack:Play()
				end

				self:GetEndPointForNPC().Position = self:GetEndPointForNPC().Position + Vector3.new(0,0,5)
				reachedConnection:Disconnect()
				
				if workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt") then
					local proxi = workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt")
					if proxi.Enabled == false then
						proxi.Enabled = true
					end
				end
				self:CreateProxiForGlassCup("Take","Glass cup",self:GetOrder(rig.Name).client_ingredients.current_global_ingredients)
			end
		end)

	end
end

function PlayerTakeOrderModule:MoveRigToASeatInstance(rig)
	local GetSeatInstance = CollectionService:GetTagged("Seat")
	local humanoidRootPart = rig:FindFirstChild("HumanoidRootPart")
	local humanoid = rig:FindFirstChild("Humanoid")
	
	local createPath = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 6,
		AgentCanJump = true,
	})
	
	self[rig] = {}
	self[rig].currentSeat = nil
	local currentWaypoints = 1
	
	for _,seat in GetSeatInstance do
		if seat.Occupant ~= nil then continue end
		seat.CanCollide = false
		self[rig].currentSeat = seat
		break
	end
	
	CollectionService:RemoveTag(self[rig].currentSeat,"Seat")
		
	local succes , pathMalformed = pcall(function()
		createPath:ComputeAsync(humanoidRootPart.Position,self[rig].currentSeat.Position)
	end)
	
	--print(createPath.Status)
	
	if (succes) and (createPath.Status == Enum.PathStatus.Success) then
		if not self._lockFuturOrder then
			self._lockFuturOrder = "Disable"
		end
		if (self.CopyOrderData[rig.Name]) then
			table.clear(self.CopyOrderData[rig.Name])
			self.CopyOrderData[rig.Name] = nil
			local rigId = self[rig.Name].rigId
			warn(self.UpcomingOrderData)
			if table.find(self.UpcomingOrderData,rigId) then
				table.remove(self.UpcomingOrderData,table.find(self.UpcomingOrderData,rigId))

				if #self.UpcomingOrderData <= 0 then
					print("new order list upcoming")
					if workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt") then
						local proxi = workspace.TakeOrderModel.OrderPart.Attachment:FindFirstChildOfClass("ProximityPrompt")
						if proxi.Enabled == false then
							proxi.Enabled = true
						end
						
						if HowManySeatIsRelease() <= 0 then
							print("all seat taken ", debug.traceback("seat tags"))
						else
						end
					end
				else
					if HowManySeatIsRelease() <= 0 then
						-- do nothing
					else
					end
				end
			end
		end
		
		local waypoints = createPath:GetWaypoints()	
		local reachedConnection 
		local SeatTrack
		local walkTrack
		local jumpTrack

		humanoid:MoveTo(waypoints[currentWaypoints].Position)

		walkTrack = humanoid:LoadAnimation(rig:FindFirstChild("WalkAnimations"))
		walkTrack:Play()
		
		reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
			if reached and currentWaypoints < #waypoints then
				currentWaypoints += 1					
				humanoid:MoveTo(waypoints[currentWaypoints].Position)
			else
				if walkTrack then
					walkTrack:Stop()
					walkTrack = nil
					SeatTrack = humanoid:LoadAnimation(rig.SeatAnimations)
					SeatTrack:Play()
				else
					SeatTrack = humanoid:LoadAnimation(rig.SeatAnimations)
					SeatTrack:Play()
				end
				
				humanoidRootPart.Anchored = true
				rig:SetPrimaryPartCFrame(self[rig].currentSeat.CFrame * CFrame.new(0,1,0))
				--humanoid.Sit = true
				self.EndPointCanMoove:set(false)

				reachedConnection:Disconnect()
				Thread.Delay(math.random(15,25),function()
					self:CleanUpRigPathfinding(rig,self[rig])
				end)
			end
		end)
		
	end
end

return PlayerTakeOrderModule
