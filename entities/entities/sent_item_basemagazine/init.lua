AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:SpawnFunction(ply, tr)
	if (!tr.Hit) then 
		return
	end
	local spawn = tr.HitPos + Vector(0, 0, 15)
	local ent = ents.Create("sent_item_base")
	ent:SetPos(spawn)
	ent:Spawn()
	return ent
end

function ENT:PositionDrop(pl)
	local av = pl:GetAimVector():Angle()
	self:SetAngles(Angle(av.p, av.y + math.random(-30, 30), math.random(-30, 30)))
	local beloweye = av:Up() * -10
	self:SetPos(pl:GetShootPos() - self:OBBCenter() + beloweye)
end

function ENT:Initialize()
	local ent = self.Entity
	ent:SetModel(self.Model)
	ent:PhysicsInit(SOLID_VPHYSICS)
	ent:SetSolid(SOLID_VPHYSICS)
	ent:SetMoveType(MOVETYPE_VPHYSICS) 
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetAngles(Angle(0, math.random(0, 360), 0))
	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
end

function ENT:OnTakeDamage(dmginfo)
	self.Entity:TakePhysicsDamage(dmginfo)
end

function ENT:RestoreState(state)
	self.Rounds = state.Rounds
	self:SendState()
end

function ENT:GetState()
	return {Rounds = self.Rounds}
end
