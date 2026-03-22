
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

util.AddNetworkString( 'cl_cam_menu' )
util.AddNetworkString( 'sv_cam_menu' )
util.AddNetworkString( 'sh_cam_menu' ) 
util.AddNetworkString( 'sv_cam_rot' )
util.AddNetworkString( 'cl_cam_cash' )

function ENT:Initialize()
	self:SetModel("models/cameras/cctv_camera.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		--phys:EnableMotion(false)
	end
	
	self:SetUseType(3)
	
	self:SetFrequency(0)
	self:SetIsBroke(false)
	self:SetCanBroke(GetConVar("cameras_default_breakable"):GetBool())
	
	self:SetNWInt('FOV', 90)
	
	self:SetSavedModel(self:GetModel())
	
	self:SaveReload()
	--[[--
	local owner = self:GetCreator()
    if IsValid(owner) and owner:IsPlayer() then
        -- Получаем трассировку взгляда игрока
        local trace = owner:GetEyeTrace()
        
        if trace.Hit then
            local angles = trace.HitNormal:Angle()
            self:SetAngles(angles)
			self:SetPos(trace.HitPos + trace.HitNormal * 0.5)
        end
    end
	--]]--
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Frequency")
    self:NetworkVar("Bool", 0, "IsBroke")
    self:NetworkVar("Bool", 1, "CanBroke")
    self:NetworkVar("String", 0, "SavedModel")
end

function ENT:SaveReload()
	timer.Simple( 1, function() 
		if !IsValid(self) then return end
		if self:GetModel() != self:GetSavedModel() then
			self:SetModel(self:GetSavedModel())
		end
		
		self:RemoveEnts2()
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:EnableMotion(false)
		end
		
		self:ResetSequence("0_idle")
		self:SetSequence("0_idle")
		
		Cameras.Inited = false
		
		if self:GetIsBroke() then
			self:CreateBrokeCam()
		end
		
	end )
end

function ENT:Use(activator, caller)

	if !( IsValid(caller) and caller:IsPlayer() ) then return end
	if self:GetPos():DistToSqr(caller:GetPos()) > 128^2 then return end
	
	if IsValid(caller:GetActiveWeapon()) and caller:GetActiveWeapon():GetClass() == "cameras_wrench" then
		if self:GetIsBroke() then
			self:RemoveEnts2()
			self:EmitSound("buttons/lever" .. math.random(1,8) .. ".wav")
			self:SetBodygroup(2, 0)
			self.SetIsBroke(false)
			return
		else
			net.Start('cl_cam_menu')
				net.WriteEntity(self)
				net.WriteInt(self:GetFrequency(), 12)
			net.Send(caller)
		end
	end

end

function ENT:RemoveEnts2()
	for _, prop in ipairs( constraint.FindConstraints(self, "Ballsocket") ) do
		if IsValid(prop.Ent2) and prop.Ent2:GetModel() == self:GetModel() then
			prop.Ent2:Remove()
		end
	end
end

function ENT:OnRemove()
	self:RemoveEnts2()
end

function ENT:OnTakeDamage()
  
	if self:GetIsBroke() or !self:GetCanBroke() then return end
  
	self:EmitSound("ambient/energy/spark" .. math.random(5,6) .. ".wav")
	
	self:CreateBrokeCam()

	self:SetIsBroke(true)
	
	local data = EffectData()
	data:SetOrigin( self:GetPos() )
	data:SetNormal( self:GetForward() )
	data:SetScale( 0.2 )
	util.Effect( "StunstickImpact", data )

end

function ENT:CreateBrokeCam()

	timer.Simple( 0.1, function() 

	local cam = ents.Create( "prop_physics" )
	cam:SetParent( self, 1 )
	cam:SetModel(self:GetModel())
	cam:SetAngles( self:GetAngles() )
	cam:SetPos( self:GetPos() )
	cam:Spawn()
	
	cam:SetBodygroup(1, 1)
	self:SetBodygroup(2, 1)
	
	cam:SetParent()
	cam:SetCollisionGroup(20)
	cam:SetSolid(SOLID_NONE)
	
	cam:SetPoseParameter("aim_pitch", self:GetPoseParameter("aim_pitch") ) 
	cam:SetPoseParameter("aim_yaw", self:GetPoseParameter("aim_yaw") )
	
	constraint.Ballsocket( self, cam, 0, 0, Vector( 0, 0, 0 ), 0, 0, 0 )

	end )

end

net.Receive( "sv_cam_menu", function(len, ply) 

	local self = net.ReadEntity()
	local frequency = net.ReadInt(12) or 0
	
	if !(IsValid(self)) then return end

	self:SetFrequency(frequency)

end )

net.Receive("sv_cam_rot", function(len, ply) 

    local cam = net.ReadEntity()
    local rot_x = net.ReadInt(12)
    local rot_y = net.ReadInt(12)

    if !IsValid(cam) or !IsValid(ply) then return end
    
    cam:ClearPoseParameters()
    cam:SetPoseParameter("aim_pitch", rot_y)
    cam:SetPoseParameter("aim_yaw", rot_x)
    cam:FrameAdvance()
    
    net.Start('cl_cam_cash')
        net.WriteEntity(cam)
    net.Send(ply)
end)

