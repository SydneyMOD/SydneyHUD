local select_original = BlackMarketGuiSlotItem.select
local deselect_original = BlackMarketGuiSlotItem.deselect

function BlackMarketGuiSlotItem:select(instant, no_sound)
	self._data.hide_unselected_mini_icons = false
	return select_original(self, instant, no_sound)
end

function BlackMarketGuiSlotItem:deselect(instant)
	self._data.hide_unselected_mini_icons = false
	return deselect_original(self, instant)
end