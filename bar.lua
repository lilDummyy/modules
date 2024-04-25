local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local Icon = require(ReplicatedStorage:WaitForChild("Packages").Icon)
local Promise = require(ReplicatedStorage:WaitForChild("Packages").Promise)
local Maid = require(ReplicatedStorage:WaitForChild("Packages").Maid)
local CodeList = require(ReplicatedStorage:WaitForChild("Packages").Lib.CodeList)
local AbbrevationSystem = require(ReplicatedStorage:WaitForChild("Packages").AbbreviationSystem)


local function loadFailedAnimation(self,index,AnimName,model)
	if not self.Animations[index] then return end
	if not model or model.ClassName ~= "Model" then return end
	if not model:FindFirstChild("Humanoid") then return end
	local Humanoid = model:FindFirstChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator")
	if self.Animations[index].FailedDummyTrack == "" then
		self.Animations[index].FailedDummyTrack = Animator:LoadAnimation(script.Parent.Parent.Animations:FindFirstChild(AnimName))
		self.Animations[index].FailedDummyTrack:Play()
	elseif self.Animations[index].FailedDummyTrack ~= "" then
		self.Animations[index].FailedDummyTrack:Stop()
		self.Animations[index].FailedDummyTrack = ""
		return loadFailedAnimation(self,index,AnimName)
	end
end

local PlayerControls

local sendReportConnection 
local enterReportConnection
local leaveReportConnection
local enterUpdateConnection
local leaveUpdateConnection
local sendUpdateConnection

local bar = {}
bar.__index = bar

local function BUILD_KNIT_CONTROLLER(controller)
	return Knit.GetController(controller)
end

local function BUILD_KNIT_SERVICE(service)
	return Knit.GetService(service)
end

bar.LoadIdleAnimation = function(self,AnimName,model)
	if not self then return end
	if not model or model.ClassName ~= "Model" then return end
	if not model:FindFirstChild("Humanoid") then return end
	local Humanoid = model:FindFirstChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator")
	if self.IdleDummyTrack == "" then
		self.IdleDummyTrack = Animator:LoadAnimation(script.Animations:FindFirstChild(AnimName))
		self.IdleDummyTrack:Play()
	elseif self.IdleDummyTrack ~= "" then
		self.IdleDummyTrack:Stop()
		self.IdleDummyTrack = ""
		return bar.LoadIdleAnimation(self,AnimName,model)
	end
end

bar.LoadFailedAnimation = function(self,AnimName,model)
	if not model or model.ClassName ~= "Model" then return end
	if not model:FindFirstChild("Humanoid") then return end
	local Humanoid = model:FindFirstChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator")
	if self.FailedDummyTrack == "" then
		self.FailedDummyTrack = Animator:LoadAnimation(script.Animations:FindFirstChild(AnimName))
		self.FailedDummyTrack:Play()
	elseif self.FailedDummyTrack ~= "" then
		self.FailedDummyTrack:Stop()
		self.FailedDummyTrack = ""
		return bar.LoadFailedAnimation(self,AnimName,model)
	end
end

bar.LoadSuccesAnimation = function(self,AnimName,model)
	if not self then return end
	if not model or model.ClassName ~= "Model" then return end
	if not model:FindFirstChild("Humanoid") then return end
	local Humanoid = model:FindFirstChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator")
	if self.SuccesDummyTrack == "" then
		self.SuccesDummyTrack = Animator:LoadAnimation(script.Animations:FindFirstChild(AnimName))
		self.SuccesDummyTrack:Play()
	elseif self.SuccesDummyTrack ~= "" then
		self.SuccesDummyTrack:Stop()
		self.SuccesDummyTrack = ""
		return bar.LoadSuccesAnimation(self,AnimName,model)
	end
end

local function CreateAnimationInstance(animName,animId)
	local animation = Instance.new("Animation")
	animation.Name = tostring(animName)
	animation.AnimationId = animId
	animation.Parent = script.Animations
	return animation
end

