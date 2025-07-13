
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

util.AddNetworkString( 'cl_cam_menu' )
util.AddNetworkString( 'sv_cam_menu' )
util.AddNetworkString( 'sh_cam_menu' ) 
util.AddNetworkString( 'sv_cam_rot' )
util.AddNetworkString( 'cl_cam_cash' )
util.AddNetworkString( 'cl_cam_broke' )

function ENT:Initialize()
	self:SetModel("models/cameras/cctv_camera.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:EnableMotion(false)
	end
	self.Frequency = 0
	self:SetUseType(3)
	
	self.CanBroke = Cameras.Config.DefaultBreakable
	self.Broke = false
	
	self.SavedModel = self:GetModel()
	timer.Simple( 1, function() 
		if !IsValid(self) then return end
		self:SetModel(self.SavedModel)
	end )
	
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
end

function ENT:Use(activator, caller)

	if !( IsValid(caller) and caller:IsPlayer() ) then return end
	if self:GetPos():DistToSqr(caller:GetPos()) > 128^2 then return end
	
	if caller:GetActiveWeapon():GetClass() == "cameras_wrench" then
		if self.Broke then
			self:RemoveEnts2()
			self:EmitSound("buttons/lever" .. math.random(1,8) .. ".wav")
			self:SetBodygroup(2, 0)
			self.Broke = false
			net.Start("cl_cam_broke") 
				net.WriteEntity(self)
				net.WriteBool(self.Broke)
			net.Broadcast()
			return
		else
			net.Start('cl_cam_menu')
				net.WriteEntity(self)
				net.WriteInt(self.Frequency, 12)
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
  
	if self.Broke or !self.CanBroke then return end
  
	self:EmitSound("ambient/energy/spark" .. math.random(5,6) .. ".wav")
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

	self.Broke = true
	
	local data = EffectData()
	data:SetOrigin( self:GetPos() )
	data:SetNormal( self:GetForward() )
	data:SetScale( 0.2 )
	util.Effect( "StunstickImpact", data )
	
	net.Start("cl_cam_broke")
		net.WriteEntity(self)
		net.WriteBool(self.Broke)
	net.Broadcast()

end

net.Receive( "sv_cam_menu", function(len, ply) 

	local self = net.ReadEntity()
	local frequency = net.ReadInt(12) or 0
	
	if !(IsValid(self)) then return end

	self.Frequency = frequency

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

