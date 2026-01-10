
monitorsToRender = {}

if CLIENT then

    language.Add("spawnmenu.utilities.cameras", "Cameras")

end

hook.Add( "AddToolMenuTabs", "Cameras_ToolMenuSettings", function()
	spawnmenu.AddToolCategory( "Utilities", "Cameras", "#spawnmenu.utilities.cameras" )
	spawnmenu.AddToolMenuOption( "Utilities", "Cameras", "settings", "Settings", "", "", function( panel )
	
	panel:SetName("Settings")
    panel:SetPadding(10)
	panel:Help("Server:")

	local noiseCheck = panel:CheckBox("Noise", "cameras_noise")
	panel:ControlHelp("Adds visual noise effect to cameras")

    local breakCheck = panel:CheckBox("Breakable", "cameras_default_breakable")
	panel:ControlHelp("Whether cameras are breakable by default")

    local nvCheck = panel:CheckBox("Nightvision", "cameras_default_nv")
	panel:ControlHelp("Enable night vision capability")
	
	local flCheck = panel:CheckBox("Flashlight", "cameras_default_light")
	panel:ControlHelp("Enable flashlight capability")

	local scCheck = panel:CheckBox("Screen", "cameras_screen")
	scCheck.OnChange = function(_, value) 
		pvCheck:SetEnabled(value)
	end
	panel:ControlHelp("Adds screens to monitors")
	
	pvCheck = panel:CheckBox("ScreenPVS", "cameras_screen_pvs")
	panel:ControlHelp("Adds the specified vector to the PVS which is currently building. This allows all objects in visleafs visible from that vector to be drawn.")
	
	panel:Help("Client:")
	slider = panel:NumSlider( "Screen size", "cameras_screen_size", 32, 1024, 0 )
	slider.OnChange = function() print(GetConVar("cameras_screen_size"):GetInt()) end
	panel:ControlHelp("Size for screens")
	
	end )
end )

hook.Add( "SetupPlayerVisibility", "CamerasRT_Check", function( ply )
	if GetConVar("cameras_screen"):GetBool() and GetConVar("cameras_screen_pvs"):GetBool() or !Cameras.Inited then
		Cameras.Inited = true
		CamerasPVS(ply)
	end
end )

function CamerasPVS( ply )
	for _, i in ipairs( ents.FindByClass("ent_cam") ) do
		if i:IsValid() and !i:TestPVS( ply ) then
			AddOriginToPVS( i:GetPos() )
		end
	end
end

hook.Add('PreRender', 'CamerasRT_PR', function()
	if !GetConVar("cameras_screen"):GetBool() then return end
    for monitor, _ in pairs(monitorsToRender) do
        if IsValid(monitor) and IsValid(monitor:GetNWEntity('Camera')) then
			RenderCameraView(monitor)
        end
    end
	monitorsToRender = {}
end)


local function GetNewAngle(currentYaw, currentPitch, min_yaw, max_yaw, min_pitch, max_pitch, ent)

	local rot_x = (currentYaw - min_yaw) / (max_yaw - min_yaw)
	local rot_y = (currentPitch - min_pitch) / (max_pitch - min_pitch)

	local ang_y = min_pitch + rot_y * (max_pitch - min_pitch)  -- pitch (вверх/вниз)
	local ang_x = min_yaw + rot_x * (max_yaw - min_yaw)        -- yaw (влево/вправо)

	local localAngles = Angle(ang_y, ang_x, 0)
	local worldAngles = ent:LocalToWorldAngles(localAngles)

	return worldAngles
	
end

function RenderCameraView(self)
	
    local camera = self:GetNWEntity('Camera')
	
    if not IsValid(camera) then return end
    
    camera:SetNoDraw(true)
    render.PushRenderTarget(self.RTTexture)
    render.Clear(0, 0, 0, 255)
	
    local camPos = camera:GetPos()
    local camAng = camera:GetAngles()
    
    camAng:RotateAroundAxis(camAng:Up(), 0) 
    camAng:RotateAroundAxis(camAng:Forward(), 0)
    
	local min_pitch, max_pitch = camera:GetPoseParameterRange("aim_pitch")
	local min_yaw, max_yaw = camera:GetPoseParameterRange("aim_yaw")
	
	local currentYaw = camera:GetPoseParameter("aim_yaw") * (max_yaw - min_yaw) + min_yaw
	local currentPitch = camera:GetPoseParameter("aim_pitch") * (max_pitch - min_pitch) + min_pitch
	
	local worldAngles = GetNewAngle(currentYaw, currentPitch, min_yaw, max_yaw, min_pitch, max_pitch, camera)
	
	cam.Start3D(LocalPlayer():GetPos(), LocalPlayer():EyeAngles(), 0)
    render.RenderView({
        origin = camPos,
        angles = worldAngles,
        x = 0, y = 0,
        w = RT_SIZE, h = RT_SIZE,
        fov = camera:GetNWInt('FOV'),
        drawmonitors = false,
        drawviewmodel = false,
        drawviewer = true,
    })
	cam.End3D()
    
	--render.SetViewPort(0, 0, 32, 32)	
    render.PopRenderTarget()
    camera:SetNoDraw(false)

    self.ScreenMat:SetTexture("$basetexture", self.RTTexture)
	--self.ScreenMat:Recompute()
end
