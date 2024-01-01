local wezterm = require("wezterm")

return {
  font = wezterm.font_with_fallback({
    "JetBrains Mono NF",
    "JetBrains Mono",
    "Noto Color Emoji",
  }),
  harfbuzz_features = { "zero" },

  color_scheme = "Catppuccin Mocha",
  window_background_opacity = 0.90,
  force_reverse_video_cursor = true,

  hide_tab_bar_if_only_one_tab = true,
}
