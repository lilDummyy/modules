--[=[
---------
@Dummy

02/09/23
create saving state if the player want to save some value or no.
---------------]] 


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfilsModulesFolder = ReplicatedStorage:WaitForChild("ProfilsModules")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(Knit.Util.Promise)
local Thread = require(Knit.Util.Thread)
local Option = require(Knit.Util.Option)
local Maid = require(Knit.Util.Maid)

local IsSavingModule = {}
IsSavingModule.__index = IsSavingModule

function IsSavingModule.new(saveMethodsName)
	local self = setmetatable({},IsSavingModule)
	self[saveMethodsName] = false
	return self
end

function IsSavingModule:Enable(saveMethodsName)
	self[saveMethodsName] = true
	return self
end

function IsSavingModule:Disable(saveMethodsName)
	self[saveMethodsName] = false
	return self
end

function IsSavingModule:GetState(saveMethodsName)
	return self[saveMethodsName]
end

return IsSavingModule
