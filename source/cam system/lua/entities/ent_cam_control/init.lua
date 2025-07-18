--init ent_cam_control
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

util.AddNetworkString( 'cl_control_menu' )
util.AddNetworkString( 'sv_control_menu' )
util.AddNetworkString( 'sv_cam_view' )

function ENT:Initialize()
	self:SetModel("models/props_lab/monitor02.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	
	self.Frequency = 0
	self:SetUseType(3)
	
	self.SavedModel = self:GetModel()
	timer.Simple( 1, function() 
		if !IsValid(self) then return end
		self:SetModel(self.SavedModel)
	end )

end  

net.Receive( "sv_cam_view", function(len, ply) 

	local cam = net.ReadEntity()
	local ent = net.ReadEntity()
	
	if !IsValid(cam) or !IsValid(ply) then return end
	
	if ply == cam then
		ply:SetFOV(0,0,ent)
	end
	ply:SetViewEntity(cam)

end )

function ENT:Use(activator, caller)
	
	if !( IsValid(caller) and caller:IsPlayer() ) then return end
	if self:GetPos():DistToSqr(caller:GetPos()) > 128^2 then return end

	if caller:GetActiveWeapon():GetClass() == "cameras_wrench" then
		net.Start('cl_cam_menu')
			net.WriteEntity(self)
			net.WriteInt(self.Frequency, 12)
		net.Send(caller)
	else
		local cams = {}
		local j = 1
		net.Start('cl_control_menu')
			net.WriteEntity(self)
			
			for _, i in ipairs( ents.FindByClass("ent_cam") ) do
				if i.Frequency != self.Frequency or i.Broke then continue end
				cams[j] = i
				j = j + 1
			end
			net.WriteUInt(j, 9)
			for _, cam in ipairs(cams) do
				net.WriteEntity(cam)
			end
			
		net.Send(caller)
		caller:SetFOV(1,0,self)
	end

end
