
if (SERVER) then

	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

end

if ( CLIENT ) then

	SWEP.DrawAmmo			= true
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 85
	SWEP.ViewModelFlip		= true
	SWEP.CSMuzzleFlashes	= true
	SWEP.SwayScale = 2; -- Causes shaking after a while
	SWEP.BobScale = 2;
	SWEP.MagBone 			= "ValveBiped.weapon_bone_Clip"
	
	local fd1 = {}
	fd1.font = "csd"
	fd1.size = ScreenScale(30)
	fd1.weight = 500
	fd1.antialias = true
	fd1.additive = true
	
	local fd2 = table.Copy(fd1)
	
	surface.CreateFont("CSKillIcons", fd1)
	surface.CreateFont("CSSelectIcons", fd2)

end

SWEP.Author			= "Counter-Strike"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

// Note: This is how it should have worked. The base weapon would set the category
// then all of the children would have inherited that.
// But a lot of SWEPS have based themselves on this base (probably not on purpose)
// So the category name is now defined in all of the child SWEPS.
//SWEP.Category			= "Counter-Strike"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.Sound			= Sound( "Weapon_AK47.Single" )
SWEP.Primary.Recoil			= 1.5
SWEP.Primary.Damage			= 40
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.02
SWEP.Primary.Delay			= 0.15

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.InventorySlots = 10
SWEP.InventoryPrimary = true

SWEP.ZoomScale = 100;
SWEP.ZoomSpeed = 0.25;
SWEP.HoldType = "ar2"
SWEP.Suppressed = false

if CLIENT then
	hook.Add("Think", "Setup VM Bones", function()
		local vm = LocalPlayer():GetViewModel()
		
		if not IsValid(vm) then return end
		
		vm.BuildBonePositions = function(vm, a, b)
			local self = LocalPlayer():GetActiveWeapon() /* Nope, active weapon... */
			if self.ModifyViewModelBones then
				self:ModifyViewModelBones(vm, a, b)
			end
		end
		
		hook.Remove("Think", "Setup VM Bones") -- We don't need to be called anymore
	end)
end

function SWEP:Initialize()	
	self:SetWeaponHoldType( self.HoldType )
	self.IronTime = 0;
	
	self.Zero = { ClicksY = 0, ClicksX = 0 }
	

end

function SWEP:Deploy()
	if self.PostWorldModel then
		self.WorldModel = self.PostWorldModel
		--self:SetModel(self.PostWorldModel)
	end
	
	if self.Suppressed then
		self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
	else
		self:SendWeaponAnim(ACT_VM_DRAW)
	end
	
	if self:GetMagazine() == nil or self:GetMagazine().Rounds == 0 then
		if self.Suppressed then
			self.Weapon:SendWeaponAnim(ACT_VM_DRYFIRE_SILENCED)
		else
			self.Weapon:SendWeaponAnim(ACT_VM_DRYFIRE)
		end
	end
	
	self:SetNextPrimaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
	self:SetNextSecondaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
	
end

function SWEP:CanTakeMagazine(mag)
	return true
end

function SWEP:SetMagazine(mag)
	if mag == nil then
		if self.Magazine and self.Magazine.Inside and self.Magazine.Inside then
			self.Magazine.Inside = nil
		end
		self.Magazine = nil
		self:SetClip1(0)
		return
	end
		
	if not self:CanTakeMagazine(mag) then return false end
	
	self:SetMagazine(nil)
	self.Magazine = mag
	
	self:Reload(1)
	
	return true
end

function SWEP:GetMagazine()
	return self.Magazine
end

