local Players = game:GetService("Players")
local runService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(Knit.Util.Promise)
local Signal = require(Knit.Util.Signal)
local Option = require(Knit.Util.Option)
local Roact = require(Knit.Util.Roact)
local Maid = require(Knit.Util.Maid)
local Symbol = require(Knit.Util.Symbol)
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local ProfilsComponent = require(ServerScriptService.Mains.Modules.DataComponent.ProfilesComponents)

local serverComm  = ServerComm.new(ReplicatedStorage.Packages.Remotes,"ReceiveSaleItemService")

serverComm:BindFunction("SaleItemFromServer",function(player:Player,item)
	if (player and item) then
		local character = player.Character or player.CharacterAdded:Wait()
		local backpack = player:WaitForChild("Backpack")
		local playerData = ProfilsComponent.ProfilesAttach[player.UserId].Data.Settings
		
		local function setValueToPlayer(value:number)
			local leaderstats = player:FindFirstChild("leaderstats")
			local Argent = leaderstats:WaitForChild("Argent(s)")
			Argent.Value += value
			playerData.leaderstats.Argents = Argent.Value
			return "Process"
		end
		
		if character:FindFirstChild(item) then
			local saleItem = character:FindFirstChild(item).__sale.Value
			setValueToPlayer(saleItem)
		elseif backpack:FindFirstChild(item) then
			local saleItem = backpack:FindFirstChild(item).__sale.Value
			setValueToPlayer(saleItem)
		elseif ServerStorage.ToolsComponent:FindFirstChild(item) then
			local saleItem = ServerStorage.ToolsComponent:FindFirstChild(item).__sale.Value
			setValueToPlayer(saleItem)
		end
		
		return `[Items Service]: Procces traceback : {debug.traceback("[Process from Knit]",2)}`
	end
end)

local ToolsComponent = ServerStorage:WaitForChild("ToolsComponent")

local module = Knit.CreateService{
	Name = "InventoryKnitMain",
	Client = {
		ItemsAddedToClient = Knit.CreateSignal(),
		ItemsRemoveClient = Knit.CreateSignal(),
	},
}


function module:ItemsAddedForClient(plr,item : string | Tool? | Instance? )
	if ToolsComponent:FindFirstChild(item) then
		if ToolsComponent:FindFirstChild(item):IsA("Tool") then			
			local clone = ToolsComponent:FindFirstChild(item):Clone()
			clone.Parent = plr:WaitForChild("Backpack")
			self.Client.ItemsAddedToClient:Fire(plr,{Add_result = "Item added : "..tostring(item).." !" ,added_Message = "Tool .. "..tostring(item).." ajoutée",tool_Owner = plr})
			print("[Items Service]: Changement en cours de traitement")
			return "Succès"
		end
	else
		return warn("[Items Service]: Changement annulé une erreur détecter pendant la recherche de l'objet")
	end
	return warn("[Items Service]: Fonction non valable !")
end

function module:GetPurchaseState(plr : Player,name)
	assert(type(name) == "string","argument n doit être une string.")
	if plr:IsDescendantOf(Players) then
		local character = plr.Character or plr.CharacterAdded:Wait()
		local backpack = plr:WaitForChild("Backpack")
		if not character then return end
		if not backpack then return end
		local obj = character:FindFirstChild(name)
		local inBackpack = backpack:FindFirstChild(name)
		if (not obj) or (not inBackpack) then
			return false
		elseif (obj) or (inBackpack) then
			return true
		end
	else
		return warn("[Items Service]: argument plr n'est pas un enfant du Service Players")
	end
end

function module:GetItemFromName(n)
	assert(type(n) == "string","argument n doit être une string.")
	local item = ServerStorage.ToolsComponent:WaitForChild(n)
	if (item) then
		return item.Name
	end
	error(`[Items Service]: echoué: item non reçu {n} `)
end

function module:PurchaseItem(player,n)
	if not (player) then return end
	local itemName = self:GetItemFromName(n)
	if (itemName) then
		local item = ServerStorage.ToolsComponent:WaitForChild(itemName)
		if (item) then
			return "Succès"
		end
	end
	error("[Items Service]: Erreur pendant l'achat de cette objet, auriez vous fait une erreur volontaire?"..`{debug.traceback("Current Execution Line",2)}`)
end

function module.Client:_PurchaseGranded(plr,name)
	return self.Server:GetPurchaseState(plr,name)
