
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

concommand.Add("cameras_ScreenPVS", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	cameras_command("ScreenPVS", args)
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
		pvCheck:SetEnabled(value)
		--scCheck:SetChecked(Cameras.Config.Screen) 
	end
	panel:ControlHelp("Adds screens to monitors")
	
	pvCheck = panel:CheckBox("ScreenPVS")
    pvCheck:SetChecked(Cameras.Config.ScreenPVS)
    pvCheck.OnChange = function(_, value) 
		RunConsoleCommand("cameras_ScreenPVS", tostring(value)) 
		--scCheck:SetChecked(Cameras.Config.Screen) 
	end
	panel:ControlHelp("PVS for all cameras")
	
	end )
end )

hook.Add( "SetupPlayerVisibility", "CamerasRT_Check", function( ply )
	if Cameras.Config.Screen and Cameras.Config.ScreenPVS or !Cameras.Inited then
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