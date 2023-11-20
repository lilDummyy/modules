local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

if (RunService:IsClient()) then
else
	return error(`{script.Name} must be required on client-side`,2)
end

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Thread = require(ReplicatedStorage.Packages.Thread)
local Maid = require(ReplicatedStorage.Packages.Maid)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Option = require(ReplicatedStorage.Packages.Option)
local Roact = require(ReplicatedStorage.Packages.Roact)

local Comm = require(ReplicatedStorage.Packages.Comm).ClientComm
local comm = Comm.new(ReplicatedStorage.Packages,true,"EmitterService")
local buildFunction = comm:BuildObject()


local player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local PlayerGui = player.PlayerGui
local ClientFolder = playerScripts:WaitForChild("Client")

local MainRequirement = PlayerGui:WaitForChild("MainRequirementUi")
local coutainer = MainRequirement.coutainer
local Items = coutainer.Items
local inventory = Items.inventory
local packages = inventory.TitlesInventory

local promiseReview = nil

local module = {}
module.__index = module

function module:Purchase(emitter : string)
	assert(type(emitter) == "string","ParticleEmitter Object must be a stringValue")
	return buildFunction:PurchaseServiceLoaded(emitter):andThen(function(data)
		if (data) == nil then return end
		local function elementConstruct()
			return Roact.createElement("Frame",{
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.0525,0.12),
				BackgroundColor3 = Color3.new(0,0,0)
			},{
				Main = Roact.createElement("Frame",{
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(.5,.5),
					Position = UDim2.fromScale(.5,.5),
					Size = UDim2.fromScale(.8,.8),
					[Roact.Event.MouseEnter] = function(element)
						TweenService:Create(element.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
						TweenService:Create(element.ImageButton,TweenInfo.new(.15),{ImageColor3 = Color3.new(0,0,0)}):Play()
						TweenService:Create(element,TweenInfo.new(.15),{BackgroundTransparency = 0,BackgroundColor3 = Color3.new(1,1,1),Size = UDim2.fromScale(.78,.78)}):Play()
					end,
					[Roact.Event.MouseLeave] = function(element)
						TweenService:Create(element.ImageButton,TweenInfo.new(.15),{ImageColor3 = Color3.new(1,1,1)}):Play()
						TweenService:Create(element,TweenInfo.new(.15),{BackgroundTransparency = 1,BackgroundColor3 = Color3.new(0,0,0),Size = UDim2.fromScale(.8,.8)}):Play()
						TweenService:Create(element.UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
					end,
				},{
					UICorner = Roact.createElement("UICorner",{}),
					UIStroke = Roact.createElement("UIStroke",{Thickness = 2,Color = Color3.new(1,1,1)}),
					ImageButton = Roact.createElement("ImageButton",{
						Image = self.textures.ImagesId[emitter] or "",
						Size = UDim2.fromScale(.85,.85),
						AnchorPoint = Vector2.new(.5,.5),
						Position = UDim2.fromScale(.5,.5),
						BackgroundTransparency = 1,
						[Roact.Event.MouseButton1Down] = function(element)
							if (self:CancelPromiseReview() == true) then
							else
								promiseReview = self:CreatePlayerDecision(emitter)
								return script.CancelPromise:Invoke("cancel")
							end
						end,
					})
				})
			})
		end
		self[emitter] = Roact.mount(Roact.createElement(elementConstruct),packages,emitter)
		return self
	end):catch(warn)
end


function module:CancelPromiseReview()
	if (promiseReview ~= nil) then
		promiseReview:cancel()
		promiseReview = nil
		return true
	else
		return false
	end
end

function module:LoadComponent(t)
	if (type(t) ~= "table") then return end
	debug.profilebegin("{CLIENT} = LoadComponent [('effects')], ["..tostring(script.Name).."]")
	for i,emitter in pairs(t) do
		buildFunction:ReloadComponentService(emitter):andThen(function(data)
			if (type(data)) ~= "table" then return end
			local function elementConstruct()
				return Roact.createElement("Frame",{
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.0525,0.12),
					BackgroundColor3 = Color3.new(0,0,0)
				},{
					Main = Roact.createElement("Frame",{
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(.5,.5),
						Position = UDim2.fromScale(.5,.5),
						Size = UDim2.fromScale(.8,.8),
						[Roact.Event.MouseEnter] = function(element)
							TweenService:Create(element.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.ImageButton,TweenInfo.new(.15),{ImageColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{BackgroundTransparency = 0,BackgroundColor3 = Color3.new(1,1,1),Size = UDim2.fromScale(.78,.78)}):Play()
						end,
						[Roact.Event.MouseLeave] = function(element)
							TweenService:Create(element.ImageButton,TweenInfo.new(.15),{ImageColor3 = Color3.new(1,1,1)}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{BackgroundTransparency = 1,BackgroundColor3 = Color3.new(0,0,0),Size = UDim2.fromScale(.8,.8)}):Play()
							TweenService:Create(element.UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
						end,
					},{
						UICorner = Roact.createElement("UICorner",{}),
						UIStroke = Roact.createElement("UIStroke",{Thickness = 2,Color = Color3.new(1,1,1)}),
						ImageButton = Roact.createElement("ImageButton",{
							Image = self.textures.ImagesId[emitter] or "",
							Size = UDim2.fromScale(.85,.85),
							AnchorPoint = Vector2.new(.5,.5),
							Position = UDim2.fromScale(.5,.5),
							BackgroundTransparency = 1,
							[Roact.Event.MouseButton1Down] = function(element)
								if (self:CancelPromiseReview() == true) then									
								else
									promiseReview = self:CreatePlayerDecision(emitter)
									return script.CancelPromise:Invoke("cancel")
								end
							end,
						})
					})
				})
			end
			self:SendPurchaseNotifier(emitter)
			self[emitter] = Roact.mount(Roact.createElement(elementConstruct),packages,emitter)
		end):catch(warn)
	end
	debug.profileend()
	return self
end

function module:SendPurchaseNotifier(n:string)
	local ui = Players.LocalPlayer.PlayerGui:FindFirstChild("RequestSend")
	return Promise.new(function(resolve,reject,OnCancel)
		local templateToMove = script:WaitForChild("template"):Clone()
		templateToMove.Parent = ui
		templateToMove.Name = n
		TweenService:Create(templateToMove:FindFirstChild("requestText"),TweenInfo.new(.15),{TextColor3 = Color3.new(1, 1, 1)}):Play()
		TweenService:Create(templateToMove:FindFirstChild("bar"),TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
		templateToMove:WaitForChild("requestText").Text = "Effet acheté :".."("..(n)..") ✨"
		TweenService:Create(templateToMove:FindFirstChild("requestText"),TweenInfo.new(.15),{TextTransparency = 0}):Play()
		TweenService:Create(templateToMove:FindFirstChild("bar").UIScale,TweenInfo.new(.15,Enum.EasingStyle.Back),{Scale = 1}):Play()
		task.wait(1.7)
		TweenService:Create(templateToMove:FindFirstChild("requestText"),TweenInfo.new(.15),{TextTransparency = 1}):Play()
		TweenService:Create(templateToMove:FindFirstChild("bar").UIScale,TweenInfo.new(.15,Enum.EasingStyle.Back),{Scale = 0}):Play()
		task.wait(.5)
		templateToMove:Destroy()
	end)		
end

function module:CreatePlayerDecision(emitter : string)
	return Promise.new(function(resolve,reject,onCancel)
		local function createElement()
			return Roact.createElement("Frame",{
				BackgroundTransparency = 0.35,
				Size = UDim2.fromScale(0.45,0.55),
				Position = UDim2.fromScale(.5,.45),
				AnchorPoint = Vector2.new(.5,.5),
				BackgroundColor3 = Color3.fromRGB(25,25,25),	
			},{
				UIStroke = Roact.createElement("UIStroke",{Color = Color3.new(1,1,1),Thickness = 1}),
				UICorner = Roact.createElement("UICorner"),
				CurrentItemLabel = Roact.createElement("TextLabel",{
					Text = "Voulez vous ajoutez l'effets à votre mort : ("..tostring(emitter)..") ?",
					TextScaled = true,
					TextColor3 = Color3.fromRGB(255,255,255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(.85,0.1),
					AnchorPoint = Vector2.new(.5,.5),
					Position = UDim2.fromScale(.5,.15),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
				}),
				EquiperFrame = Roact.createElement("Frame",{
					Size = UDim2.fromScale(.2,.125),
					Position = UDim2.fromScale(0.25,0.85),
					AnchorPoint = Vector2.new(.5,.5),
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(25,25,25),	
				},{
					UICorner = Roact.createElement("UICorner"),
					UIScale = Roact.createElement("UIScale",{Scale = 1}),
					UIStroke = Roact.createElement("UIStroke",{Color = Color3.new(1,1,1),Thickness = 1}),
					EquipButton = Roact.createElement("TextButton",{
						BackgroundTransparency = 1,
						BackgroundColor3 = Color3.fromRGB(25,25,25),
						AnchorPoint = Vector2.new(.5,.5),
						Size = UDim2.fromScale(0.8,0.8),
						Text = "Équiper",
						TextColor3 = Color3.new(1,1,1),
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal),
						TextScaled = true,
						Position = UDim2.fromScale(.5,.5),
						[Roact.Event.MouseEnter] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = .95}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
						end,
						[Roact.Event.MouseLeave] = function(element)
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(1,1,1)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = 1}):Play()
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.fromRGB(25,25,25),BackgroundTransparency = 1}):Play()
						end,
						[Roact.Event.MouseButton1Down] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()	
							if #Players.LocalPlayer:WaitForChild("PlayerGui").InventoryScreen.coutainer:GetChildren()>=5 then return end
							self:UpdateDeathEffect(emitter)
						end,
					}),
				}),
				SuppFrame = Roact.createElement("Frame",{
					Size = UDim2.fromScale(.2,.125),
					Position = UDim2.fromScale(0.75,0.85),
					AnchorPoint = Vector2.new(.5,.5),
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(25,25,25),
				},{
					UICorner = Roact.createElement("UICorner"),
					UIScale = Roact.createElement("UIScale",{Scale = 1}),
					UIStroke = Roact.createElement("UIStroke",{Color = Color3.new(1,1,1),Thickness = 1}),
					DeleteButton = Roact.createElement("TextButton",{
						BackgroundTransparency = 1,
						BackgroundColor3 = Color3.fromRGB(25,25,25),
						AnchorPoint = Vector2.new(.5,.5),
						Size = UDim2.fromScale(0.8,0.8),
						Text = "Vendre",
						TextColor3 = Color3.new(1,1,1),
						TextScaled = true,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal),
						Position = UDim2.fromScale(.5,.5),
						[Roact.Event.MouseEnter] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = .95}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
						end,
						[Roact.Event.MouseLeave] = function(element)
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(1,1,1)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = 1}):Play()
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.fromRGB(25,25,25),BackgroundTransparency = 1}):Play()
						end,
						[Roact.Event.MouseButton1Down] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()	
							self:CompletelyRemoveEffect(emitter)
						end,
					})
				}),
				UnEquipFrame = Roact.createElement("Frame",{
					Size = UDim2.fromScale(.2,.125),
					Position = UDim2.fromScale(0.5,0.85),
					AnchorPoint = Vector2.new(.5,.5),
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(25,25,25),
				},{
					UICorner = Roact.createElement("UICorner"),
					UIScale = Roact.createElement("UIScale",{Scale = 1}),
					UIStroke = Roact.createElement("UIStroke",{Color = Color3.new(1,1,1),Thickness = 1}),
					UnEquipButton = Roact.createElement("TextButton",{
						BackgroundTransparency = 1,
						BackgroundColor3 = Color3.fromRGB(25,25,25),
						AnchorPoint = Vector2.new(.5,.5),
						Size = UDim2.fromScale(0.8,0.8),
						Text = "Déséquiper",
						TextColor3 = Color3.new(1,1,1),
						TextScaled = true,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal),
						Position = UDim2.fromScale(.5,.5),
						[Roact.Event.MouseEnter] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = .95}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()
						end,
						[Roact.Event.MouseLeave] = function(element)
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(1,1,1)}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(1,1,1)}):Play()
							TweenService:Create(element.Parent.UIScale,TweenInfo.new(.15),{Scale = 1}):Play()
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.fromRGB(25,25,25),BackgroundTransparency = 1}):Play()
						end,
						[Roact.Event.MouseButton1Down] = function(element)
							TweenService:Create(element.Parent,TweenInfo.new(.15),{BackgroundColor3 = Color3.new(1,1,1),BackgroundTransparency = 0}):Play()
							TweenService:Create(element,TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)}):Play()
							TweenService:Create(element.Parent.UIStroke,TweenInfo.new(.15),{Color = Color3.new(0,0,0)}):Play()	
							self:RemoveEffect(emitter)
						end,
					})
				})
			})
		end
		local handle = Roact.mount(Roact.createElement(createElement),Items,emitter)
		
		onCancel(function()
			warn("[Emitter Controller]: PromiseReview à était Cancel")
			if (handle) then
				return Roact.unmount(handle)
			end
		end)
		
	end):catch(warn)
end

function module:UpdateDeathEffect(emitter)
	return buildFunction:UpdateDeathEffect(emitter):andThen(function(data)
		if (data) then
			self:CancelPromiseReview()
			return print("[Emitter Controller]: "..`({data._v}) equiped`)
		end
	end):catch(warn)
end

function module:CompletelyRemoveEffect(emitter)
	return buildFunction:RemoveObjectFromComponent(emitter):andThen(function(data)
		if (data) then
			self:CancelPromiseReview()
			return Roact.unmount(self[emitter])
		end
	end):catch(warn)
end

function module:RemoveEffect(emitter)
	return buildFunction:RemoveEmitter(emitter):andThen(function(result)
		return self:CancelPromiseReview()
	end)
end

module.textures = {ImagesId = {
	DeathLover = "rbxassetid://917189380"
}}

module.signal = {
	[script.CancelPromise.Name] = script.CancelPromise
}

module.sound = {
	DeathLover = "rbxassetid://4576364825",
}

return module
