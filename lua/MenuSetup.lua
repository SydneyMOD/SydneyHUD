local init_game_original = MenuSetup.init_game
function MenuSetup:init_game(...)
	game_state_machine:set_boot_intro_done(true)
	game_state_machine:change_state_by_name("menu_titlescreen")

	return init_game_original(self, ...)
end
