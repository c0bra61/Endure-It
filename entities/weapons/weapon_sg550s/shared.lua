if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if ( CLIENT ) then

	SWEP.PrintName			= "SIG Sauer SG550 Sniper"			
	SWEP.Author				= "victormeriqui & C0BRA"

	SWEP.Slot				= 3
	SWEP.SlotPos			= 1
	SWEP.IconLetter			= "i"
	
	killicon.AddFont( "weapon_sg550s", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ) )

end

SWEP.HoldType			= "ar2"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "Endure-It"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModelFlip		= true

SWEP.ViewModel			= "models/weapons/v_snip_sg550.mdl"
SWEP.WorldModel			= "models/weapons/w_snip_sg550.mdl"

SWEP.Weight				= 12
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound			= Sound( "Weapon_Sg550.Single" )
SWEP.Primary.Recoil			= 0.75
SWEP.Primary.Damage			= 95
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 5
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Delay			= 0.1
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "smg1"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.ZoomScale = 30;
SWEP.ZoomSpeed = 0.4;
SWEP.IronMoveSpeed = 0.02;

SWEP.IronSightsPos = Vector (5.6005, -5, 1.8803)
SWEP.IronSightsAng = Vector (0, 0, 0)


function SWEP:Think()

	if self.IsZoomedIn then
		self.IronTime = self.IronTime + self.IronMoveSpeed
	else
		self.IronTime = self.IronTime - self.IronMoveSpeed
	end
	
	self.IronTime = math.Clamp(self.IronTime, 0, 1)
	
	if (self.Owner:KeyDown(IN_ATTACK2) && !self.Owner:KeyDown(IN_USE)) and not self.IsZoomedIn then
		self.SwayScale = 0.5;
		self.BobScale = 0.5;
		self.Owner:SetFOV(self.ZoomScale, self.ZoomSpeed)
		self.IsZoomedIn = true
		self:SetNWBool("zoomed", true)
	elseif not self.Owner:KeyDown(IN_ATTACK2) and self.IsZoomedIn then
		self.SwayScale = 2;
		self.BobScale = 2;
		self.Owner:SetFOV(0, self.ZoomSpeed)
		self.IsZoomedIn = false
	end	
end	

function SWEP:OnReload()
	
	if CLIENT and not (self.IronTime <= 0) then
		self.Owner:SetFOV(0, 0)
		// Yes, I know... timer.Simple can't be called recursivly
		for i = self.IronTime, 0, -0.01 do
			local ii = i
			timer.Simple(1 - ii, function() self.IronTime = ii end)
		end
		
	end
	
end

if CLIENT then
	SWEP.ScopeRT = SWEP.ScopeRT or GetRenderTarget("ei_scope_", 1024, 1024, true)

	Material("models/weapons/v_models/snip_awp/v_awp_scope"):SetTexture("$basetexture", SWEP.ScopeRT)
	Material("models/weapons/v_models/snip_awp/v_awp_scope"):SetUndefined("$envmap")
	Material("models/weapons/v_models/snip_awp/v_awp_scope"):SetUndefined("$envmapmask")
	Material("models/weapons/v_models/snip_awp/v_awp_scope"):SetShader("UnlitGeneric")
	
end

function SWEP:DrawHUD()
	local Cam = {}
	
	
	self.Zero.ClicksY = self.Zero.ClicksY or 0
	self.Zero.ClicksX = self.Zero.ClicksX or 0
	
	Cam.angles = LocalPlayer():EyeAngles() +  Angle(self.Zero.ClicksY/100 * -1, 0, 0) + Angle(0, self.Zero.ClicksX/100 * -1, 0)
    Cam.origin = LocalPlayer():GetShootPos()
    
	local sizex = 800
	local sizey = 800
	
	Cam.x = 0-- - sizex / 2;
    Cam.y = 0-- - sizey / 2;
    Cam.w = 1024;
    Cam.h = 1024;
	
	Cam.drawviewmodel = false;
	
	Cam.fov = 5;
	
	if self.IronTime == 1 then
		self.ViewModelFlip = false
	else
		self.ViewModelFlip = true
	end
	
	local oldrt = render.GetRenderTarget()
	render.SetRenderTarget(self.ScopeRT)
		local w, h = ScrW(), ScrH()
		render.SetViewPort(0, 0, 1024, 1024)
		render.RenderView(Cam)
		
		surface.SetDrawColor(0, 0, 0, 255)
		--surface.DrawLine(0, 512 + 25, 1024*2, 512+25)
		
		local cx = w / 2
		local cy = h / 2
		
		surface.DrawLine(cx, 0, cx, h)
		surface.DrawLine(0, cy, w, cy)
		
		local factor = (1/Cam.fov * 170)
		
		local width = 110
		local height = 7
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 55
		height = 23
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 38
		height = 38
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 27
		height = 56
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 22
		height = 82
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 18
		height = 113
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		width = 16
		height = 150
		surface.DrawLine(cx - width, cy + height, cx + width, cy + height)
		
		
		--surface.DrawLine(512*1.875, 0, 512 * 1.875, 1024*2)
		
		surface.SetDrawColor(0, 0, 0, 255 - math.pow(self.IronTime, 6) * 255)
		surface.DrawRect(0, 0, w, h)
		
		render.SetViewPort(0, 0, w, h)
	render.SetRenderTarget(oldrt)


end

function SWEP:AdjustMouseSensitivity()
	if self.IsZoomedIn and self.IronTime == 1 then
		local fov = 5
		return (fov / 90)
	end
	return 1
end

function SWEP:CanTakeMagazine(mag)
	return mag:GetClass() == "sent_mag_sg550s"
end
