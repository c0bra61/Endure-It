if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if ( CLIENT ) then

	SWEP.PrintName			= "FN Five-Seven"			
	SWEP.Author				= "victormeriqui & C0BRA"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 5
	SWEP.IconLetter			= "u"
	SWEP.MagBone 			= "ValveBiped.weapon_bone_Clip"
	
	killicon.AddFont( "pistol_fiveseven", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ) )
	
end

SWEP.HoldType			= "pistol"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "Endure-It"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_pist_fiveseven.mdl"
SWEP.WorldModel			= "models/weapons/w_pist_fiveseven.mdl"

SWEP.Weight				= 2
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound			= Sound( "Weapon_FiveSeven.Single" )
SWEP.Primary.Recoil			= 1.2
SWEP.Primary.Damage			= 18
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.02
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Delay			= 0.05
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "pistol"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.ZoomScale = 75;
SWEP.ZoomSpeed = 0.2;
SWEP.IronMoveSpeed = 0.05;

SWEP.IronSightsPos = Vector (2.0013, -0.5384, 1.9127)
SWEP.IronSightsAng = Vector (0, 0, 0)

function SWEP:CanTakeMagazine(mag)
	return mag:GetClass():StartWith("sent_mag_9mm")
end