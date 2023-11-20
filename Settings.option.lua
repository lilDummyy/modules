--[[ Dummy

02/09/23
Start Setting Module (uiDraggerComponent.lua is connected with this module)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages:FindFirstChild("Knit"))
local Keyboard = require(Knit.Util.Input).Keyboard
local Promise = require(Knit.Util.Promise)
local Option = require(Knit.Util.Option)
local DragClockTime = require(script:WaitForChild("DragClockTime"))
local IsSavingModule = require(Knit.Util.IsSavingModule)

local DragComponent = require(ReplicatedStorage:WaitForChild("Packages").Menu.DragComponent)
local option = {}
option.__index = option

function option.new()
	local self = setmetatable({},option)
	self.drag = DragClockTime.new()
	self.clockAsync = 'currently : '..'none'
	self.player = Players.LocalPlayer
	
	return self
end


function option:Create_cycleChange()
	if (self.player) then
		local clockTimeButton = self.player.PlayerGui:WaitForChild("MainRequirementUi").coutainer.Items:WaitForChild("option").ScrollingFrame.clockTimeCoutainer.Slider.button
		self.drag.set(self.drag,clockTimeButton,"Clock",true)		
		self.clockAsync = self.drag.state(self.drag)
	end
	return self
end


function option:Graphics()
	local function ColorSaturation()
		local SaturationragComm = DragComponent.new()
		local ItemsCoutainer = Players.LocalPlayer.PlayerGui:WaitForChild("MainRequirementUi").coutainer.Items
		local SliderFrame = ItemsCoutainer.option.ScrollingFrame.ColorCorrectionCoutainer.Slider
		local button = SliderFrame:WaitForChild("t")

		local data = {
			_stateChanged = "GetSaturationValue",
			SavingMethodsEnable = true,
			value = "Saturation",
			percentage = 0,
			CPS = "CurrentSaturationPercentage",
			SaveMethodsName = "SaturationSaveMethods",
			TypeToChange = game:GetService("Lighting"):WaitForChild("ColorCorrection"),
			SaveRemote = ReplicatedStorage:WaitForChild("Packages").Remotes._remote.AutoLoadSettingsValue,
			SaveFrame = button.Parent.Parent.saveFrame.Name,
			SaveButton = button.Parent.Parent.saveFrame.saveButton.Name,
			multp = 2,
			MaxValue = 1,
			DefaultValue = -1,
		}
		
		SaturationragComm:Create(button,true,data)
	end
	
	local function ColorConstractSaturation()
		local ConstractdragComm = DragComponent.new()
		local ItemsCoutainer = Players.LocalPlayer.PlayerGui:WaitForChild("MainRequirementUi").coutainer.Items
		local SliderFrame = ItemsCoutainer.option.ScrollingFrame.ConstrastColorCorrectionCoutainer.Slider
		local button = SliderFrame:WaitForChild("t")

		local data = {
			_stateChanged = "GetContrastValue",
			value = "Contrast",
			percentage = 0,
			CPS = "CurrentContrastPercentage",
			SavingMethodsEnable = true,
			SaveMethodsName = "ContrastSaveMethods",
			TypeToChange = game:GetService("Lighting"):WaitForChild("ColorCorrection"),
			SaveRemote = ReplicatedStorage:WaitForChild("Packages").Remotes._remote.AutoLoadSettingsValue,
			SaveFrame = button.Parent.Parent.saveFrame.Name,
			SaveButton = button.Parent.Parent.saveFrame.saveButton.Name,
			multp = 2,
			MaxValue = 1,
			DefaultValue = -1,
		}

		ConstractdragComm:Create(button,true,data)
	end
	
	local function ColorBrightness()
		local ConstractdragComm = DragComponent.new()
		local ItemsCoutainer = Players.LocalPlayer.PlayerGui:WaitForChild("MainRequirementUi").coutainer.Items
		local SliderFrame = ItemsCoutainer.option.ScrollingFrame.BrightnessCoutainer.Slider
		local button = SliderFrame:WaitForChild("t")
				
		local data = {
			_stateChanged = "GetBrightnessValue",
			value = "Brightness",
			percentage = 0,
			CPS = "CurrentBrightnessPercentage",
			SavingMethodsEnable = true,
			SaveMethodsName = "BrightnessSaveMethods",
			TypeToChange = "Brightness",
			SaveRemote = ReplicatedStorage:WaitForChild("Packages").Remotes._remote.AutoLoadSettingsValue,
			SaveFrame = button.Parent.Parent.saveFrame.Name,
			SaveButton = button.Parent.Parent.saveFrame.saveButton.Name,
			multp = 10,
			MaxValue = 10,
			DefaultValue = 0,
		}

		ConstractdragComm:Create(button,true,data)
	end
	

	
	local function call()
		ColorConstractSaturation()
		ColorSaturation()
		ColorBrightness()
	end
	
	local promise = Promise.new(call)
	
	return self
end

function option:muteSounds()
	local dragComm = DragComponent.new()
	local ItemsCoutainer = Players.LocalPlayer.PlayerGui:WaitForChild("MainRequirementUi").coutainer.Items
	local SliderFrame = ItemsCoutainer.option.ScrollingFrame.ShadowsCoutainer.Slider
	local button = SliderFrame:WaitForChild("button")
		
	local data = {
		_stateChanged = "VolumeClient",
		SavingMethodsEnable = true,
		value = "Music",
		percentage = 0,
		CPS = "CurrentMusicPercentage",
		SaveMethodsName = "VolumeSaveMethods",
		TypeToChange = game:GetService("CollectionService"):GetTagged("MusicVolume/UiSounds"),
		SaveRemote = ReplicatedStorage:WaitForChild("Packages").Remotes._remote.AutoLoadSettingsValue,
		SaveFrame = button.Parent.Parent.saveFrame.Name,
		SaveButton = button.Parent.Parent.saveFrame.saveButton.Name,
		multp = 1,
		MaxValue = 1,
		DefaultValue = 0,
	}
	
	dragComm:Create(button,true,data)
	return self
end



function option:Start()
	self:Create_cycleChange()
	self:Graphics()
	self:muteSounds()
	return self
end

function option:Stop()
	return self
end

return option
