
include('shared.lua')

local RT_SIZE = 128 -- Разрешение RT текстуры

local monitorsToRender = {}


function ENT:Initialize()
	self.RTTexture = GetRenderTarget("CamerasRT_" .. self:EntIndex(), RT_SIZE, RT_SIZE)
    self.ScreenMat = CreateMaterial("CamerasMat_" .. self:EntIndex(), "UnlitGeneric", {
    ["$basetexture"] = self.RTTexture:GetName(),
    ["$translucent"] = 0,
    ["$vertexalpha"] = 0,
    ["$ignorez"] = 0,
    ["$nolod"] = 0
	})
end

function ENT:Draw()
    self:DrawModel() -- Отрисовываем основную модель монитора
	
	local cam = self:GetNWEntity('Camera') or NULL
    -- Добавляем монитор в список для рендеринга, если у него есть камера
    if IsValid(cam) and cam != NULL then
		if !cam.Broke then
			monitorsToRender[self] = true
		end
    end

    -- Отрисовываем черную панель с RT материалом
    self:DrawScreenPanel()
end

local noiseTexture = Material("effects/tvscreen_noise002a")

function ENT:DrawScreenPanel()

	if !Cameras.Config.Screen then return end

    local pos = self:GetPos()
    local ang = self:GetAngles()
    
	local cam_pos = Cameras.Monitors[self:GetModel()].pos
	local cam_ang = Cameras.Monitors[self:GetModel()].ang
	
    -- Корректируем позицию экрана (передняя часть монитора)
    pos = pos + ang:Forward() * cam_pos.Forward + ang:Up() * cam_pos.Up + ang:Right() * cam_pos.Right
    
    -- Корректируем угол (чтобы экран смотрел вперед)
    ang:RotateAroundAxis(ang:Right(), cam_ang.Right)
    ang:RotateAroundAxis(ang:Up(), cam_ang.Up)
    ang:RotateAroundAxis(ang:Forward(), cam_ang.Forward)
    
    cam.Start3D2D(pos, ang, 0.8)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.SetMaterial(self.ScreenMat)
        surface.DrawTexturedRect(cam_pos.x, cam_pos.y, cam_pos.w, cam_pos.h)
		
		if Cameras.Config.NoiseEnabled then
			surface.SetMaterial(noiseTexture)
			surface.DrawTexturedRect(cam_pos.x, cam_pos.y, cam_pos.w, cam_pos.h)
		end

    cam.End3D2D()
end

hook.Add('PreRender', 'CamerasRT_PR', function()
    for monitor, _ in pairs(monitorsToRender) do
        if IsValid(monitor) and IsValid(monitor:GetNWEntity('Camera')) then
            monitor:RenderCameraView()
        end
    end
	monitorsToRender = {}
end)

function ENT:RenderCameraView()
	
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
	
	local rot_x = (currentYaw - min_yaw) / (max_yaw - min_yaw)
	local rot_y = (currentPitch - min_pitch) / (max_pitch - min_pitch)

	local ang_y = min_pitch + rot_y * (max_pitch - min_pitch)  -- pitch (вверх/вниз)
	local ang_x = min_yaw + rot_x * (max_yaw - min_yaw)        -- yaw (влево/вправо)

	localAngles = Angle(ang_y, ang_x, 0)
	worldAngles = camera:LocalToWorldAngles(localAngles)
	
	cam.Start3D(LocalPlayer():GetPos(), LocalPlayer():EyeAngles(), 0)
    render.RenderView({
        origin = camPos,
        angles = worldAngles,
        x = 0, y = 0,
        w = RT_SIZE, h = RT_SIZE,
        fov = 90,
        drawmonitors = false,
        drawviewmodel = false,
        drawviewer = true,
    })
	cam.End3D()
        
	--render.SetViewPort(0, 0, 32, 32)	
    render.PopRenderTarget()
    camera:SetNoDraw(false)

    -- Обновляем материал
    self.ScreenMat:SetTexture("$basetexture", self.RTTexture)
	--self.ScreenMat:Recompute()
end

net.Receive( "cl_cam_cash", function() 
    local cam = net.ReadEntity()
    cam:InvalidateBoneCache()
	--cam:SetupBones()
	--cam:FrameAdvance()
end )

