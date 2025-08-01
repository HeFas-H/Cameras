
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = 'Camera'
ENT.Category = 'Cam System'
ENT.Spawnable = true

--[[
function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Fov" )
end
--]]