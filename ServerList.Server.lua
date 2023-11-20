local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

local Promise = require(ReplicatedStorage.Packages.Promise)

local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local Comm = ServerComm.new(ReplicatedStorage.Packages,"ServerListService")
local ServerListService = require(script.Parent.ServerListModule)

local mainServer = {}

Comm:BindFunction("GetServerForPlayers",function()
	return mainServer
end)

local function loop()
	while true do
		local ServerEncode = nil
		local data = Promise.new(function(resolve,reject,onCancel)
			ServerEncode = ServerListService:CreateEncodeMethods()
			if (type(ServerEncode) == "table") then
				Promise.new(function()
					local succes , err = pcall(function()
						return MessagingService:PublishAsync("UpdateServerList",ServerEncode)
					end)
					if not (succes) then
						warn(err, "Failed to publish global server <[(ServerEncode)]>")
					end
				end):catch(warn)
			end
		end):catch(function()
			ServerEncode = "Failed result"
			return warn("Failed to get this server from this async.")
		end)

		task.wait(5)
	end
end

task.spawn(loop)

MessagingService:SubscribeAsync("UpdateServerList",function(async)
	local DecodeData = ServerListService:DestroyDecodeMethods(async.Data)
	if (type(DecodeData) == "table") then
		if (DecodeData.Type == "add") then
			if (DecodeData.Friends) then
				for i,players in Players:GetPlayers() do
					if not (table.find(DecodeData.Friends,players.UserId)) then
						table.insert(DecodeData.Friends,players.UserId)
					else
						table.remove(DecodeData.Friends,table.find(DecodeData.Friends,players.UserId)) 
						table.insert(DecodeData.Friends,players.UserId)
					end
				end
			end
			table.remove(mainServer,table.find(mainServer,async.Data.Job))
			
			for i,v in pairs(mainServer) do
				if i == async.Data.Job then
					table.remove(mainServer,table.find(mainServer,i))
				end	
			end
			
			
			mainServer[async.Data.Job] = async.Data
			ReplicatedStorage.Packages.Menu.Configuration.Servers.ServerToClientAsync:FireAllClients("add",DecodeData.Job,DecodeData.MaxPlayers,DecodeData.Place,DecodeData.Region)
		elseif (DecodeData.Type == "remove") then
			if (DecodeData.Friends) then
				for i,players in Players:GetPlayers() do
					if (table.find(DecodeData.Friends,players.UserId)) then
						table.remove(DecodeData.Friends,table.find(DecodeData.Friends,players.UserId))
					end
				end
			end
			table.remove(mainServer,table.find(mainServer,async.Data.Job))
			
			for i,v in pairs(mainServer) do
				if i == async.Data.Job then
					table.remove(mainServer,table.find(mainServer,i))
				end
			end
			
			ReplicatedStorage.Packages.Menu.Configuration.Servers.ServerToClientAsync:FireAllClients("remove",DecodeData.Job)
		end
		return mainServer
	end
end)


game:BindToClose(function()
	return MessagingService:PublishAsync("UpdateServerList",{[game.JobId] = {Type = "remove"}, ["Job"] = game.JobId,["Place"] = game.PlaceId})
end)			
