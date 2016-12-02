local local_data = { from_x = 0, from_y = 0 }
local select_original = BlackMarketGuiSlotItem.select
local deselect_original = BlackMarketGuiSlotItem.deselect
local mouse_pressed_original = BlackMarketGui.mouse_pressed
local mouse_moved_original = BlackMarketGui.mouse_moved
local mouse_released_original = BlackMarketGui.mouse_released

function BlackMarketGuiSlotItem:select(...)
	self._data.hide_unselected_mini_icons = false
	return select_original(self, ...)
end

function BlackMarketGuiSlotItem:deselect(...)
    self._data.hide_unselected_mini_icons = false
    return deselect_original(self, ...)
end

function BlackMarketGui:mouse_pressed(...)
	if self._enabled and not self._data.is_loadout and not self._renaming_item and self._highlighted and button == Idstring("0") and self._tabs[self._highlighted]:inside(x, y) == 1 then
		local ctg = self._slot_data.category
		if (ctg == "masks" and self._slot_data.slot ~= 1 and self._data.topic_id ~= "bm_menu_buy_mask_title") or ((ctg == "primaries" or ctg == "secondaries") and not self._data.buying_weapon) then
			local_data.dragging = false
			local_data.picked = false
			local_data.from_x = x
			local_data.from_y = y
			local_data.slot_src = self._slot_data and not self._slot_data.locked_slot and self._slot_data.slot
			local_data.slot_data = self._slot_data
		end
	end
	return mouse_pressed_original(self, ...)
end

function BlackMarketGui:mouse_moved(...)
	local grab = false
	if self._enabled and self._highlighted and local_data.slot_src and self._tabs[self._highlighted] then
		if self._tab_scroll_panel:inside(x, y) and self._tabs[self._highlighted]:inside(x, y) ~= 1 then
			if self._selected ~= self._highlighted then
				self:set_selected_tab(self._highlighted)
			end
		elseif self._tabs[self._highlighted]:inside(x, y) == 1 then
			local_data.dragging = local_data.dragging or math.abs(x - local_data.from_x) > 5 or math.abs(y - local_data.from_y) > 5
			if local_data.dragging then
				if not local_data.picked then
					local_data.picked = true
					managers.blackmarket:pickup_crafted_item(self._slot_data.category, self._slot_data.slot)
				end

				if local_data.slot_data.bitmap_texture then
					local bmp = self._panel:child("SydneyHUD_Item") or self._panel:bitmap({
						name = "SydneyHUD_Item",
						texture = local_data.slot_data.bitmap_texture,
						layer = tweak_data.gui.MOUSE_LAYER - 50,
					})
					bmp:set_center(x, y)
				end
			end
		end
		grab = true
	end

	if grab then
		mouse_moved_original(self, ...)
		return true, "grab"
	else
		return mouse_moved_original(self, ...)
	end
end

function BlackMarketGui:mouse_released(...)
	if button == Idstring("0") then
		if local_data.dragging and self._highlighted and self._tabs[self._highlighted]:inside(x, y) == 1 then
			local tab = self._tabs[self._highlighted]
			local slot_dst = tab._slots[tab._slot_highlighted]._data
			if slot_dst and not slot_dst.locked_slot and not (slot_dst.category == "masks" and slot_dst.slot == 1) then
				managers.blackmarket:place_crafted_item(slot_dst.category, slot_dst.slot)
				self:reload()
			end
		end

		local bmp = self._panel:child("local_dataItem")
		if bmp then
			self._panel:remove(bmp)
		end
		local_data.dragging = false
		local_data.slot_src = nil
		local_data.slot_data = nil
	end

	return mouse_released_original(self, ...)
end
