
if ContractBoxGui.UpdateTeamBox then
	local UpdateTeamBox_original = ContractBoxGui.UpdateTeamBox

	function ContractBoxGui:UpdateTeamBox()
		UpdateTeamBox_original(self)
		if SydneyHUD:GetOption("move_lpi_lobby_box") then
			if alive(self._team_skills_panel) then
				self._team_skills_panel:set_left(self._panel:w() / 2 - self._team_skills_panel:w() / 2)
				self._team_skills_panel:set_top(0)
			end
			if alive(self._team_skills_text) then
				self._team_skills_text:set_visible(false)
			end
		end
	end
end