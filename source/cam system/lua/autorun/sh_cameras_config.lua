
Cameras = Cameras or {}
Cameras.Config = Cameras.Config or {}

Cameras.Config.NoiseEnabled = false -- doesnt work with NV
Cameras.Config.DefaultBreakable = true
Cameras.Config.NVEnabled = true

Cameras.Monitors = Cameras.Monitors or {}
Cameras.Monitors["models/props/cs_office/computer.mdl"] = 0
Cameras.Monitors["models/props_lab/monitor02.mdl"] = 0
Cameras.Monitors["models/props_lab/securitybank.mdl"] = 0

Cameras.Models = Cameras.Models or {}
Cameras.Models["models/cameras/cctv_camera.mdl"] = {
    origin = function(cam)
        return cam:GetPos() + cam:GetRight() * 2 + cam:GetForward()
    end,
	pos = function(cam, trace)
		return trace.HitPos + trace.HitNormal * 16
	end,
	angle = function(trace)
		return trace.HitNormal:Angle()
	end
}

Cameras.Models["models/cameras/cctv_cam_bird.mdl"] = {
    origin = function(cam)
        return cam:GetPos() - cam:GetUp() * 3.5
    end,
	pos = function(cam, trace)
		return trace.HitPos + trace.HitNormal + trace.HitNormal:Angle():Forward() * 2
	end,
	angle = function(trace)
		return Angle(0,trace.HitNormal:Angle().y,trace.HitNormal:Angle().z)
	end
}

if SERVER then

util.AddNetworkString("cameras_command")

local function cameras_command(str, args)
	if !table.IsEmpty(args) then 
	
		local newValue = tobool(args[1])
		Cameras.Config[str] = newValue
		
		net.Start("cameras_command")
			net.WriteString(str)
			net.WriteBool(newValue)
		net.Broadcast()
		
	end
	
	print("cameras_" .. str .. " " .. tostring(Cameras.Config[str])) 
	
end

concommand.Add("cameras_NoiseEnabled", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	cameras_command("NoiseEnabled", args)
end)

concommand.Add("cameras_DefaultBreakable", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	cameras_command("DefaultBreakable", args)
end)

concommand.Add("cameras_NVEnabled", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	cameras_command("NVEnabled", args)
end)

end

if CLIENT then

net.Receive("cameras_command", function()
    Cameras.Config[net.ReadString()] = net.ReadBool()
end)

end