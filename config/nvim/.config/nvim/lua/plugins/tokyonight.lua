return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        hl.StatusLine = { bg = "none" }
        hl.StatusLineNC = { bg = "none" }
      end,
    },
  },
}
