-- File: lua/custom/plugins/vue_utils.lua

local M = {}

function M.is_in_start_tag()
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local node = ts_utils.get_node_at_cursor()
  if not node then
    return false
  end
  local types = { 'start_tag', 'self_closing_tag', 'directive_attribute' }
  return vim.tbl_contains(types, node:type())
end

return M