SWEP.NextQuickReload = 0
SWEP.StartReload = nil -- Used so you can hold R
function SWEP:Reload(invoker)
	if self.Reloading or self.CanPrimaryAttack_Reload then return end
	print("RELOADING")
	if invoker == nil then
		--if true then return end
		if CLIENT and CurTime() > self.NextQuickReload then
			
			if self.StartReload == nil then
				self.StartReload = CurTime() + 1
				timer.Simple(0.1, function()
					if not self.Reload then return end
					self:Reload() end
				)
				return
			end
			
			if not self.Owner:KeyReleased(IN_RELOAD) then --self.Owner:KeyDown(IN_RELOAD) then
				if self.Owner:KeyDown(IN_RELOAD) == true then -- erm, you're wrong, game
					timer.Simple(0.1, function()
						if not self.Reload then return end
						self:Reload() end
					)
					return
				end
			end
			
			local manual = self.StartReload < CurTime()			
			self.StartReload = nil
			
			local bestmag = nil
			for k, v in pairs((self.Owner:GetInventory().ToolBelt or {})) do
				if v.IsMagazine and self:CanTakeMagazine(v) then
					if self.Magazine and self.Magazine == v then continue end -- So we don't drop and put in gun at same time...
					
					if not bestmag or (v.Rounds > bestmag.Rounds) then
						bestmag = v
					end
				end
			end
			
			if bestmag != nil then
				if self.Magazine and not manual then
					self.Owner:InvDrop(self.Magazine)
				elseif self.Magazine then
					self.Magazine:InvokeAction("top") -- So when we put the new one in, the old one is garruenteed to be taken out...
				end
				
				bestmag:InvokeAction("pip")
				self.NextQuickReload = CurTime() + 1 -- will also be set a bit later, when we start to reload
			end
		end
		return
	end
	/*
	if invoker == 1 then
		self.Weapon:SendWeaponAnim(ACT_VM_DEPLOY)
		timer.Simple(0.5, function() self:Reload(2) end)
	end
	*/
	if not self.Magazine then
		return
	end
	
	--self.Weapon:DefaultReload( ACT_VM_RELOAD )
	-- This isn't fired if they havn't shot
	--self.Owner:GetViewModel():ResetSequenceInfo()
	--ACT_VM_DRAW
	if self.Suppressed then
		self.Weapon:SendWeaponAnim(ACT_VM_RELOAD_SILENCED)
	else
		self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
	end
	self.Owner:SetAnimation(PLAYER_RELOAD)
	
	self.ZoomedIn = false
	self.IronTime = 0
	self.Owner:SetFOV(0, 0)
	local oldowner = self.Owner
	self.Reloading = true
	
	self.NextQuickReload = self.Owner:GetViewModel():SequenceDuration() + CurTime()
	
	timer.Simple(self.Owner:GetViewModel():SequenceDuration(), function()
		self.Reloading = false
		if not self.Owner then return end
		if self.Owner != oldowner then return end
		if self.Owner:GetActiveWeapon() != self then return end
		
		if self.Owner and IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
			--local vm = self.Owner:GetViewModel()
			--vm:ResetSequence(vm:LookupSequence("idle") or 0)
			--vm:SetPlaybackRate(1)
			if self.Suppressed then
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE_SILENCED)
			else
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
			end
		end
		
		if self:GetMagazine() == nil or self:GetMagazine().Rounds == 0 then
			if self.Suppressed then
				self.Weapon:SendWeaponAnim(ACT_VM_DRYFIRE_SILENCED)
			else
				self.Weapon:SendWeaponAnim(ACT_VM_DRYFIRE)
			end
		end
		
		if not self.Magazine then
			self:SetClip1(0)
		else
			self:SetClip1(self.Magazine.Rounds)
		end
	end)
	
	if self.OnReload then self:OnReload() end
end


