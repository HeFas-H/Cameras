TOOL.Category = "Cameras"
TOOL.Name = "Cameras Placer"
TOOL.Command = nil
TOOL.ConfigName = "" 

TOOL.ClientConVar = {
    ["model"] = "",
    ["breakable"] = "1",
    ["frequency"] = "0",
}

if CLIENT then
    language.Add("tool.cameras_hefas.name", "Cameras Placer")
    language.Add("tool.cameras_hefas.desc", "Spawns cameras.")
    language.Add("tool.cameras_hefas.0", "Left click: Place camera.")
end

function TOOL.BuildCPanel(panel)
    panel:SetName("Camera Placer")
    panel:SetPadding(10)

    local combo = panel:ComboBox("Camera Model", "cameras_hefas_model")
    for model, _ in pairs(Cameras.Models) do
        combo:AddChoice(model)
    end
	combo.OnSelect = function(self, index, value, data)
        GetConVar("cameras_hefas_model"):SetString(value)
    end
	
	panel:NumSlider("Frequency", "cameras_hefas_frequency", 0, 999, 0)
    panel:ControlHelp("Frequency")

    panel:CheckBox("Breakable", "cameras_hefas_breakable")
    panel:ControlHelp("Can be break")
end

function TOOL:LeftClick(trace)
	if SERVER then
    if not trace.HitPos or trace.Entity:IsPlayer() then return false end

    local ply = self:GetOwner()
	if !ply:IsAdmin() then return false end
    local model = self:GetClientInfo("model")
    local breakable = self:GetClientNumber("breakable")
    local frequency = self:GetClientNumber("frequency")
    
    if not Cameras.Models[model] then return false end
    
    local cam = ents.Create("ent_cam")
    if not IsValid(cam) then return false end
	
	local angles = trace.HitNormal:Angle()
	cam:SetAngles(Cameras.Models[model].angle(trace))
	cam:SetPos(Cameras.Models[model].pos(cam,trace))
	cam:Spawn()
	cam:SetModel(model)
	cam.SavedModel = model

	cam.Frequency = frequency
	cam.CanBroke = tobool(breakable)
    
    cam:SetCollisionGroup(COLLISION_GROUP_WORLD)
    cam:GetPhysicsObject():EnableMotion(false)
    cam:SetCreator(ply)
    
    undo.Create("Camera")
        undo.AddEntity(cam)
        undo.SetPlayer(ply)
    undo.Finish("Camera ("..model..")")

	end
	return true
end
