
local init_original = HUDAssaultCorner.init
local _start_assault_original = HUDAssaultCorner._start_assault

function HUDAssaultCorner:init(hud, full_hud, tweak_hud, ...)
	init_original(self, hud, full_hud, tweak_hud, ...)
	if self._hud_panel:child("hostages_panel") then
		self:_hide_hostages()
	end
	if SydneyHUD:GetOption("center_assault_banner") then
		self._hud_panel:child("assault_panel"):set_right(self._hud_panel:w() / 2 + 150)
		self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_visible(false)
		self._hud_panel:child("casing_panel"):set_right(self._hud_panel:w() / 2 + 150)
		self._hud_panel:child("casing_panel"):child("icon_casingbox"):set_visible(false)
		self._hud_panel:child("point_of_no_return_panel"):set_right(self._hud_panel:w() / 2 + 150)
		self._hud_panel:child("point_of_no_return_panel"):child("icon_noreturnbox"):set_visible(false)
		self._hud_panel:child("buffs_panel"):set_x(self._hud_panel:child("assault_panel"):right())
		self._vip_bg_box:set_x(0) -- left align this "buff"
		self._last_assault_timer_size = 0
		self._assault_timer = HUDHeistTimer:new({
			panel = self._bg_box:panel({
				name = "assault_timer_panel",
				x = 4
			})
		}, tweak_hud)
		self._assault_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
		self._assault_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
		self._assault_timer._timer_text:set_align("left")
		self._assault_timer._timer_text:set_vertical("center")
		self._assault_timer._timer_text:set_color(Color.white:with_alpha(0.9))
		self._last_casing_timer_size = 0
		self._casing_timer = HUDHeistTimer:new({
			panel = self._casing_bg_box:panel({
				name = "casing_timer_panel",
				x = 4
			})
		}, tweak_hud)
		self._casing_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
		self._casing_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
		self._casing_timer._timer_text:set_align("left")
		self._casing_timer._timer_text:set_vertical("center")
		self._casing_timer._timer_text:set_color(Color.white:with_alpha(0.9))
	end
end

function HUDAssaultCorner:feed_heist_time(t, ...)
	local time = "00:00"

	if t >= 60 then
		local m = tonumber(string.format("%d", t/60))
		local s = t - m*60

		if m >= 60 then
			local h = tonumber(string.format("%d", m/60))
				m = m - h*60
			time = string.format("%02d:%02d:%02d", h, m, s)
		else
			time = string.format("%02d:%02d", m, s)
		end

	else
		r = string.format("00:%02d", t)
	end

	if self._assault_timer then
		self._assault_timer:set_time(t)
		local _, _, cw, _ = self._assault_timer._timer_text:text_rect()
		if self._bg_box:child("text_panel") and self._bg_box:w() >= 242 and cw ~= self._last_assault_timer_size then
			self._last_assault_timer_size = cw
			self._bg_box:child("text_panel"):set_w(self._bg_box:w() - (cw + 8))
			self._bg_box:child("text_panel"):set_x(cw + 8)
		end
	end
	if self._casing_timer then
		self._casing_timer:set_time(t)
		local _, _, aw, _ = self._casing_timer._timer_text:text_rect()
		if self._casing_bg_box:child("text_panel") and self._casing_bg_box:w() >= 242 and aw ~= self._last_casing_timer_size then
			self._last_casing_timer_size = aw
			self._casing_bg_box:child("text_panel"):set_w(self._casing_bg_box:w() - (aw + 8))
			self._casing_bg_box:child("text_panel"):set_x(aw + 8)
		end
	end
end

function HUDAssaultCorner:_show_hostages(...)
	return
end

function HUDAssaultCorner:_start_assault(text_list, ...)
	if Network:is_server() then
		-- Hack for Enhanced Assault Banner
		-- this allows the LocationManager to reroute the call for the assault banner text.
		for i = 1, 1000 do
			if text_list[i] == "hud_assault_assault" then
				text_list[i] = "hud_assault_enhanced"
			end
		end
	end
	return _start_assault_original(self, text_list, ...)
end