function bar.new()
	local self = setmetatable({
		SETTINGS_ICON = Icon.new(),
		MAID_UTILS_App = {},
		REPORT_ICON = Icon.new(),
		LEADERBOARD_ICON = Icon.new(),
		DONATION_ICON = Icon.new(),
		debouces = {
			codes_db = false,
			report_db = false,
			report_ui_db = false,
			board_db = false,
			board_ui_db = false,
		},
		Animations = {
			ReportMenuTracking = {
				SuccesDummyTrack = "",
				FailedDummyTrack = "",
				IdleDummyTrack = ""
			},
			LeaderboardMenuTracking = {
				SuccesDummyTrack = "",
				FailedDummyTrack = "",
				IdleDummyTrack = ""
			},
		},
		KNIT_SERVICES = {},
		KNIT_CONTROLLERS = {},
	},bar)
	
	local ReportDummyFrame = workspace:WaitForChild("B_script").Report.ReportDummyFrame
	local DummyFrame = workspace:WaitForChild("B_script").Leadeboard.DummyFrame
	
	task.delay(3,function()
		self.KNIT_SERVICES.Value = BUILD_KNIT_SERVICE("Value-Service")
		self.KNIT_SERVICES.Bots = BUILD_KNIT_SERVICE("Bots-Service")
		self.KNIT_SERVICES.GetDataReplication = BUILD_KNIT_SERVICE("GetDataReplicationService")
		self.KNIT_SERVICES.Description = BUILD_KNIT_SERVICE("Description-Service")
		self.KNIT_SERVICES.FrameTemplateService = BUILD_KNIT_SERVICE("FrameTemplateService")
		
		self.KNIT_SERVICES.Value:ValueConvertToIRLChange(Lighting,"GlobalShadows",
			self.KNIT_SERVICES.Value:Get(Players.LocalPlayer).Shadows)
	
		CodeList = self.KNIT_SERVICES.Value:LoadUserCodeList()
		

		self.KNIT_SERVICES.Description:LoadAndSet(3813642140,ReportDummyFrame)
		self.KNIT_SERVICES.Description:LoadAndSet(4175218688,DummyFrame)

		print(CodeList)
		self:build()
	end)
	
	CreateAnimationInstance("[ReportMenu] -> FailedTracking","rbxassetid://"..tostring(17265155128))
	CreateAnimationInstance("[ReportMenu] -> SuccesTracking","rbxassetid://"..tostring(17265139085))
	CreateAnimationInstance("[ReportMenu] -> IdleTracking","rbxassetid://"..tostring(17264922973))
	CreateAnimationInstance("[BoardMenu] -> SuccesTracking","rbxassetid://"..tostring(17282237414))
	CreateAnimationInstance("[BoardMenu] -> IdleTracking","rbxassetid://"..tostring(17264922973))
	self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
	self.LoadIdleAnimation(self.Animations.LeaderboardMenuTracking,"[BoardMenu] -> IdleTracking",DummyFrame)

	return self
end

