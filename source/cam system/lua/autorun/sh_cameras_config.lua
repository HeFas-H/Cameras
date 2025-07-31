
Cameras = Cameras or {}
Cameras.Config = Cameras.Config or {}
Cameras.Config.NoiseEnabled = false -- doesnt work with NV
Cameras.Config.DefaultBreakable = true
Cameras.Config.NVEnabled = true
Cameras.Config.Screen = true
Cameras.Config.ScreenPVS = false

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

--Not config
Cameras.Inited = false
