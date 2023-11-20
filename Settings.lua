--[[ Dummy 

02/09/23
Setting module 

->TopbarPlus
Description;
ui to open all settings and to connect some m1 event on ui/frames
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages:FindFirstChild("Knit"))
local Keyboard = require(Knit.Util.Input).Keyboard
local Promise = require(Knit.Util.Promise)
local Option = require(Knit.Util.Option)
local Maid = require(Knit.Util.Maid)
local setting_option = require(script.setting_Option)
local inventoryItemModule = require(script.Parent["InventoryModule.all"]).Items
local Icon = require(ReplicatedStorage.Packages.Icon)
local IconController = require(ReplicatedStorage.Packages.Icon.IconController)
IconController.voiceChatEnabled = true

local option = setting_option.new()

local set = {}
set.__index = set


local DEFAULT_LIST_X = 0.072
local DEFAULT_LIST_Y = 0.857

local function tween(obj,info,properties)
	if assert(obj ~= nil , `{obj} can't be nil`) then
		return TweenService:Create(obj,info,properties):Play()
	end
	return nil
end

function set.new()
	local self = setmetatable({},set)
	self.player = Players.LocalPlayer
	self.config = script.Parent:WaitForChild("Configuration")
	self.initialized = self.config.initialized
	self.isBroken = "no state"
	self.isAlreadyConnected = "none"
	self.uis = {}
	self.ClassName = "SettingsMenu"
	return self
end

function set._on(self, guiObject : {}): (any)
	if (not self) then return `{self[guiObject]} can't be finded on self` end
	self.uis.givePromiseObject = "table"
	if (self.uis.givePromiseObject) then
		self.uis.givePromiseObject = guiObject
		self.isAlreadyConnected = "on Connect"
		return self.uis.givePromiseObject
	end
	return nil
end

function set:ToggleObject(bindToggleItem)
	if (bindToggleItem) then
		local coutainer = bindToggleItem.coutainer.bar_coutainer
		local itemsCoutains = bindToggleItem.coutainer.Items
		return Promise.new(function(resolve,reject,onCancel)
			local maid = Maid.new()
			local frames = {}
			
			for i,frameInCoutainer in pairs(coutainer:GetChildren()) do
				if frameInCoutainer.ClassName == "UIListLayout" then continue end
				if frameInCoutainer.ClassName == "Frame" then
					table.insert(frames,frameInCoutainer)
					maid:giveTask(frameInCoutainer.MouseEnter:Connect(function()
						SoundService:PlayLocalSound(SoundService:FindFirstChild("RBLX UI Hover 03 (SFX)"))
						tween(frameInCoutainer.UIScale,TweenInfo.new(.15),{Scale = .95})
						tween(frameInCoutainer,TweenInfo.new(.15),{BackgroundTransparency = 0,BackgroundColor3 = Color3.new(1,1,1)})
						tween(frameInCoutainer:FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextColor3 = Color3.new(0,0,0)})
						tween(frameInCoutainer.UIStroke,TweenInfo.new(.15),{Thickness = 2,Color = Color3.new(0,0,0)})
					end))
					maid:giveTask(frameInCoutainer.MouseLeave:Connect(function()
						tween(frameInCoutainer.UIScale,TweenInfo.new(.15),{Scale = 1})
						tween(frameInCoutainer,TweenInfo.new(.15),{BackgroundTransparency = 1,BackgroundColor3 = Color3.new(0,0,0)})
						tween(frameInCoutainer:FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextColor3 = Color3.new(1,1,1)})
						tween(frameInCoutainer.UIStroke,TweenInfo.new(.15),{Thickness = 1,Color = Color3.new(1,1,1)})
					end))
					maid:giveTask(frameInCoutainer:FindFirstChildOfClass("TextButton").MouseButton1Down:Connect(function()
						SoundService:PlayLocalSound(SoundService:FindFirstChild("UI Click"))
						tween(itemsCoutains:FindFirstChild(frameInCoutainer.Name),TweenInfo.new(.15),{Position = UDim2.fromScale(0.5,0.5)})
						tween(itemsCoutains:FindFirstChild(frameInCoutainer.Name):FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextTransparency = 0})
						for i,frame in next,frames do
							if frame:IsA("Frame") then
								if frame.Name == frameInCoutainer.Name then continue end
								tween(itemsCoutains:FindFirstChild(frame.Name),TweenInfo.new(.15),{Position = UDim2.fromScale(1.5,0.5)})
								tween(itemsCoutains:FindFirstChild(frame.Name):FindFirstChildOfClass("TextLabel"),TweenInfo.new(.15),{TextTransparency = 1})
							end
						end
					end))
				end
 			end
			
			onCancel(function()
				table.clear(frames)
				return maid:clean()
			end)
		end)
	end
