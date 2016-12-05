
local init_original = WeaponLaser.init
local update_original = WeaponLaser.update

WeaponLaser._suffix_map = {
	player = "",
	default = "_others",
	cop_sniper = "_snipers",
	turret_module_active = "_turret",
	turret_module_rearming = "_turretr",
	turret_module_mad = "_turretm"
}

function WeaponLaser:init(...)
	init_original(self, ...)
	self._themes.player = deep_clone(self._themes.default)
	self._default_themes = deep_clone(self._themes)
	self:set_color_by_theme(self._theme_type)
end

function WeaponLaser:update(unit, t, dt, ...)
	update_original(self, unit, t, dt, ...)
	local theme = self._theme_type
	local suffix = self._suffix_map[theme]
	if suffix then
		if SydneyHUD:GetOption("enable_laser_options" .. suffix) then
			local r, g, b = SydneyHUD:GetOption("laser_color_r" .. suffix), SydneyHUD:GetOption("laser_color_g" .. suffix), SydneyHUD:GetOption("laser_color_b" .. suffix)
			if SydneyHUD:GetOption("laser_color_rainbow" .. suffix) then
				r, g, b = math.sin(135 * t + 0) / 2 + 0.5, math.sin(140 * t + 60) / 2 + 0.5, math.sin(145 * t + 120) / 2 + 0.5
			end
			self._themes[theme] = {
				light = Color(r, g, b) * SydneyHUD:GetOption("laser_light" .. suffix),
				glow = Color(r, g, b) * SydneyHUD:GetOption("laser_glow" .. suffix),
				brush = Color(SydneyHUD:GetOption("laser_color_a" .. suffix), r, g, b)
			}
		else
			self._themes[theme] = self._default_themes[theme]
		end
	else
		log("[SydneyHUD Warn] Ignoring unknown laser theme: \"" .. theme .. "\".")
	end
	self:set_color_by_theme(theme)
end
