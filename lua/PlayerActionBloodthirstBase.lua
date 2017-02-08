
local bloodthirstbase_original = PlayerAction.BloodthirstBase.Function

function PlayerAction.BloodthirstBase.Function(...)
	managers.gameinfo:event("buff", "activate", "bloodthirst_basic")
	managers.gameinfo:event("buff", "set_value", "bloodthirst_basic", { value = 1 })
	bloodthirstbase_original(...)
	managers.gameinfo:event("buff", "deactivate", "bloodthirst_basic")
end