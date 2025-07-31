
Cameras = Cameras or {}
Cameras.Config = Cameras.Config or {}

Cameras.Config.NoiseEnabled = false -- doesnt work with NV
Cameras.Config.DefaultBreakable = true
Cameras.Config.NVEnabled = true
Cameras.Config.Screen = true

Cameras.NV = {
	[ "$pp_colour_addr" ] = 0.0,
	[ "$pp_colour_addg" ] = 0.3,
	[ "$pp_colour_addb" ] = 0.0,
	[ "$pp_colour_brightness" ] = -0.15,
	[ "$pp_colour_contrast" ] = 1,2,
	[ "$pp_colour_colour" ] = 0,
	[ "$pp_colour_mulr" ] = 0.1,
	[ "$pp_colour_mulg" ] = 0.1,
	[ "$pp_colour_mulb" ] = 0.1
}

Cameras.Monitors = Cameras.Monitors or {}
Cameras.Monitors["models/props/cs_office/computer.mdl"] = {
	pos = {
		x = -4,
		y = -3,
		w = 27,
		h = 20,
		Forward = 0.3,
		Up = 22.5,
		Right = 8.3
	},
	ang = {
		Right = -90,
		Up = 90,
		Forward = 0,
	}
}

Cameras.Monitors["models/props_lab/monitor02.mdl"] = {
	pos = {
		x = -1,
		y = 0,
		w = 22,
		h = 18,
		Forward = 10.1,
		Up = 22.2,
		Right = 8.3
	},
	ang = {
		Right = -82,
		Up = 90,
		Forward = 0,
	}
}

Cameras.Monitors["models/props_lab/securitybank.mdl"] = {
	pos = {
		x = -6,
		y = -7,
		w = 37,
		h = 24,
		Forward = 12,
		Up = 80.2,
		Right = 0
	},
	ang = {
		Right = -90,
		Up = 90,
		Forward = 0,
	}
}

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

concommand.Add("cameras_Screen", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	cameras_command("Screen", args)
end)

end

if CLIENT then

net.Receive("cameras_command", function()
    Cameras.Config[net.ReadString()] = net.ReadBool()
end)

    language.Add("spawnmenu.utilities.cameras", "Cameras")


end

hook.Add( "AddToolMenuTabs", "myHookClass", function()
	spawnmenu.AddToolCategory( "Utilities", "Cameras", "#spawnmenu.utilities.cameras" )
	spawnmenu.AddToolMenuOption( "Utilities", "Cameras", "settings", "Settings", "", "", function( panel )
	
	panel:SetName("Settings")
    panel:SetPadding(10)

	local noiseCheck = panel:CheckBox("Noise")
    noiseCheck:SetChecked(Cameras.Config.NoiseEnabled)
    noiseCheck.OnChange = function(_, value) 
		RunConsoleCommand("cameras_NoiseEnabled", tostring(value)) 
		--noiseCheck:SetChecked(Cameras.Config.NoiseEnabled) 
	end
	panel:ControlHelp("Whether cameras are breakable by default")

    local breakCheck = panel:CheckBox("Breakable")
    breakCheck:SetChecked(Cameras.Config.DefaultBreakable)
    breakCheck.OnChange = function(_, value) 
		RunConsoleCommand("cameras_DefaultBreakable", tostring(value)) 
		--breakCheck:SetChecked(Cameras.Config.DefaultBreakable) 
	end
	panel:ControlHelp("Enable night vision capability")

    local nvCheck = panel:CheckBox("Nightvision")
    nvCheck:SetChecked(Cameras.Config.NVEnabled)
    nvCheck.OnChange = function(_, value) 
		RunConsoleCommand("cameras_NVEnabled", tostring(value)) 
		--nvCheck:SetChecked(Cameras.Config.NVEnabled) 
	end
	panel:ControlHelp("Adds visual noise effect to cameras")

	local scCheck = panel:CheckBox("Screen")
    scCheck:SetChecked(Cameras.Config.Screen)
    scCheck.OnChange = function(_, value) 
		RunConsoleCommand("cameras_Screen", tostring(value)) 
		--scCheck:SetChecked(Cameras.Config.Screen) 
	end
	panel:ControlHelp("Adds screens to monitors")
	
	end )
end )
