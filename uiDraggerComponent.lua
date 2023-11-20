--[[]
Dummy
create dragger for ui (i think i will remake it)
--02/09/23
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages:FindFirstChild("Knit"))
local keyboard = require(Knit.Util.Input).Keyboard
local Promise = require(Knit.Util.Promise)
local IsSavingModule = require(Knit.Util.IsSavingModule)
local Thread = require(Knit.Util.Thread)

local RemoteClientComponent = require(Knit.Util.RemoteClientComponent)
local remoteClientComm = RemoteClientComponent.new()

local DragComponent = {}
DragComponent.__index = DragComponent

function DragComponent.new()
	local self = setmetatable({},DragComponent)
	self.keyboardController = keyboard.new()
	self.indicator = {}
	self.usePromise = {}
	self.currentConnectionUp = nil
	self.currentConnectionDown = nil
	self.keyUp = nil
	self.dataDown = nil
	self.buttonToBind = {}
	return self
end

local function snap(value,snapvalue)
	return value - (value % snapvalue)
end

function DragComponent.has()
	if (CollectionService:HasTag(Knit.Util.Menu.Setting.setting_Option.DragClockTime._drag,"DragDetectors")) then
		return true
	else
		return false
	end
end

function DragComponent:GetState(args)
	return self.buttonToBind or {["failed"] = args}
end

