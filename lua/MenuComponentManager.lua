
local create_new_heists_gui_original = MenuComponentManager.create_new_heists_gui

function MenuComponentManager:create_new_heists_gui(...)
	if SydneyHUD:GetOption("remove_ads") then
		self:close_new_heists_gui()
	else
		create_new_heists_gui_original(self, ...)
	end
end