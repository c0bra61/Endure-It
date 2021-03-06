-- Sound
resource.AddFile("sound/arma2/bullet_by1.wav")
resource.AddFile("sound/arma2/bullet_by2.wav")
resource.AddFile("sound/arma2/bullet_by3.wav")
resource.AddFile("sound/arma2/bullet_by4.wav")
resource.AddFile("sound/arma2/bullet_by5.wav")
resource.AddFile("sound/arma2/bullet_by6.wav")
resource.AddFile("sound/arma2/sscrack1.wav")
resource.AddFile("sound/arma2/sscrack2.wav")

-- Models & textures
resource.AddFile("models/wystan/stanag_magazine.mdl")
resource.AddFile("models/wystan/weapons/ak47magazine.mdl")
resource.AddFile("models/wystan/weapons/m9magazine.mdl")
resource.AddFile("models/wystan/weapons/m249magazine.mdl")
resource.AddFile("models/wystan/weapons/sr-25magazine.mdl")
resource.AddFile("models/wystan/weapons/trg-42magazine.mdl")
resource.AddFile("models/kuyler/weapons/glock 17 mag.mdl")

resource.AddFile("materials/wystan/556.vmf")
resource.AddFile("materials/wystan/556_normal.vtf")
resource.AddFile("materials/wystan/weapons/AK47/47_mag.vmt")
resource.AddFile("materials/wystan/weapons/AK47/Magazine.vmt")
resource.AddFile("materials/wystan/weapons/M9/frame.vmt")
resource.AddFile("materials/wystan/weapons/M9/frame_normal.vtf")
resource.AddFile("materials/wystan/weapons/M249/boxmag.vmt")
resource.AddFile("materials/wystan/weapons/M249/bullet.vmt")
resource.AddFile("materials/wystan/weapons/SR-25/casings.vmt")
resource.AddFile("materials/wystan/weapons/SR-25/default_normal.vtf")
resource.AddFile("materials/wystan/weapons/SR-25/sr25.vmt")
resource.AddFile("materials/wystan/weapons/TRG-42/Recmag.vmt")
resource.AddFile("materials/wystan/weapons/TRG-42/Recmag_Normal.vtf")
resource.AddFile("materials/models/kuyler/weapons/Glock 17.vmt")

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_weapon_drawing.lua" )
AddCSLuaFile( "cl_legs.lua" )

include( 'shared.lua' )
include("sv_inventory.lua")

// Serverside only stuff goes here

function SpawnFlashlight(pl)
	if pl.flashlight then
		if IsValid(pl.flashlight) then pl.flashlight:Remove() end
		pl.flashlight = nil
	end
	
	pl.flashlight = ents.Create( "env_projectedtexture" )
		pl:SetNWEntity("Flashlight", pl.flashlight)
		
		--pl.flashlight:SetParent( pl )
		
		-- The local positions are the offsets from parent..
		pl.flashlight:SetLocalPos( Vector( 0, 0, 64 ) )
		pl.flashlight:SetLocalAngles( Angle(0,0,0) )
		
		-- Looks like only one flashlight can have shadows enabled!
		pl.flashlight:SetKeyValue( "enableshadows", 1 )
		pl.flashlight:SetKeyValue( "farz", 1024 )
		pl.flashlight:SetKeyValue( "nearz", 16 )
		pl.flashlight:SetKeyValue( "lightfov", 45 )
		
		local c = Color(255,255,255,255)
		local b = 1
		pl.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )
		
	pl.flashlight:Spawn()
	
	pl.flashlight:Input( "SpotlightTexture", NULL, NULL, "effects/flashlight001" )
end

/*---------------------------------------------------------
   Name: gamemode:PlayerLoadout( )
   Desc: Give the player the default spawning weapons/ammo
---------------------------------------------------------*/
function GM:PlayerLoadout( pl )
	pl:SetWalkSpeed(7 * 17.6 * 0.75) -- 8mph
	pl:SetRunSpeed(20 * 17.6 * 0.75) -- 20mph
	pl:Give("empty_weapon")
	
	stanima:PlayerSpawn(pl)
	
	if pl.flashlight then
		if IsValid(pl.flashlight) then pl.flashlight:Remove() end
		pl.flashlight = nil
	end
end

function GM:PlayerSwitchFlashlight(pl, on)
	if pl.flashlight then
		if IsValid(pl.flashlight) then pl.flashlight:Remove() end
		pl.flashlight = nil
	else
		SpawnFlashlight(pl)
	end
	
	return false
end

function GM:EntityTakeDamage(ent, inflictor, attacker, amount, dmginf)
	if ent:IsPlayer() then
		
		if dmginf:GetDamageType() == DMG_BULLET 
				or dmginf:GetDamageType() == DMG_BLAST
				or dmginf:GetDamageType() == DMG_BUCKSHOT
				or math.random(1, 50) == 25 then
			ent:Bleed(dmginf)
		end
	end
end

function GM:ScalePlayerDamage(pl, hitbox, dmginf)
	
	if ( hitgroup == HITGROUP_HEAD ) then
		dmginfo:ScaleDamage( 2 )
	end

	// Less damage if we're shot in the arms or legs
	if hitbox == HITGROUP_RIGHTARM then
		local inv = pl:GetInventory()
		local prim = inv.Primary
		local sec = inv.Secondary
		
		if IsValid(pl:GetActiveWeapon()) then		
			local acw = pl:GetActiveWeapon():GetClass()
			
			if prim and prim.Weapon_Class and acw == prim.Weapon_Class then
				-- Drop gun
				pl:InvDrop(prim)
			end
			
			if sec and sec.Weapon_Class and acw == sec.Weapon_Class then
				-- Drop gun
				pl:InvDrop(sec)
			end
		end
	end
	
	if hitbox == HITGROUP_HEAD then
		dmginf:SetDamage(1000)
	end
	
	
	if pl:IsPlayer() then
		
		if 		   dmginf:GetDamageType() == DMG_BULLET 
				or dmginf:GetDamageType() == DMG_BLAST
				or dmginf:GetDamageType() == DMG_BUCKSHOT
				or math.random(1, 50) == 25 then
				
			pl:Bleed(dmginf)
		end
	end
	
	dmginf:ScaleDamage(0.5)
end

local ZOMBIE_HEADSHOT_TIME = 0
local ZOMBIE_HEADSHOT_INFO = nil
function GM:ScaleNPCDamage(npc, hitbox, dmginf)
	if hitbox == HITGROUP_HEAD then
		dmginf:SetDamage(10000)
		
		if npc:GetClass() == "npc_zombie" then
			ZOMBIE_HEADSHOT_TIME = CurTime()
			ZOMBIE_HEADSHOT_INFO = dmginf
		end
	end
end

function GM:OnEntityCreated(ent)
	if ent:GetClass() == "npc_headcrab" and ZOMBIE_HEADSHOT_TIME == CurTime() then -- Please, fuck off
		ent:TakeDamageInfo(ZOMBIE_HEADSHOT_INFO)
	end
end