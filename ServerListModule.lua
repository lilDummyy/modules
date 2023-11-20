local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Option = require(ReplicatedStorage.Packages.Option)


local module = {}

local function checkCurrentRunMode()
	if (RunService:IsStudio()) then
		return true
	elseif (RunService:IsServer()) then
		return true
	elseif RunService:IsRunMode() then
		return false
	elseif (RunService:IsClient()) then
		return false
	end
end

function module:CreateEncodeMethods()
	if not checkCurrentRunMode() then return warn("failed to encode this server") end
	return {
		[game.JobId] = {
			Type = "add",
			MaxPlayers = Players.MaxPlayers,
			AllPlayers = #Players:GetPlayers(),
			FriendsInThisServer = {}
		},
		Region = HttpService:JSONDecode(HttpService:GetAsync("http://ip-api.com/json/")) or "Impossible d'obtenir la region de ce serveur.",
		Job = game.JobId,
		Place = game.PlaceId,
	} 
end

function module:DestroyDecodeMethods(data)
	if not checkCurrentRunMode() then return warn("failed to Decode this server") end
	if type(data) ~= "table" then return end
	
	local Type
	local MaxPlayers
	local friends
	local job
	local place
	local region
	
	
	for i,v in pairs(data) do
		if (type(v) == "table") then
			for index,value in pairs(v) do
				if index == "Type" then
					Type = value
				elseif index == "MaxPlayers" then
					MaxPlayers = value
				elseif index == "FriendsInThisServer" then
					friends = value
				end
			end
		elseif i == "Job" then
			job = v
		elseif i == "Place" then
			place = v
		end
		if i == "Region" then
			region = v
		end
	end
	
	return {
		["Type"] = Type,
		["MaxPlayers"] = MaxPlayers,
		["Friends"] = friends,
		["Job"] = job,
		["Place"] = place,
		["Region"] = region
	}
end

return module