function SWEP:PrimaryAttack()
	
	if self.Sprinting or self.SprintTime != 0 then return end
	
	--self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	self.CanPrimaryAttack_Reload = true
	if ( !self:CanPrimaryAttack() ) then
		self.CanPrimaryAttack_Reload = false
		return
	end
	self.CanPrimaryAttack_Reload = false
	
	if self.Magazine and IsValid(self.Magazine) then
		if SERVER then
			self.Magazine:StateChanged(SYNCSTATE_OWNER, self.Primary.Delay + 0.25)
		end
	else
		self:SetClip1(0)
		return
	end
	
	self:EmitSound( self.Primary.Sound )
	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone )
	self:TakePrimaryAmmo( 1 )
	
	if ( self.Owner:IsNPC() ) then return end
	
	--self.Owner:ViewPunch( Angle(math.random(-self.Primary.Recoil, -1), math.random(-self.Primary.Recoil, 1), math.random(-1, 1)) )
	self.Owner:ViewPunch( Angle(0.01, 0, 0) )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if (CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

function SWEP:Special()
end

function SWEP:SecondaryAttack()
	if self.Owner:KeyDown(IN_USE) and IsFirstTimePredicted() then
		self:Special()
	end
end

function SWEP:CSShootBullet( dmg, recoil, numbul, cone )
	if self.Magazine == nil or self.Magazine.Rounds == nil or self.Magazine.Rounds == 0 then return end
	
	numbul 	= numbul 	or 1
	
	if numbul > 1 then
		numbul = numbul * 5
	end
	
	cone 	= cone 		or 0.01
	cone = cone * 0.5
	
	if CLIENT and IsFirstTimePredicted() then
		for i = 1, numbul do
			local bul = {}
			local lp = LocalPlayer()
			bul.StartPos = lp:GetShootPos()
			bul.Direction = lp:GetAimVector()
			
			local rand = VectorRand() * cone * 0.5 * 1.25 -- 1unit * 1.25 = 1 inch

			local distance = Yards(100)
			
			local spread = Vector(Inches(cone), distance, 0):GetNormal():Angle() - Angle(0, 90, 0)
			local ang = math.abs(spread.y)
			
			spread = Angle(math.Rand(-ang, ang), math.Rand(-ang, ang), math.Rand(-ang, ang))
			
			//bul.Direction = bul.Direction:GetNormal() //+ conevec
			bul.Direction = (bul.Direction:Angle() + spread):Forward()

			bul.TraceIgnore = {LocalPlayer()}
			bul.RandSeed = math.Rand(-100000, 100000)
			
			bul.Bullet = GetBullet(self.Magazine.Bullet)
						
			ShootBullet(bul, function(bullet)
				bullet.Velocity = bullet.Velocity + lp:GetVelocity() + lp:GetAimVector() * math.random(-100, 100)
			end)
		end
	end
	
	if (CLIENT and IsFirstTimePredicted()) or SERVER then
		self.Magazine.Rounds = self.Magazine.Rounds - 1
	end
	
	if self.DontPrimaryAttackAnim == nil then
		local anim
		if self.Suppressed then
			anim = ACT_VM_DRYFIRE_SILENCED
			if self.Magazine.Rounds > 0 then
				anim = ACT_VM_PRIMARYATTACK_SILENCED
			end
		else
			anim = ACT_VM_DRYFIRE  
			if self.Magazine.Rounds > 0 then
				anim = ACT_VM_PRIMARYATTACK
			end
		end
		self.Weapon:SendWeaponAnim( anim ) 		// View model animation
	end
	if not self.Suppressed then
		self.Owner:MuzzleFlash()								// Crappy muzzle light
	end
	
	if self.DontPrimaryAttackAnim == nil then
		self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
	end
	
	if ( self.Owner:IsNPC() ) then return end
	
	// CUSTOM RECOIL !
	if CLIENT && IsFirstTimePredicted() then
	
		local eyeang = self.Owner:EyeAngles()
		
		eyeang.p = eyeang.p - self.Primary.Recoil/10
		eyeang.y = eyeang.y + (self.Primary.Recoil/10) * math.Rand(-1, 1)
		
		self.Owner:SetEyeAngles(eyeang)
	
	end
	//wtf is this shitl

end

function SWEP:Think()
	if self.IsZoomedIn then
		self.IronTime = self.IronTime + self.IronMoveSpeed
	else
		self.IronTime = self.IronTime - self.IronMoveSpeed
	end
	
	self.IronTime = math.Clamp(self.IronTime, 0, 1)
	
	if (self.Owner:KeyDown(IN_ATTACK2) && !self.Owner:KeyDown(IN_USE)) and not self.IsZoomedIn then
		self.SwayScale = 1;
		self.BobScale = 1;
		self.Owner:SetFOV(self.ZoomScale, self.ZoomSpeed)
		self.IsZoomedIn = true
	elseif not self.Owner:KeyDown(IN_ATTACK2) and self.IsZoomedIn then
		self.SwayScale = 2;
		self.BobScale = 2;
		self.Owner:SetFOV(0, self.ZoomSpeed)
		self.IsZoomedIn = false
	end	
	
	if self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length() > self.Owner:GetRunSpeed() * 0.5 then
		self.Sprinting = true
	else
		self.Sprinting = false
	end
end	

SWEP.SprintTime = 0
function SWEP:GetViewModelPosition( pos, ang )
	
	local grad = Lerp( self.IronTime, 0, 1)
	
	local IronPos = self.IronSightsPos;
	local IronAng = self.IronSightsAng;
	local OverPos = self.OverridePos;
	local OverAng = self.OverrideAng;
	
	if(OverPos || OverAng) then	
		
		ang:RotateAroundAxis(ang:Right(), OverAng.x)
		ang:RotateAroundAxis(ang:Up(), OverAng.y)
		ang:RotateAroundAxis(ang:Forward(), OverAng.z)	
		
		pos = pos + OverPos.x * ang:Right();
		pos = pos + OverPos.y * ang:Up();
		pos = pos + OverPos.z * ang:Forward();

		
	end
	
	ang:RotateAroundAxis(ang:Right(), IronAng.x)
	ang:RotateAroundAxis(ang:Up(), IronAng.y)
	ang:RotateAroundAxis(ang:Forward(), IronAng.z)

	local Right = ang:Right()
	local Up = ang:Up()
	local Forward = ang:Forward()
	
	pos = pos + IronPos.x * Right * grad
	pos = pos + IronPos.y * Forward * grad
	pos = pos + IronPos.z * Up * grad
	
	if self.Sprinting or self.SprintTime != 0 then
		local mod = 5
		if not self.Sprinting then
			mod = -5
		end
		
		self.SprintTime = self.SprintTime + mod * FrameTime()
		self.SprintTime = math.Clamp(self.SprintTime, 0, 1)
				
		if self.SprintTime >= 1 then self.SprintTime = 1 end
		
		return pos, ang - Angle(20, -20, 0) * self.SprintTime * -1
	end
	
	return pos, ang

end


function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	
	--maybe garry was high when he made this
	// try to fool them into thinking they're playing a Tony Hawks game
	//draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-14, 14), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )
	//draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-9, 9), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )
	
end

function SWEP:DrawHUD()

	// No crosshair when ironsights is on
	if ( self.Weapon:GetNetworkedBool( "Ironsights" ) ) then return end

	local x, y

	// If we're drawing the local player, draw the crosshair where they're aiming,
	// instead of in the center of the screen.
	if ( self.Owner == LocalPlayer() && self.Owner:ShouldDrawLocalPlayer() ) then

		local tr = util.GetPlayerTrace( self.Owner )
		tr.mask = bit.bor( CONTENTS_SOLID,CONTENTS_MOVEABLE,CONTENTS_MONSTER,CONTENTS_WINDOW,CONTENTS_DEBRIS,CONTENTS_GRATE,CONTENTS_AUX )
		local trace = util.TraceLine( tr )
		
		local coords = trace.HitPos:ToScreen()
		x, y = coords.x, coords.y

	else
		x, y = ScrW() / 2.0, ScrH() / 2.0
	end
	
	local scale = 0.1 --* self.Primary.Cone
	
	// Scale the size of the crosshair according to how long ago we fired our weapon
	local LastShootTime = self.Weapon:GetNetworkedFloat( "LastShootTime", 0 )
	scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0.0, 1.0 ))
	
	surface.SetDrawColor( 0, 255, 0, 255 )
	
	// Draw an awesome crosshair
	local gap = 40 * scale
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )

