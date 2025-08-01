
if CLIENT then

    language.Add("spawnmenu.utilities.cameras", "Cameras")

end

hook.Add( "AddToolMenuTabs", "myHookClass", function()
	spawnmenu.AddToolCategory( "Utilities", "Cameras", "#spawnmenu.utilities.cameras" )
	spawnmenu.AddToolMenuOption( "Utilities", "Cameras", "settings", "Settings", "", "", function( panel )
	
	panel:SetName("Settings")
    panel:SetPadding(10)
	panel:Help("Server:")

	local noiseCheck = panel:CheckBox("Noise", "cameras_noise")
	panel:ControlHelp("Whether cameras are breakable by default")

    local breakCheck = panel:CheckBox("Breakable", "cameras_default_breakable")
	panel:ControlHelp("Enable night vision capability")

    local nvCheck = panel:CheckBox("Nightvision", "cameras_default_nv")
	panel:ControlHelp("Adds visual noise effect to cameras")

	local scCheck = panel:CheckBox("Screen", "cameras_screen")
	scCheck.OnChange = function(_, value) 
		pvCheck:SetEnabled(value)
	end
	panel:ControlHelp("Adds screens to monitors")
	
	pvCheck = panel:CheckBox("ScreenPVS", "cameras_screen_pvs")
	panel:ControlHelp("PVS for all cameras")
	
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