core:module("CoreMenuItemSlider")
local set_value_original = ItemSlider.set_value

function ItemSlider:set_value(value)
    value = self._min + self._step * math.round((value - self._min) / self._step)
    set_value_original(self, value)
end