function bar.build(self)
	if not self.MAID_UTILS_App then return end
	
	self.SETTINGS_ICON
		:setLabel("In-game settings")
		:setCaption("Open settings")
		:bindEvent("toggled",function() SoundService:PlayLocalSound(SoundService.Click) end)
		:setName("SETTINGS")
		:modifyTheme({"Dropdown", "MaxIcons", 3})
		:setImage(9405931578)
		:setTextFont(Enum.Font.GothamBold)
		:bindToggleKey(Enum.KeyCode.V)
		:setDropdown({
			Icon.new()
			:setLabel("Global Shadows")
			:bindEvent("toggled",function()
				SoundService:PlayLocalSound(SoundService.Click)
				if Lighting.GlobalShadows == false then Lighting.GlobalShadows = true else Lighting.GlobalShadows = false end
				self.KNIT_SERVICES.Value:ApplyChange("Settings","Shadows", Lighting.GlobalShadows)
			end)
			,	
		})
		
	self.REPORT_ICON
		:setLabel("Report")
		:setCaption("Open report menu")
		:bindEvent("toggled",function() 
			SoundService:PlayLocalSound(SoundService.Click) 
			local player = Players.LocalPlayer
			local playerGui = player.PlayerGui or player:WaitForChild("PlayerGui")
			local playerScript = player.PlayerScripts or player:WaitForChild("PlayerScripts")
			local character = player.Character or player.CharacterAdded:Wait()
			local camera = workspace.CurrentCamera
			local Main = playerGui:WaitForChild("Main")
			local SurfaceCameraReport = playerGui:WaitForChild("SurfaceCameraReport")
			local Coutainer = Main:FindFirstChild("Coutainer")
			local CameraPart = workspace:WaitForChild("B_script").Report.CameraPart
			local ReportDummyFrame = workspace:WaitForChild("B_script").Report.ReportDummyFrame
			if not PlayerControls then
				PlayerControls = require(playerScript:WaitForChild("PlayerModule")):GetControls()
			end
			
			self.REPORT_ICON:lock()
			self.LEADERBOARD_ICON:lock()
			self.LEADERBOARD_ICON:setLabel("Leaderboard [locked]")

			task.delay(3,function()
				self.REPORT_ICON:unlock()
			end)
			
			if (self.debouces.report_ui_db == false) and camera.CameraType ~= Enum.CameraType.Scriptable then
				TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 0}):Play()
				TweenService:Create(camera,TweenInfo.new(.25),{FieldOfView = 90}):Play()
				SurfaceCameraReport.AlwaysOnTop = true
				PlayerControls:Disable()
				CameraPart.Orientation = Vector3.new(0,-90,0)		
				task.delay(0.25,function()			
					self.debouces.report_ui_db = true
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CameraSubject = CameraPart
					camera.CFrame = CameraPart.CFrame
				end)
				task.delay(1,function()
					TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
				end)
		elseif (self.debouces.report_ui_db == true) then
				TweenService:Create(Coutainer,TweenInfo.new(.15),{BackgroundTransparency = 0}):Play()
				TweenService:Create(camera,TweenInfo.new(.25),{FieldOfView = 70}):Play()
				SurfaceCameraReport.AlwaysOnTop = false
				CameraPart.Orientation = Vector3.new(0,-90,0)		
				task.delay(0.25,function()			
					camera.CameraType = Enum.CameraType.Custom
					camera.CameraSubject = character
					camera.CFrame = character:GetPivot()
				end)
				self.LEADERBOARD_ICON:unlock()
				self.LEADERBOARD_ICON:setLabel("Leaderboard")
				PlayerControls:Enable()
				task.delay(1,function()
					self.debouces.report_ui_db = false
					TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
				end)
			end
				
			if not sendReportConnection then
				sendReportConnection = SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").MouseButton1Down:Connect(function()
					if (string.len(SurfaceCameraReport.ReportFrame.TextBoxFrame.TextBox.Text:gsub("%s+", "")) > 5) then
						if (self.debouces.report_db == false) then
							self.debouces.report_db = true
							self.KNIT_SERVICES.Bots:SendReport(SurfaceCameraReport.ReportFrame.TextBoxFrame.TextBox.Text)
							SoundService:PlayLocalSound(SoundService.succes)
							SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Succes, Thank you !"

							if self.Animations.ReportMenuTracking.IdleDummyTrack ~= "" then
								ReportDummyFrame.Head.Attachment.ParticleEmitter:Emit(50)
								self.Animations.ReportMenuTracking.IdleDummyTrack:Stop()
								self.Animations.ReportMenuTracking.IdleDummyTrack = ""
								self.LoadSuccesAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> SuccesTracking",ReportDummyFrame)

								task.delay(2,function()
									if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
										self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
									end
									if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
										self.Animations.ReportMenuTracking.FailedDummyTrack = ""
									end
									self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
								end)
							else
								ReportDummyFrame.Head.Attachment.ParticleEmitter:Emit(50)
								self.LoadSuccesAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> SuccesTracking",ReportDummyFrame)
								task.delay(2,function()
									if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
										self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
									end
									if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
										self.Animations.ReportMenuTracking.FailedDummyTrack = ""
									end
									self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
								end)
							end

							task.delay(20,function()self.debouces.report_db = false end)
							task.delay(1,function() SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Send Report" end)
						elseif self.debouces.report_db == true then
							SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Cooldown enable"
							SoundService:PlayLocalSound(SoundService.fld)

							if self.Animations.ReportMenuTracking.IdleDummyTrack ~= "" then
								self.Animations.ReportMenuTracking.IdleDummyTrack:Stop()
								self.Animations.ReportMenuTracking.IdleDummyTrack = ""
								self.LoadFailedAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> FailedTracking",ReportDummyFrame)
								task.delay(1.25,function()
									if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
										self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
									end
									if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
										self.Animations.ReportMenuTracking.FailedDummyTrack = ""
									end
									self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
								end)
							else
								self.LoadFailedAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> FailedTracking",ReportDummyFrame)
								task.delay(1.25,function()
									if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
										self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
									end
									if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
										self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
										self.Animations.ReportMenuTracking.FailedDummyTrack = ""
									end
									self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
								end)
							end

							task.delay(1,function() SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Send Report" end)
						end
					else 
						SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Please write 5 words minmum"

						if self.Animations.ReportMenuTracking.IdleDummyTrack ~= "" then
							self.Animations.ReportMenuTracking.IdleDummyTrack:Stop()
							self.Animations.ReportMenuTracking.IdleDummyTrack = ""
							self.LoadFailedAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> FailedTracking",ReportDummyFrame)
							task.delay(1.25,function()
								if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
									self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
									self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
								end
								if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
									self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
									self.Animations.ReportMenuTracking.FailedDummyTrack = ""
								end
								self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
							end)
						else
							self.LoadFailedAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> FailedTracking",ReportDummyFrame)
							task.delay(1.25,function()
								if self.Animations.ReportMenuTracking.SuccesDummyTrack ~= "" then
									self.Animations.ReportMenuTracking.SuccesDummyTrack:Stop()
									self.Animations.ReportMenuTracking.SuccesDummyTrack = ""
								end
								if self.Animations.ReportMenuTracking.FailedDummyTrack ~= "" then
									self.Animations.ReportMenuTracking.FailedDummyTrack:Stop()
									self.Animations.ReportMenuTracking.FailedDummyTrack = ""
								end
								self.LoadIdleAnimation(self.Animations.ReportMenuTracking,"[ReportMenu] -> IdleTracking",ReportDummyFrame)
							end)
						end

						SoundService:PlayLocalSound(SoundService.fld)
						task.delay(1,function() SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").Text = "Send Report" end)
					end
				end)
			end
			
			if not enterReportConnection then
				enterReportConnection = SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").MouseEnter:Connect(function()
					SoundService:PlayLocalSound(SoundService.Mouse_hover)
					TweenService:Create(SurfaceCameraReport.ReportFrame.SendFrame.UIScale,TweenInfo.new(.25),{Scale = 1.1}):Play()
					TweenService:Create(SurfaceCameraReport.ReportFrame.SendFrame.UIStroke,TweenInfo.new(.25),{Thickness = 2.5}):Play()
				end)
			end
			
			if not leaveReportConnection then
				leaveReportConnection = SurfaceCameraReport.ReportFrame.SendFrame:FindFirstChildOfClass("TextButton").MouseLeave:Connect(function()
					TweenService:Create(SurfaceCameraReport.ReportFrame.SendFrame.UIScale,TweenInfo.new(.25),{Scale = 1}):Play()
					TweenService:Create(SurfaceCameraReport.ReportFrame.SendFrame.UIStroke,TweenInfo.new(.25),{Thickness = 0}):Play()
				end)
			end
					
		end)
		:setName("report")
		:setImage(11379131842)
		:setTextFont(Enum.Font.GothamBold)
		:align("Right")
	
	self.LEADERBOARD_ICON
		:setLabel("Leaderboard")
		:setName("Leaderboad")
		:setTextFont(Enum.Font.GothamBold)
		:align("Right")
		:setImage(5107166345)
		:bindEvent("toggled",function()
			SoundService:PlayLocalSound(SoundService.Click) 
			local player = Players.LocalPlayer
			local playerGui = player.PlayerGui or player:WaitForChild("PlayerGui")
			local playerScript = player.PlayerScripts or player:WaitForChild("PlayerScripts")
			local character = player.Character or player.CharacterAdded:Wait()
			local camera = workspace.CurrentCamera
			local Main = playerGui:WaitForChild("Main")
			local SurfaceCameraLeaderboard = playerGui:WaitForChild("SurfaceCameraLeaderboard")
			local Coutainer = Main:FindFirstChild("Coutainer")
			local CameraPart = workspace:WaitForChild("B_script").Report.CameraPart
			local DummyFrame = workspace:WaitForChild("B_script").Leadeboard.DummyFrame
			if not PlayerControls then
				PlayerControls = require(playerScript:WaitForChild("PlayerModule")):GetControls()
			end
			
			self.REPORT_ICON:lock()
			self.LEADERBOARD_ICON:lock()
			self.REPORT_ICON:setLabel("Report [locked]")

			task.delay(3,function()
				self.LEADERBOARD_ICON:unlock()
			end)
			
			if (self.debouces.board_ui_db == false) and camera.CameraType ~= Enum.CameraType.Scriptable then
				TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 0}):Play()
				TweenService:Create(camera,TweenInfo.new(.25),{FieldOfView = 90}):Play()
				SurfaceCameraLeaderboard.AlwaysOnTop = true
				PlayerControls:Disable()
				CameraPart.Orientation = Vector3.new(0,0,0)
				task.delay(0.25,function()			
					self.debouces.board_ui_db = true				
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CameraSubject = CameraPart
					camera.CFrame = CameraPart.CFrame
				end)
				task.delay(1,function()
					TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
				end)
			elseif (self.debouces.board_ui_db == true) then
				TweenService:Create(Coutainer,TweenInfo.new(.15),{BackgroundTransparency = 0}):Play()
				TweenService:Create(camera,TweenInfo.new(.25),{FieldOfView = 70}):Play()
				SurfaceCameraLeaderboard.AlwaysOnTop = false
				CameraPart.Orientation = Vector3.new(0,0,0)
				task.delay(0.25,function()			
					camera.CameraType = Enum.CameraType.Custom
					camera.CameraSubject = character
					camera.CFrame = character:GetPivot()
				end)
				self.REPORT_ICON:unlock()
				self.REPORT_ICON:setLabel("Report")
				PlayerControls:Enable()
				task.delay(1,function()
					self.debouces.board_ui_db = false
					TweenService:Create(Coutainer,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
				end)
			end
				
			if not sendUpdateConnection then
				sendUpdateConnection = SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").MouseButton1Down:Connect(function()
					SoundService:PlayLocalSound(SoundService.Click)
					local pageResult = self.KNIT_SERVICES.GetDataReplication:Page()
					if type(pageResult) == "table" then
						if (#pageResult > 0) then
							
						if self.Animations.LeaderboardMenuTracking.IdleDummyTrack ~= "" then
							DummyFrame.Head.Attachment.ParticleEmitter:Emit(50)
							self.Animations.LeaderboardMenuTracking.IdleDummyTrack:Stop()
							self.Animations.LeaderboardMenuTracking.IdleDummyTrack = ""
							self.LoadSuccesAnimation(self.Animations.LeaderboardMenuTracking,"[BoardMenu] -> SuccesTracking",DummyFrame)

							task.delay(2,function()
								if self.Animations.LeaderboardMenuTracking.SuccesDummyTrack ~= "" then
									self.Animations.LeaderboardMenuTracking.SuccesDummyTrack:Stop()
									self.Animations.LeaderboardMenuTracking.SuccesDummyTrack = ""
								end
								if self.Animations.LeaderboardMenuTracking.FailedDummyTrack ~= "" then
									self.Animations.LeaderboardMenuTracking.FailedDummyTrack:Stop()
									self.Animations.LeaderboardMenuTracking.FailedDummyTrack = ""
								end
								self.LoadIdleAnimation(self.Animations.LeaderboardMenuTracking,"[BoardMenu] -> IdleTracking",DummyFrame)
							end)
						else
							DummyFrame.Head.Attachment.ParticleEmitter:Emit(50)
							self.LoadSuccesAnimation(self.Animations.LeaderboardMenuTracking,"[BoardMenu] -> SuccesTracking",DummyFrame)
							task.delay(2,function()
								if self.Animations.LeaderboardMenuTracking.SuccesDummyTrack ~= "" then
									self.Animations.LeaderboardMenuTracking.SuccesDummyTrack:Stop()
									self.Animations.LeaderboardMenuTracking.SuccesDummyTrack = ""
								end
								if self.Animations.LeaderboardMenuTracking.FailedDummyTrack ~= "" then
									self.Animations.LeaderboardMenuTracking.FailedDummyTrack:Stop()
									self.Animations.LeaderboardMenuTracking.FailedDummyTrack = ""
								end
								self.LoadIdleAnimation(self.Animations.LeaderboardMenuTracking,"[BoardMenu] -> IdleTracking",DummyFrame)
							end)
						end
						
							for i,d in SurfaceCameraLeaderboard.UFrame.ScrollingFrame:GetChildren() do
								if d:IsA("Frame") then
									d:Destroy()
								else
									continue
								end
							end
							
							for i,data in ipairs(pageResult) do
								local frame = self.KNIT_SERVICES.FrameTemplateService:GetTemplate("BoardTemplate")
								if type(frame) ~= "boolean" then
									frame.Parent = SurfaceCameraLeaderboard.UFrame.ScrollingFrame
									frame.LayoutOrder = i
									frame.Name = data.key
									frame.ImageLabel.Image = Players:GetUserThumbnailAsync(data.key,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
									frame.TextLabel.Text = "Top: "..i.."| $R"..AbbrevationSystem(tonumber(data.value)).. "| @"..Players:GetNameFromUserIdAsync(data.key)
								end
							end
						else
							SoundService:PlayLocalSound(SoundService.fld)
							SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").Text = "Leaderboard is empty"
							task.delay(1,function()
								SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").Text = "Update"
							end)
						end
					else
						SoundService:PlayLocalSound(SoundService.fld)
						SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").Text = "Failed to fetch data."
						task.delay(1,function()
							SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").Text = "Update"
						end)
					end
				end)
			end	
				
			if not enterUpdateConnection then
				enterUpdateConnection = SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").MouseEnter:Connect(function()
					SoundService:PlayLocalSound(SoundService.Mouse_hover)
					TweenService:Create(SurfaceCameraLeaderboard.UFrame.UpdateFrame.UIScale,TweenInfo.new(.25),{Scale = 1.1}):Play()
					TweenService:Create(SurfaceCameraLeaderboard.UFrame.UpdateFrame.UIStroke,TweenInfo.new(.25),{Thickness = 2.5}):Play()
				end)
			end

			if not leaveUpdateConnection then
				leaveUpdateConnection = SurfaceCameraLeaderboard.UFrame.UpdateFrame:FindFirstChildOfClass("TextButton").MouseLeave:Connect(function()
					TweenService:Create(SurfaceCameraLeaderboard.UFrame.UpdateFrame.UIScale,TweenInfo.new(.25),{Scale = 1}):Play()
					TweenService:Create(SurfaceCameraLeaderboard.UFrame.UpdateFrame.UIStroke,TweenInfo.new(.25),{Thickness = 0}):Play()
				end)
			end
			
		end)
	
	self.DONATION_ICON
		:setCaption("Open robux shop")
		:bindEvent("toggled",function() SoundService:PlayLocalSound(SoundService.Click) end)
		:setName("DONATION")
		:modifyTheme({"Dropdown", "MaxIcons", 3})
		:setImage(13885942899)
		:bindToggleKey(Enum.KeyCode.B)
		:setDropdown({
			Icon.new()
			:setLabel("$R 10")
			,
			Icon.new()
			:setLabel("$R 100")
			,
			Icon.new()
			:setLabel("$R 500")
			,
			Icon.new()
			:setLabel("$R 1000")
			,
			Icon.new()
			:setLabel("$R 5000")
			,
			Icon.new()
			:setLabel("$R 10000")
			,
		})
	
end

return bar