end


local function StopForDisconnectedFunction(self,set)
	tween(set.ScreenGui:WaitForChild("coutainer"):FindFirstChildOfClass("CanvasGroup"),TweenInfo.new(.1),{GroupTransparency = 1})
	for i,child in ipairs(set.ScreenGui:WaitForChild("coutainer"):FindFirstChildOfClass("CanvasGroup"):GetChildren()) do
		if (child.ClassName == "Frame") then
			if (child.Name == "frameInventory") then
				inventoryItemModule:CancelPromiseReview()
			end
			if (child.ClassName == "Frame") and (child.Name ~= "ignored") then tween(child,TweenInfo.new(.1),{Position = UDim2.fromScale(1.5,0.5)}) end
			if (child:FindFirstChildOfClass("UIStroke")) and (child.Name == "ignored") then
				tween(child:FindFirstChildOfClass("UIStroke"),TweenInfo.new(.1),{Transparency = 1})
			end	
		end
	end
	for i, coutainer in next,set.ScreenGui:GetChildren() do
		if (coutainer.ClassName ~= nil) and (coutainer.ClassName == "Frame") then
			tween(coutainer,TweenInfo.new(.15),{BackgroundTransparency = 1})
			for i,frame in ipairs(coutainer:GetChildren()) do
				if (frame.ClassName ~= nil) and (coutainer.ClassName == "Frame") and (frame.Name == "bar_coutainer") then												
					for i,child in ipairs(frame:GetChildren()) do
						if (child.ClassName ~= "Frame") then continue end
						if (child:FindFirstChildOfClass("UIScale") ~= nil) and (child:FindFirstChildOfClass("UIStroke") ~= nil) then
							tween(child,TweenInfo.new(.1),{BackgroundTransparency = 1})
							tween(child:FindFirstChildOfClass("UIStroke"),TweenInfo.new(.1,Enum.EasingStyle.Sine),{Transparency = 1})
							if child:FindFirstChildOfClass("TextLabel") then
								tween(child:FindFirstChildOfClass("TextLabel"),TweenInfo.new(.1),{TextTransparency = 1,TextColor3 = Color3.fromRGB(255,255,255)})
							end
						end
					end
				end
			end
		end
	end
end