function DragComponent:Create(button,canDestroy,data: {f:any,DefaultValue : number | string})
	assert(self:GetState("0 instance in self.buttonToBind").failed == nil,`{self:GetState("1 instance in self.buttonToBind").failed}`)
	assert(typeof(button) == "Instance" ,"button can't be nil pls set a TextButtonObject")
	assert(button.ClassName == "TextButton","button can't be nil pls set a TextButtonObject")
	assert(typeof(canDestroy) == "boolean","canDestroy argument must be a boolean")
	--assert(self.buttonToBind[button.Name] == nil,`{self.buttonToBind[button.Name]} can't be the same value`)
	if self.currentConnectionDown then return end
	if self.currentConnectionUp then return end
	if self.keyUp then return end
	
	local dataSaved = IsSavingModule.new(data["SaveMethodsName"])
	
	local has:boolean,others = pcall(self.has,self)
	if (not has) then return warn(others) end
	
	self.buttonToBind[button.Name] = button
	
	if (self.buttonToBind[button.Name]) then	
		
		local promise = Promise.new(function()
			local connection
			local percentage
			
			self.currentConnectionDown = self.buttonToBind[button.Name].MouseButton1Down:Connect(function()
				if (not self.indicator[button.Name]) then
					self.indicator[button.Name] = true
					if (self.indicator[button.Name] == true) then					
						if (self.buttonToBind[button.Name] == nil) then
							self.buttonToBind[button.Name] = button
						end
						
						connection = RunService.Heartbeat:Connect(function()
							local mouseLocation = UserInputService:GetMouseLocation()
							local relativePosition = mouseLocation-self.buttonToBind[button.Name].Parent.AbsolutePosition
							percentage = math.round(snap(math.clamp(relativePosition.X/self.buttonToBind[button.Name].Parent.AbsoluteSize.X,0,1),0.01)*1000)/1000
														
							if (percentage <0.02) then
								if (self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton")~=nil) then
									self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton").Text = tostring((data.DefaultValue))
								elseif (self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel")~=nil) then
									self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel").Text = tostring((data.DefaultValue))
								end
							else
								if (self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton")~=nil) then
									if (data.DefaultValue <0) then
										self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton").Text = string.format("%.2f",math.clamp((percentage-0.5)*data["multp"],-1,1))
									else
										self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton").Text = string.format("%.2f",(percentage)*data["multp"])
									end
								elseif (self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel")~=nil) then
									if (data.DefaultValue <0) then
										self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel").Text = string.format("%.2f",math.clamp((percentage-0.5)*data["multp"],-1,1))
									else
										self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel").Text = string.format("%.2f",(percentage)*data["multp"])
									end
								end
							end 
							
							if (data["percentage"]) then data["percentage"] = (percentage) end
							
							if typeof((data["TypeToChange"])) == "table" then
								for index,value in data do
									if (typeof(value) == "table") then
										for index,childValue in value do
											if (typeof(childValue) == "Instance") and (childValue.ClassName == "Sound") then
												if (data["multp"]>0) then
													childValue.Volume = math.clamp((percentage)*data["multp"],0,data["MaxValue"])
												else
													childValue.Volume = math.clamp((percentage),0,data["MaxValue"])
												end
											end
										end
									end
								end
							elseif(typeof(data["TypeToChange"])) == "Instance" then
								if (data["TypeToChange"].ClassName == "ColorCorrectionEffect") then
									if data["value"] == "Saturation" then
										data["TypeToChange"].Saturation = math.clamp((percentage-0.5)*data["multp"],-1,1)
									elseif data["value"] == "Contrast" then
										data["TypeToChange"].Contrast = math.clamp((percentage-0.5)*data["multp"],-1,1)
									end
								end
							else
								if ((data["TypeToChange"]) == "Brightness") then
									Lighting.Brightness = math.clamp((percentage)*data["multp"],0,data["MaxValue"])
								end
							end
							self.buttonToBind[button.Name].Position	= UDim2.fromScale((percentage),self.buttonToBind[button.Name].Position.Y.Scale)
						end)
						
					end
				end
			end)
			
			self.dataDown = self.buttonToBind[button.Name].Parent.Parent:WaitForChild(data["SaveFrame"]):WaitForChild(data["SaveButton"]).MouseButton1Down:Connect(function()
				local getButtonComponents = self.buttonToBind[button.Name].Parent.Parent:WaitForChild(data["SaveFrame"]):FindFirstChildOfClass("TextLabel")
				SoundService:PlayLocalSound(SoundService["UI Click"])
				if (getButtonComponents) and dataSaved:GetState(data["SaveMethodsName"]) == false then
					dataSaved:Enable(data["SaveMethodsName"])
					data["SavingMethodsEnable"] = true
					TweenService:Create(getButtonComponents,TweenInfo.new(.25),{TextColor3 = Color3.fromRGB(33, 33, 33)}):Play()
				elseif (getButtonComponents) and dataSaved:GetState(data["SaveMethodsName"]) == true then
					dataSaved:Disable(data["SaveMethodsName"])
					data["SavingMethodsEnable"] = false
					TweenService:Create(getButtonComponents,TweenInfo.new(.25),{TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				end
			end)
			
			self.keyUp = self.keyboardController.KeyDown:Connect(function(key : KeyCode)
				if (key == Enum.KeyCode.E) then
					if (typeof(connection) == "RBXScriptConnection") and (self.indicator[button.Name] == true) then
						connection:Disconnect()
						connection = nil
						self.indicator[button.Name] = nil
						
						
						if (dataSaved:GetState(data["SaveMethodsName"]) == true) then
							local getLastInformation = {
								p = Players.LocalPlayer,
								[data["CPS"]] = data["percentage"],
								[data["_stateChanged"]] = tonumber(self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel").Text) or tonumber(self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton").Text),
								SavingMode = dataSaved:GetState(data["SaveMethodsName"]),
								Name = data["_stateChanged"]
							}
							remoteClientComm:Fire(data["SaveRemote"],getLastInformation)
							remoteClientComm:ConnectClientSingleEvent(data["SaveRemote"],false,nil)
						end
												
					end
				end
			end)
			
			self.currentConnectionUp = self.buttonToBind[button.Name].MouseButton1Up:Connect(function()
				if (typeof(connection) == "RBXScriptConnection") and (self.indicator[button.Name] == true) then
					connection:Disconnect()
					connection = nil
					self.indicator[button.Name] = nil

					--if (data["isClientEventHandler"] == true) then
					--	remoteClientComm:ConnectClientSingleEvent(data._remote[""],false,data.f)
					--end
					
					if (dataSaved:GetState(data["SaveMethodsName"]) == true) then
						local getLastInformation = {
							p = Players.LocalPlayer,
							[data["CPS"]] = data["percentage"],
							[data["_stateChanged"]] = tonumber(self.buttonToBind[button.Name]:FindFirstChildOfClass("TextLabel").Text) or tonumber(self.buttonToBind[button.Name]:FindFirstChildOfClass("TextButton").Text),
							SavingMode = dataSaved:GetState(data["SaveMethodsName"]),
							Name = data["_stateChanged"]
						}
						remoteClientComm:Fire(data["SaveRemote"],getLastInformation)
						remoteClientComm:ConnectClientSingleEvent(data["SaveRemote"],false,nil)
					end
					
				end
			end)
			
		end):catch(warn)
		
	end
	return self
end

return DragComponent
