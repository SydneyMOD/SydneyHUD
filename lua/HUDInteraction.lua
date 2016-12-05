
local init_original = HUDInteraction.init
local show_interaction_bar_original = HUDInteraction.show_interaction_bar
local set_interaction_bar_width_original = HUDInteraction.set_interaction_bar_width
local hide_interaction_bar_original = HUDInteraction.hide_interaction_bar
local destroy_original = HUDInteraction.destroy

function HUDInteraction:init(hud, child_name)
	init_original(self, hud, child_name)
	self._interact_timer_text = self._hud_panel:text({
		name = "interact_timer_text",
		visible = false,
		text = "",
		valign = "center",
		align = "center",
		layer = 2,
		color = Color.white,
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.hud_present.text_size + 8,
		h = 64
	})
	self._interact_timer_text:set_y(self._hud_panel:h() / 2)
	for i = 1, 4 do
		self["_bgtext" .. i] = self._hud_panel:text({
			name = "bgtext" .. i,
			visible = false,
			text = "",
			valign = "center",
			align = "center",
			layer = 1,
			color = Color.black,
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.hud_present.text_size + 8,
			h = 64
		})
	end
	self._bgtext1:set_y(self._hud_panel:h() / 2 - 1)
	self._bgtext1:set_x(self._bgtext1:x() - 1)
	self._bgtext2:set_y(self._hud_panel:h() / 2 + 1)
	self._bgtext2:set_x(self._bgtext2:x() + 1)
	self._bgtext3:set_y(self._hud_panel:h() / 2 + 1)
	self._bgtext3:set_x(self._bgtext3:x() - 1)
	self._bgtext4:set_y(self._hud_panel:h() / 2 - 1)
	self._bgtext4:set_x(self._bgtext4:x() + 1)
end

function HUDInteraction:show_interaction_bar(current, total)
	show_interaction_bar_original(self, current, total)
	self._interact_circle:set_visible(SydneyHUD:GetOption("show_interaction_circle"))
	self._interact_timer_text:set_visible(SydneyHUD:GetOption("show_interaction_text"))
	for i = 1, 4 do
		self["_bgtext" .. i]:set_visible(SydneyHUD:GetOption("show_interaction_text") and SydneyHUD:GetOption("show_text_borders"))
	end
end

function HUDInteraction:set_interaction_bar_width(current, total)
	set_interaction_bar_width_original(self, current, total)
	if not self._interact_timer_text then
		return
	end
	local text = string.format("%.1f", total - current >= 0 and total - current or 0) .. "s"
	local color = Color(SydneyHUD:GetOption("interaction_color_r"), SydneyHUD:GetOption("interaction_color_g"), SydneyHUD:GetOption("interaction_color_b"))
	self._interact_timer_text:set_text(text)
	self._interact_timer_text:set_color(Color(
		color.a + (current / total),
		color.r + (current / total),
		color.g + (current / total),
		color.b + (current / total)
	))
	for i = 1, 4 do
		self["_bgtext" .. i]:set_text(text)
	end
end

function HUDInteraction:hide_interaction_bar(complete)
	hide_interaction_bar_original(self, complete and SydneyHUD:GetOption("show_interaction_circle"))
	self._interact_timer_text:set_visible(false)
	for i = 1, 4 do
		self["_bgtext" .. i]:set_visible(false)
	end
end

function HUDInteraction:destroy()
	self._hud_panel:remove(self._hud_panel:child("interact_timer_text"))
	self._hud_panel:remove(self._hud_panel:child("bgtext1"))
	self._hud_panel:remove(self._hud_panel:child("bgtext2"))
	self._hud_panel:remove(self._hud_panel:child("bgtext3"))
	self._hud_panel:remove(self._hud_panel:child("bgtext4"))
	destroy_original(self)
end