net.Receive( "cl_control_menu", function() 
    local cams = {}
    local ply = LocalPlayer()
    local self = net.ReadEntity()
    local numCams = net.ReadUInt(9)

    for i = 1, numCams-1 do
        local cam = net.ReadEntity()
        if IsValid(cam) then
            table.insert(cams, cam)
        end
    end
    
    if !( IsValid( ply ) and ply:IsPlayer() and IsValid( self ) ) then return end -- IsAlive()
    if self:GetPos():DistToSqr(ply:GetPos()) > 256^2 then return end

    local current = 1
	if IsValid(self:GetNWEntity('Camera')) and self:GetNWEntity('Camera') != NULL and not self:GetNWEntity('Camera').Broke then
		current = table.KeyFromValue( cams, self:GetNWEntity('Camera'))
	end
    local _fov = 90
    local rotationSpeed = 60
	local max_fov = 90
	local min_fov = 35
    local lastThink = CurTime()

    local currentPitch = 0
    local currentYaw = 0
    local targetPitch = 0
    local targetYaw = 0

	local nightVisionEnabled = false

    local black = vgui.Create( "DFrame" )
	black:SetSize( ScrW(), ScrH() )
    black:SetTitle("")
    black:SetDraggable(false)
    black:Center()
    black:ShowCloseButton(false)
	function black:Paint( w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) ) end
	
    local frame = vgui.Create( "DFrame" )
    frame:SetSize( ScrW(), ScrH() )
    frame:SetTitle("")
    frame:Center()
    frame:SetDraggable(false)
	frame:ShowCloseButton(false)
    frame:MakePopup()

    frame:SetKeyboardInputEnabled(true)
    
    frame.OnClose = function()
		black:Close()
		
		if !IsValid(cams[current]) then return end
        net.Start('sv_cam_view')
            net.WriteEntity(cams[current]) -- cam
			net.WriteEntity(self) -- ent
        net.SendToServer()
    end

    -- Таблица для отслеживания нажатых клавиш
    local keyState = {
        [KEY_W] = false,
        [KEY_A] = false,
        [KEY_S] = false,
        [KEY_D] = false
    }
    function frame:OnKeyCodePressed(key) -- Нажат
		if key == KEY_E or key == KEY_SPACE then
            OnClose()
		end
		if key == KEY_N then
			if Cameras.Config.NVEnabled then
				nightVisionEnabled = !nightVisionEnabled
				render.SetLightingMode(nightVisionEnabled and 1 or 0)
				ply:EmitSound("buttons/button15.wav", 0, 150, 1, CHAN_AUTO)
			else
				print("Night vision disabled!")
			end
		end
		if table.IsEmpty(cams) then return end
        if !IsValid(cams[current]) then return end
        if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
            keyState[key] = true
			ply:EmitSound("physics/plaster/ceiling_tile_scrape_smooth_loop1.wav", 0, 230, 0.6, CHAN_AUTO)
        end
    end
	
	function OnClose()
		frame:Close()
		for i=1,5 do -- wasd+
			ply:StopSound("physics/plaster/ceiling_tile_scrape_smooth_loop1.wav")
		end
        net.Start('sv_cam_view') -- обновление отображения камеры
            net.WriteEntity(ply)
            net.WriteEntity(self)
        net.SendToServer()
		render.SetLightingMode(0)
		render.SuppressEngineLighting(false)
	end

    function frame:OnKeyCodeReleased(key) -- Отжат
        if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
            keyState[key] = false
			ply:StopSound("physics/plaster/ceiling_tile_scrape_smooth_loop1.wav") -- can error cuz not always can be Released after Press (like while ESC menu)
        end
		
    end

	function frame:OnMousePressed(code)
		if table.IsEmpty(cams) then return end
		if code == MOUSE_RIGHT then
            current = current < #cams and current + 1 or 1
        elseif code == MOUSE_LEFT then
            current = current > 1 and current - 1 or #cams
        end
		CamChange()
		--if code == MOUSE_MIDDLE then
			--frame:SetKeyboardInputEnabled(!frame:IsKeyboardInputEnabled())
		--end
    end

	if Cameras.Config.NoiseEnabled then
		local noise = vgui.Create("DImage", frame)
		noise:SetSize( ScrW(), ScrH())
		noise:SetImage("effects/tvscreen_noise002a") -- effects/combine_binocoverlay
	end

	local min_pitch, max_pitch
	local min_yaw, max_yaw

	function CamChange() -- Deploy
		if table.IsEmpty(cams) then return end
        if !IsValid(cams[current]) then return end
		
		local cam = cams[current]
		min_pitch, max_pitch = cam:GetPoseParameterRange("aim_pitch")
		min_yaw, max_yaw = cam:GetPoseParameterRange("aim_yaw")

		ply:EmitSound("buttons/button15.wav", 0, 150, 1, CHAN_AUTO)
		currentYaw = cam:GetPoseParameter("aim_yaw") * (max_yaw - min_yaw) + min_yaw
		currentPitch = cam:GetPoseParameter("aim_pitch") * (max_pitch - min_pitch) + min_pitch
		net.Start('sv_cam_view')
            net.WriteEntity(cam)
			net.WriteEntity(self)
        net.SendToServer()
		targetYaw = currentYaw
        targetPitch = currentPitch
		_fov = 90
	end

	if IsValid(cams[current]) then
        CamChange()
    end
    
    function frame:OnMouseWheeled(delta)
		if table.IsEmpty(cams) then return end
        if !IsValid(cams[current]) then return end
		ply:EmitSound("buttons/lightswitch2.wav", 0, 200, 0.5, CHAN_AUTO)
        _fov = math.Clamp(_fov - delta*5, min_fov, max_fov)
    end

	local now
	local deltaTime
	
	local lastSendTime = 0
	local sendInterval = 0.15
	
    function frame:Think()
	
        now = CurTime()
        deltaTime = now - lastThink
        lastThink = now
		
		if !(keyState[KEY_W] or keyState[KEY_S] or keyState[KEY_A] or keyState[KEY_D]) then return end
		if table.IsEmpty(cams) or !IsValid(cams[current]) or cams[current].Broke then return end
		
		rotationSpeed = 60 * _fov/100

        if keyState[KEY_W] then targetPitch = math.Clamp(targetPitch - rotationSpeed * deltaTime, min_pitch, max_pitch) end
        if keyState[KEY_S] then targetPitch = math.Clamp(targetPitch + rotationSpeed * deltaTime, min_pitch, max_pitch) end
        if keyState[KEY_A] then targetYaw = math.Clamp(targetYaw + rotationSpeed * deltaTime, min_yaw, max_yaw) end
        if keyState[KEY_D] then targetYaw = math.Clamp(targetYaw - rotationSpeed * deltaTime, min_yaw, max_yaw) end
		
        currentPitch = targetPitch
        currentYaw = targetYaw

		if now - lastSendTime >= sendInterval then
			net.Start('sv_cam_rot') -- обновление pose для сервера
				net.WriteEntity(cams[current])
				net.WriteInt(math.Round(currentYaw), 12)
				net.WriteInt(math.Round(currentPitch), 12)
			net.SendToServer()
			lastSendTime = now
		end

    end

	local rot_x, rot_y
	local ang_x, ang_y
	local localAngles, worldAngles

    function frame:Paint( w, h )
        draw.DrawText( "No connection", "HudDefault", w/2, h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )

        if table.IsEmpty(cams) then return end
        if !IsValid(cams[current]) then return end
        if cams[current].Broke then
            table.remove(cams, current)
            return
        end

		rot_x = (currentYaw - min_yaw) / (max_yaw - min_yaw)
		rot_y = (currentPitch - min_pitch) / (max_pitch - min_pitch)

		ang_y = min_pitch + rot_y * (max_pitch - min_pitch)  -- pitch (вверх/вниз)
		ang_x = min_yaw + rot_x * (max_yaw - min_yaw)        -- yaw (влево/вправо)

		localAngles = Angle(ang_y, ang_x, 0)
		worldAngles = cams[current]:LocalToWorldAngles(localAngles)
		
		render.SuppressEngineLighting(nightVisionEnabled)

		local x, y = self:GetPos()
        render.RenderView({
            origin = Cameras.Models[cams[current]:GetModel()].origin(cams[current]),
            angles = worldAngles,
            drawviewmodel = false,
            drawmonitors = false,
            x = x, y = y,
            w = w, h = h,
            fov = _fov,
            znear = 15,
            zfar = 32768,
        })

		if nightVisionEnabled then
			DrawColorModify(Cameras.NV)
		end
	
		draw.DrawText("E & Space - Exit | WASD - Rotate | LMB & RMB - Change Camera | Mouse Wheel - Zoom | N - Night Vision", "CenterPrintText", w/2, h - 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.DrawText( "Cam " .. current .. "\nPitch: " .. math.ceil(currentPitch) .. "\nYaw: " .. math.ceil(currentYaw) .. "\nFOV: " .. _fov, "CenterPrintText", 10, 10, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
    end 
    
    if !table.IsEmpty(cams) then
        net.Start('sv_cam_view')
            net.WriteEntity(cams[current])
			net.WriteEntity(self)
        net.SendToServer()
    end
end )
