ENT.Type 			= "anim"
ENT.Base 			= "sent_item_base"
ENT.PrintName		= "Base Item"
ENT.Author			= "victormeriqui & C0BRA"
ENT.Information		= ""
ENT.Category		= "Endure It"

ENT.Spawnable			= false
ENT.AdminSpawnable		= true

function ENT:InvokeAction(id, pl)
	if id == "pip" and CLIENT then
		net.Start("action_item_stanag_1")
			net.WriteEntity(self)
			net.WriteEntity(LocalPlayer():GetActiveWeapon())
		net.SendToServer()
	end
end

function ENT:Move(oldpos, newpos)
	
end

function ENT:GetActions()
	local ret = {}
	table.insert(ret, { Name = "Put in primary", ID = "pip" })
	return ret
end

net.Receive("action_item_stanag_1", function(len, pl)
	local itm = net.ReadEntity()
	local pl = net.ReadEntity()
	
	if itm.Owner and itm.Owner == pl then
		itm:InvokeAction("pip", pl)
	end
end)