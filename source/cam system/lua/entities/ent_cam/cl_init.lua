
include('shared.lua')

function ENT:Draw()

	self:DrawModel()

end

net.Receive("cl_cam_broke", function()
	local cam = net.ReadEntity()
    local bool = net.ReadBool()
	
    if !IsValid(cam) then return end

	cam.Broke = bool
end)

net.Receive( "cl_cam_menu", function() 

	local ply = LocalPlayer()
	local self = net.ReadEntity()
	local frequency = net.ReadInt(12) or 0

	if !( IsValid( ply ) and ply:IsPlayer() and IsValid( self ) ) then return end 

	if self:GetPos():DistToSqr(ply:GetPos()) > 256^2 then return end
	
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 250, 80 )
	frame:SetTitle("Settings Menu")
	frame:Center()
	frame:MakePopup()
	frame.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color( 50, 50, 50, 125 ) )

		-- Draw the outline of the menu.
		surface.SetDrawColor(0,0,0,255)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(0,0,0,255)
		surface.DrawOutlinedRect(0, 0, w, 25)
	end
	
	local DNumSlider = vgui.Create( "DNumSlider", frame )
	DNumSlider:SetPos( 10, 20 )			
	DNumSlider:SetSize( 250, 30 )
	DNumSlider:SetText( "Frequency" )	
	DNumSlider:SetMin( 0 )				
	DNumSlider:SetMax( 999 )			
	DNumSlider:SetDecimals( 0 )			
	DNumSlider:SetValue( frequency )			
	DNumSlider.OnValueChanged = function( self, value )
		frequency = math.Round(value)
		DNumSlider:SetValue( frequency )
	end
	DNumSlider.Paint = function( self, w, h ) draw.RoundedBoxEx(8,1,1,frame:GetWide()-2,frame:GetTall()-2,Color(0, 0, 0, 0), true, false, false, false) end
	
	local DButton = vgui.Create( "DButton", frame )
	DButton:SetText( "Save" )	
	DButton:SetPos( 50, 50 )
	DButton:Dock( BOTTOM )
	DButton:SetSize( 40, 25 )
	DButton.DoClick = function()
		self:EmitSound("buttons/button15.wav", 0, 150, 1, CHAN_AUTO)
		net.Start('sv_cam_menu')
			net.WriteEntity(self) -- Don`t change
			net.WriteInt( frequency, 12 )
		net.SendToServer()
	end
	DButton.Paint = function( self, w, h ) 
		draw.RoundedBox( 6, 0, 0, w, h, Color( 200, 200, 200, 230 ) )
		surface.SetDrawColor(0,0,0,255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
end )



