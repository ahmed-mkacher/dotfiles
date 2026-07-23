return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local function hl(name)
        local color = vim.api.nvim_get_hl(0, { name = name })
        if color then
          if color.fg then
            color.fg = type(color.fg) == "number" and string.format("#%06x", color.fg) or color.fg
          end
          if color.bg then
            color.bg = type(color.bg) == "number" and string.format("#%06x", color.bg) or color.bg
          end
        end
        return color
      end

      local theme = {
        normal = {
          a = { bg = "none", fg = hl("Include").fg or "#7aa2f7", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        insert = {
          a = { bg = "none", fg = hl("String").fg or "#9ece6a", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        visual = {
          a = { bg = "none", fg = hl("Special").fg or "#bb9af7", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        replace = {
          a = { bg = "none", fg = hl("Number").fg or "#ff9e64", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        command = {
          a = { bg = "none", fg = hl("Identifier").fg or "#e0af68", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        terminal = {
          a = { bg = "none", fg = hl("String").fg or "#7dcfff", gui = "bold" },
          b = { bg = "none", fg = hl("Normal").fg or "#c0caf5" },
          c = { bg = "none", fg = hl("NonText").fg or "#a9b1d6" },
        },
        inactive = {
          a = { bg = "none", fg = hl("Comment").fg or "#565f89" },
          b = { bg = "none", fg = hl("Comment").fg or "#565f89" },
          c = { bg = "none", fg = hl("Comment").fg or "#565f89" },
        },
      }
      opts.options.theme = theme
    end,
  },
}