end

function module.Client:PurchaseResult(player,n)
	return self.Server:PurchaseItem(player,n)
end

function module.Client:GetItemFromName(player,n)
	return self.Server:GetItemFromName(n)
end

function module:ItemsRemovedForClient(plr,item)
	local backpack = plr:WaitForChild("Backpack")
	local character = plr.Character or plr.CharacterAdded:Wait()
	if character:FindFirstChild(item) then
		self.Client.ItemsRemoveClient:Fire(plr,{Remove_result = "Item removed : "..item.." !" ,removeMessage = "Tool .. "..item.." retiré" ,oldTool_Owner = plr})		
		character:FindFirstChild(item):Destroy()
	end
	if backpack:FindFirstChild(item) then
		self.Client.ItemsRemoveClient:Fire(plr,{Remove_result = "Item removed : "..item.." !" ,removeMessage = "Tool .. "..item.." retiré" ,oldTool_Owner = plr})
		backpack:FindFirstChild(item):Destroy()
	end
end

function module.Client:RemoveObject(plr,item)
	return self.Server:ItemsRemovedForClient(plr,item)
end

function module:Equip(plr : Player,item)
	assert(plr:IsDescendantOf(Players),"argument (plr) is not a Member of PlayersService")
	local backpack = plr:WaitForChild("Backpack")
	local obj = backpack:FindFirstChild(item) or ServerStorage.ToolsComponent:FindFirstChild(item)
	if (obj) then
		print("[Items Service]: Equip Started")
		local c = obj:Clone()
		c.Parent = plr.Character or plr.CharacterAdded:Wait()
		if not (self.oldItem) then
			self.oldItem = tostring(obj.Name)
		end
		return true
	end
	return false
end


function module:GetItemFromBackpackChid(plr,item)
	assert(plr:IsDescendantOf(Players),"argument (plr) is not a Member of PlayersService")
	local backpack = plr:WaitForChild("Backpack")
	if (backpack:FindFirstChild(tostring(item))) then
		return backpack:FindFirstChild(tostring(item)).Name
	else
		return false
	end
end

function module:GetItemNameFromServerStorage(plr,item)
	local item = ServerStorage.ToolsComponent:FindFirstChild(item)
	if (item) then
		return item.Name
	else
		return false
	end
end


function module:GetItemFromCharacterChid(plr,item)
	if (item) and (plr) then
		local character = plr.Character or plr.CharacterAdded:Wait()
		if (character) then
			if (character:FindFirstChild(tostring(item))) then
				return character:FindFirstChild(tostring(item))
			else
				return false
			end
		end
	end
end

function module.Client:Equip(plr,item)
	local getItem = self.Server:GetItemFromBackpackChid(plr,tostring(item)) or self.Server:GetItemNameFromServerStorage(plr,tostring(item))
	if (getItem ~= false) then
		return self.Server:Equip(plr,item)
	else
		return warn("[Items Service]: failed to get: ["..tostring(item).."]")
	end
end

function module:UnEquip(plr,item)
	if (item) and (plr) then
		print("[Items Service]: UnEquip Started")
		local character = plr.Character or plr.CharacterAdded:Wait()
		if (character) then
			if (character:FindFirstChild(tostring(item))) then
				character:FindFirstChild(tostring(item)).Parent = Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].Component.ComponentTools
				Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].Component.ComponentTools:WaitForChild(tostring(item)):Destroy()
				if self.oldItem then
					Knit.Util.Menu["InventoryModule.all"]["Inventory.Items"].__bindable.ClientService.RefreshItemSignal:FireClient(plr,self.oldItem or item)
					self.oldItem = nil
				end
				return true
			else
				return warn("[Items Service]: failed to remove: ["..tostring(item).."]")
			end
		end
	end
end

function module.Client:UnEquip(plr,item)
	local getItem = self.Server:GetItemFromCharacterChid(plr,tostring(item))
	if (getItem ~= false) then
		return self.Server:UnEquip(plr,getItem)
	else
		return warn("[Items Service]: impossible d'obtenir : ["..tostring(item).."], cette erreur la n'est pas important car il arrive que le joueur se reset lors de ce renvoie"), self.Server:UnEquip(plr,self.Server.oldItem)
	end
end

function module.Client:ReceivedAddedItems(plr,item)
	return self.Server:ItemsAddedForClient(plr,item)
end


return module
