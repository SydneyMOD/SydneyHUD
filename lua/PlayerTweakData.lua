local init_original = PlayerTweakData.init
function PlayerTweakData:init()
	init_original(self)
	if SydneyHUD:GetOption("anti_bobble") then
		for k, v in pairs(self.stances) do
			v.standard.shakers.breathing.amplitude = 0
			v.crouched.shakers.breathing.amplitude = 0
			v.standard.vel_overshot.yaw_neg = 0
			v.standard.vel_overshot.yaw_pos = 0
			v.standard.vel_overshot.pitch_neg = 0
			v.standard.vel_overshot.pitch_pos = 0
			v.crouched.vel_overshot.yaw_neg = 0
			v.crouched.vel_overshot.yaw_pos = 0
			v.crouched.vel_overshot.pitch_neg = 0
			v.crouched.vel_overshot.pitch_pos = 0
		end
	end
end
