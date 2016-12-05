
if SydneyHUD:GetOption("enable_objective_animation") then

	HUDPresenter = HUDPresenter or class()

	function HUDPresenter:init(hud)
		self._hud_panel = hud.panel
		if self._hud_panel:child("present_panel") then
			self._hud_panel:remove(self._hud_panel:child("present_panel"))
		end
		local _
		local h = 68
		local w = 450
		local x = math.round(self._hud_panel:w()/2 - w/2)
		local y = math.round(self._hud_panel:h()/14)
		local present_panel = self._hud_panel:panel({ visible = false, name = "present_panel", layer = 10 })
		local message_panel = present_panel:panel({ visible = false, alpha = 0, name = "message_panel", h = h, w = w, x = x, y = y, valign = {1/5,0} })
		message_panel:set_center_y(math.round(self._hud_panel:h()/5))
		message_panel:rect({ name = "rect", color = Color.black:with_alpha(0) })
		local title = message_panel:text({ name = "title", text = "SIZE", vertical="bottom", valign="grow",  layer = 1, color = (Color.white/2):with_alpha(1), font = tweak_data.hud_present.title_font, font_size = tweak_data.hud_present.title_size })
		_,_,_,h = title:text_rect()
		title:set_h(h)
		title:set_bottom(math.floor(message_panel:h()/ 2) + 2)
		local text = message_panel:text({ name = "text", text = "SIZE", vertical="top", valign="grow", layer = 1, color = Color.white, font = tweak_data.hud_present.text_font, font_size = tweak_data.hud_present.text_size })
		_,_,_,h = text:text_rect()
		text:set_h(h)
		text:set_top(math.ceil(message_panel:h()/ 2) - 2)
		local icon = message_panel:bitmap({ name = "icon", layer = 1, color = Color.black, h = h - 32, w = h - 32, y = 16 })
		icon:set_right(message_panel:w())
		self._bg_start = message_panel:bitmap({ name = "bg_start", texture = "guis/textures/trial_bank", alpha = 1,     layer = 0, color = Color.black })
		self._bg_mid = message_panel:bitmap({ name = "bg_mid", texture = "units/world/props/yacht/basket/generic_fruit_nm", alpha = 1,   layer = 0, color = Color.black })
		self._bg_end = message_panel:bitmap({ name = "bg_end", texture = "guis/textures/trial_bridge", alpha = 1,   layer = 0, color = Color.black })
		self._bg_start:set_size(message_panel:h(), message_panel:h())
		self._bg_mid:set_size(message_panel:h(), message_panel:h())
		self._bg_mid:set_x(message_panel:h())
		self._bg_end:set_size(message_panel:h(), message_panel:h())
		self._bg_end:set_x(message_panel:h() * 2)
		local stroke1 = present_panel:bitmap({ rotation = 6 + 180, name = "stroke1", alpha = 0.25, texture = "units/world/props/yacht/drugs/lxy_prop_party_drugs_nm", layer = 0, color = Color.black, })
		local stroke2 = present_panel:bitmap({ rotation = -5, name = "stroke2", alpha = 0.25, texture = "units/world/props/yacht/drugs/lxy_prop_party_drugs_nm", layer = 0, color = Color.black, })
		stroke1:set_center(message_panel:center())
		stroke2:set_center(message_panel:center())
		local glow = present_panel:bitmap({ rotation = 360, name = "glow", blend_mode = "add", alpha = 1, texture = "guis/textures/pd2/hot_cold_glow", layer = -2, color = Color(0.5, 0.5, 0.9), w = stroke1:w()*2, h = stroke1:h()*2.5 })
		glow:set_center(message_panel:center())
		local big_glow = present_panel:bitmap({ rotation = 360, name = "big_glow", blend_mode = "add", alpha = 1, texture = "guis/textures/pd2/hot_cold_glow", layer = -2, color = Color(0.9, 0.5, 0.5), w = stroke1:w()*5, h = stroke1:h()*0.75 })
		big_glow:set_center(message_panel:center())
	end

	function HUDPresenter:present(params)
		self._present_queue = self._present_queue or {}
		if self._presenting then
			table.insert(self._present_queue, params)
			return
		end
		if params.present_mid_text then
			self:_present_information(params)
		end
	end

	function HUDPresenter:_present_information(params)
		local present_panel = self._hud_panel:child("present_panel")
		local message_panel = present_panel:child("message_panel")
		local title = message_panel:child("title")
		local text = message_panel:child("text")
		title:set_text(utf8.to_upper(params.title or "ERROR"))
		text:set_text(utf8.to_upper(params.text))
		local _,_,w,_ = title:text_rect()
		title:set_w(w)
		local _,_,w2,_ = text:text_rect()
		text:set_w(w2)
		local tw = math.max(w, w2)
		local x_offset = 16
		title:set_x(x_offset)
		text:set_x(x_offset)
		local def_w = message_panel:h()
		local parts = math.max(3, math.ceil((tw + x_offset)/def_w))
		message_panel:set_w(parts * def_w)
		self._bg_mid:set_w(def_w * (parts - 2))
		self._bg_end:set_x(def_w * (parts - 1))
		message_panel:set_left(math.round(message_panel:parent():w()/2 - message_panel:w()/2))
		if params.event then
			managers.hud._sound_source:post_event(params.event)
		end
		present_panel:animate(callback(self, self, "_animate_present_information"), { done_cb = callback(self, self, "_present_done"), seconds = params.time or 4, use_icon = params.icon })
		self._presenting = true
	end

	function HUDPresenter:_present_done()
		print(Application:time(), ":_present_done()")
		self._presenting = false
		local queued = table.remove(self._present_queue, 1)
		if queued then
			if queued.present_mid_text then
				setup:add_end_frame_clbk(callback(self, self, "_do_it", queued))
			end
		end
	end

	function HUDPresenter:_do_it(queued)
		print("do_it", inspect(queued))
		self:_present_information(queued)
	end

	function HUDPresenter:_animate_show_text(title, text)
		local TOTAL_T = 0.5
		local t = TOTAL_T
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			local alpha = math.round(math.abs(((math.sin((t) * 360 * 3)))))
			title:set_alpha(alpha)
			text:set_alpha(alpha)
		end
		title:set_alpha(1)
		text:set_alpha(1)
	end

	function HUDPresenter:_animate_hide_text(title, text)
		local TOTAL_T = 0.5
		local t = TOTAL_T
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			local vis = math.round(math.abs(((math.cos((t) * 360 * 3)))))
			title:set_alpha(vis)
			text:set_alpha(vis)
		end
		title:set_alpha(1)
		text:set_alpha(1)
		title:set_visible(false)
		text:set_visible(false)
	end

	function HUDPresenter:_animate_present_information(present_panel, params)
		local message_panel = present_panel:child("message_panel")
		message_panel:child("icon"):set_visible(params.use_icon)
		present_panel:set_visible(true)
		present_panel:set_alpha(1)
		local stroke1 = present_panel:child("stroke1")
		local stroke2 = present_panel:child("stroke2")
		local glow = present_panel:child("glow")
		local big_glow = present_panel:child("big_glow")
		local intro = 	function(stroke)
			local INTRO_T = 0.3
			local t = INTRO_T
			local scale = 10
			local sw = stroke:w()
			local cx,cy = message_panel:center()
			while t > 0 do
				local dt = coroutine.yield()
				t = t - dt
				local a = 1 - t/INTRO_T
				stroke:set_alpha(a)
				local w = math.lerp(sw, sw * scale, t/INTRO_T)
				stroke:set_w(w)
				stroke:set_center(cx, cy)
			end
			stroke:set_alpha(1)
			stroke:set_w(sw)
		end
		stroke1:animate(intro)
		wait(0.2)
		stroke2:animate(intro)
		wait(0.3)
		-- Anim for glow pulses
		local glow_pulse = 	function(glo)
			local TOTAL_T = 0.3
			local t = TOTAL_T
			while t > 0 do
				local dt = coroutine.yield()
				t = t - dt
				local a = 1 - t/TOTAL_T
				glo:set_alpha(a)
			end
			t = 0
			while true do
				local dt = coroutine.yield()
				t = t + dt
				local a = 0.5 + (1 + math.sin(t * 360)) / 4
				glo:set_alpha(a)
			end
		end
		glow:animate(glow_pulse)
		big_glow:animate(glow_pulse)
		message_panel:set_visible(true)
		message_panel:set_alpha(0)
		local t = params.seconds
		local tt = 0
		local present_time = 0.25
		local TOTAL_BG_T = 2.5
		local bg_t = TOTAL_BG_T
		-- Anim fade up, sustain and fade down of message panel
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			tt = tt + dt
			bg_t = bg_t - dt
			if t < 0.25 then
				local a = t/0.25
				message_panel:set_alpha(a)
				glow:set_alpha(math.min(glow:alpha(), a))
				big_glow:set_alpha(math.min(glow:alpha(), a))
			else
				local a = math.min(tt/present_time, 1)
				message_panel:set_alpha(a)
			end
		end
		message_panel:set_visible(false)
		message_panel:set_alpha(0)
		glow:stop()
		glow:set_alpha(0)
		big_glow:stop()
		big_glow:set_alpha(0)
		local outro = 	function(stroke)
			local OUTRO_T = 0.3
			local ot = OUTRO_T
			local scale = 10
			local sw = stroke:w()
			local cx,cy = message_panel:center()
			while ot > 0 do
				local dt = coroutine.yield()
				ot = ot - dt
				local a = ot/OUTRO_T
				stroke:set_alpha(a)
				local w = math.lerp(sw, sw * scale, 1 - ot/OUTRO_T)
				stroke:set_w(w)
				stroke:set_center(cx, cy)
			end
			stroke:set_alpha(1)
			stroke:set_w(sw)
		end
		stroke1:animate(outro)
		wait(0.2)
		stroke2:animate(outro)
		wait(0.3)
		present_panel:set_visible(false)
		params.done_cb()
	end
end
