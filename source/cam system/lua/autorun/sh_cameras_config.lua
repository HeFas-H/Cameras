
Cameras = Cameras or {}
CreateConVar("cameras_noise", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Noise.")
CreateConVar("cameras_default_breakable", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "DefaultBreakable.")
CreateConVar("cameras_default_nv", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Nightvision.")
CreateConVar("cameras_screen", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Screens for monitors.")
CreateConVar("cameras_screen_pvs", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "PVS for cameras.")
CreateClientConVar("cameras_screen_size", "128", {FCVAR_ARCHIVE, FCVAR_LUA_CLIENT}, "Screens size.")


Cameras.NV = {
	[ "$pp_colour_addr" ] = 0.0,
	[ "$pp_colour_addg" ] = 0.25,
	[ "$pp_colour_addb" ] = 0.0,
	[ "$pp_colour_brightness" ] = -0.05,
	[ "$pp_colour_contrast" ] = 1.2,
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

--Not config
Cameras.Inited = false
