local wezterm = require("wezterm")

function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

return {
  font = wezterm.font_with_fallback({
    "JetBrains Mono Nerd Font",
    "JetBrains Mono",
    "Noto Color Emoji",
  }),
  harfbuzz_features = { "zero" },

  color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
  window_background_opacity = 0.90,

  enable_scroll_bar = true,

  hide_tab_bar_if_only_one_tab = true,
}