end

if CLIENT then

	local function ZeroUp()
		if not LocalPlayer():GetActiveWeapon().Zero then
			LocalPlayer():GetActiveWeapon().Zero = { ClicksY = 0, ClicksX = 0 }
		end
		LocalPlayer():GetActiveWeapon().Zero.ClicksY = LocalPlayer():GetActiveWeapon().Zero.ClicksY + 1
	end
	
	local function ZeroDown()
		if not LocalPlayer():GetActiveWeapon().Zero then
			LocalPlayer():GetActiveWeapon().Zero = { ClicksY = 0, ClicksX = 0 }
		end
		LocalPlayer():GetActiveWeapon().Zero.ClicksY = LocalPlayer():GetActiveWeapon().Zero.ClicksY - 1
	end
	
	local function ZeroLeft()
		if not LocalPlayer():GetActiveWeapon().Zero then
			LocalPlayer():GetActiveWeapon().Zero = { ClicksY = 0, ClicksX = 0 }
		end
		LocalPlayer():GetActiveWeapon().Zero.ClicksX = LocalPlayer():GetActiveWeapon().Zero.ClicksX - 1
	end
	
	local function ZeroRight()
		if not LocalPlayer():GetActiveWeapon().Zero then
			LocalPlayer():GetActiveWeapon().Zero = { ClicksY = 0, ClicksX = 0 }
		end
		LocalPlayer():GetActiveWeapon().Zero.ClicksX = LocalPlayer():GetActiveWeapon().Zero.ClicksX + 1
	end
	
	concommand.Add("zero_up", ZeroUp)
	concommand.Add("zero_down", ZeroDown)
	concommand.Add("zero_left", ZeroLeft)
	concommand.Add("zero_right", ZeroRight)
end

function SWEP:AdjustMouseSensitivity()
	local fov = self.Owner:GetFOV()
	return (fov / 90)
end

function SWEP:ModifyViewModelBones(vm, num, numphys)
	if self.MagBone == nil then return end
	if self.Magazine != nil then return end
	
	local bone = vm:LookupBone(self.MagBone)
	if not bone then
		print("MagBone for " .. self:GetClass() .. "(" .. self.MagBone .. ") doesn't exist!")
		if self.MagBone == "ValveBiped.weapon_bone_Clip" then
			local class = self:GetClass()
			class = string.Replace(class, "weapon_", "")
			class = string.Replace(class, "_sd", "") -- remove the _sd too
			
			self.MagBone = "v_weapon." .. class .. "_Clip"
			print("Attempting to get from class name: " .. self.MagBone)
		end
		return
	end
	
	vm:SetBonePosition(bone, vm:GetAngles(), vm:GetPos() + vm:GetAngles():Up() * 1000 /* you'll never see me */)
end