local function start(set)
	tween(set.ScreenGui:WaitForChild("coutainer"):FindFirstChildOfClass("CanvasGroup"),TweenInfo.new(.1),{GroupTransparency = 0})
	for i,child in ipairs(set.ScreenGui:WaitForChild("coutainer"):FindFirstChildOfClass("CanvasGroup"):GetChildren()) do
		if (child.ClassName == "Frame") then
			if (child:FindFirstChildOfClass("UIStroke")) and (child.Name == "ignored") then
				tween(child:FindFirstChildOfClass("UIStroke"),TweenInfo.new(.1),{Transparency = 0})
			end	
		end
	end
	for i, coutainer in next,set.ScreenGui:GetChildren() do
		if (coutainer.ClassName ~= nil) and (coutainer.ClassName == "Frame") then
			tween(coutainer,TweenInfo.new(.15),{BackgroundTransparency = 0.5})
			for i,frame in ipairs(coutainer:GetChildren()) do
				if (frame.ClassName ~= nil) and (coutainer.ClassName == "Frame") and (frame.Name == "bar_coutainer") then												
					for i,child in ipairs(frame:GetChildren()) do
						if (child.ClassName ~= "Frame") then continue end
						if (child:FindFirstChildOfClass("UIScale") ~= nil) and (child:FindFirstChildOfClass("UIStroke") ~= nil) then
							child:FindFirstChildOfClass("UIScale").Scale = 0
							child:FindFirstChildOfClass("UIStroke").Transparency = 1
							if child:FindFirstChildOfClass("TextLabel") then
								tween(child:FindFirstChildOfClass("TextLabel"),TweenInfo.new(.1),{TextTransparency = 0})
							end
							tween(child:FindFirstChildOfClass("UIScale"),TweenInfo.new(.1,Enum.EasingStyle.Back),{Scale = 1})
							tween(child:FindFirstChildOfClass("UIStroke"),TweenInfo.new(.1,Enum.EasingStyle.Sine),{Transparency = 0})
						end
					end
				end
			end
		end
	end
end


function set:onIconInput()
	if (self.is(self)) then
		self.StartBindingEvent = option:Start()
		local icon = Icon.new()
		:setLabel("Menu")
		:setImage("rbxassetid://9405921255")
		:bindEvent("selected",function()
			SoundService:PlayLocalSound(SoundService:FindFirstChild("UI Click"))
			if not (self.set) then
				self.set = self._on(self,{ ScreenGui = self.player.PlayerGui:WaitForChild("MainRequirementUi") })
				if (not self.down) and (self.isAlreadyConnected == "on Connect") and (self.set.ScreenGui.Enabled == false) then
					self.down = true
					Players.LocalPlayer.PlayerGui.InventoryScreen.Enabled = false
					local promise = Promise.new(function()
						if (self.set) then
							if (self.cooldown) then return end
							self.cooldown = true
							self.set.ScreenGui.Enabled = (true)
							self.toggleObjectFN = self:ToggleObject(self.set.ScreenGui)
							self.config:WaitForChild("List"):FindFirstChild("Menu"):Play()
							start(self.set)
						end
					end)							
				end
			else
				if (not self.down) and (self.isAlreadyConnected == "on Connect") and (self.set.ScreenGui.Enabled == false) then
					self.down = true
					Players.LocalPlayer.PlayerGui.InventoryScreen.Enabled = false
					local promise = Promise.new(function()
						if (self.set) then
							if (self.cooldown) then return end
							self.cooldown = true
							self.toggleObjectFN = self:ToggleObject(self.set.ScreenGui)
							self.set.ScreenGui.Enabled = (true)
							self.config:WaitForChild("List"):FindFirstChild("Menu"):Play()
							start(self.set)
						end
					end)							
				end
			end
		end)
		:bindEvent("deselected",function()
			local promiseOnDeselected = Promise.new(function()
				if (self.set) then
					self.isAlreadyConnected = "on Connect"
					if self.uis then table.clear(self.uis) end   
					StopForDisconnectedFunction(self,self.set)
					if self.toggleObjectFN then self.toggleObjectFN:cancel() end
					Players.LocalPlayer.PlayerGui.InventoryScreen.Enabled = true
					task.delay(.1,function()
						self.set.ScreenGui.Enabled = false
						self.down = false
						self.cooldown = false
					end)
				end;
			end):catch(warn)
		end)
		:setTip("Ouvre le menu avec (?) ou (M [qwerty uniquement!])")
		:bindToggleKey(Enum.KeyCode.M)
		:bindEvent("hoverStarted",function()
			return SoundService:PlayLocalSound(SoundService:FindFirstChild("RBLX UI Hover 03 (SFX)"))
		end)
	end
end


function set.is(self): boolean
	assert(type(self) == "table",'self must be a table')
	local getClassName = self.ClassName
	if (getClassName == "SettingsMenu") then
		return true
	end
	return false
end

function set:OnConfig()
	return self:onIconInput()
end

return set
