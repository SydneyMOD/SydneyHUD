
local update_original = LootDropScreenGui.update

local SKIP_LOOT_SCREEN = SydneyHUD:GetOption("skip_loot_screen")
local SKIP_CARD_PICKING = SydneyHUD:GetOption("skip_card_picking")
local SKIP_LOOT_SCREEN_DELAY = SydneyHUD:GetOption("loot_screen_skip")

function LootDropScreenGui:update(t, ...)
	update_original(self, t, ...)
	if not self._card_chosen and SKIP_CARD_PICKING then
		self:_set_selected_and_sync(math.random(3))
		self:confirm_pressed()
	end
	if not self._button_not_clickable and SKIP_LOOT_SCREEN_DELAY >= 0 and SKIP_LOOT_SCREEN then
		self._auto_continue_t = self._auto_continue_t or (t + SKIP_LOOT_SCREEN_DELAY)
		if t >= self._auto_continue_t then
			self:continue_to_lobby()
		end
	end
end
