
function MenuSceneManager:_get_lobby_character_prio_item(rank, outfit)
	local infamous = rank and rank > 0
	local primary_rarity, secondary_rarity
	if SydneyHUD:GetOption("lobby_skins_mode") ~= 2 then
		if outfit.primary.cosmetics and outfit.primary.cosmetics.id and outfit.primary.cosmetics.id ~= "nil" then
			local rarity = tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id] and tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id].rarity
			primary_rarity = tweak_data.economy.rarities[rarity].index
		end
		if outfit.secondary.cosmetics and outfit.secondary.cosmetics.id and outfit.secondary.cosmetics.id ~= "nil" then
			local rarity = tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id] and tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id].rarity
			secondary_rarity = tweak_data.economy.rarities[rarity].index
		end
		if (primary_rarity and secondary_rarity and primary_rarity >= secondary_rarity) or primary_rarity or (SydneyHUD:GetOption("lobby_skins_mode") == 3) then
			return "primary"
		elseif secondary_rarity or (SydneyHUD:GetOption("lobby_skins_mode") == 4) then
			return "secondary"
		end
	end
	return infamous and "rank" or "primary"
end
