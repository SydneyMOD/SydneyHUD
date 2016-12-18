local _init_civilian_original = CharacterTweakData._init_civilian

function CharacterTweakData:_init_civilian(...)
	_init_civilian_original(self, ...)
	if SydneyHUD:GetOption("civilian_spot") then
		self.civilian.silent_priority_shout = "f37"
		self.civilian_female.silent_priority_shout = "f37"
	end
end
