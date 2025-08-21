-- ~/.config/nvim/lua/custom/commands.lua (or add to init.lua)

local php_utils = require 'custom.modules.php_utils'

-- Interactive commands (with subdirectory prompt)
vim.api.nvim_create_user_command('CreateCommand', function(opts)
  php_utils.create_command_pair(opts.args)
end, {
  nargs = 1,
  desc = 'Create Command and CommandHandler pair (with subdirectory prompt)',
})

-- Direct commands (specify subdirectory as parameter)
vim.api.nvim_create_user_command('CreateCommandAt', function(opts)
  local args = vim.split(opts.args, ' ', { trimempty = true })
  if #args < 1 then
    print 'Usage: CreateCommandAt <CommandName> [subdirectory]'
    return
  end

  local command_name = args[1]
  local subdirectory = args[2] or ''

  php_utils.create_command_pair_at(command_name, subdirectory)
end, {
  nargs = '+',
  desc = 'Create Command pair at specific path: CreateCommandAt <Name> [subdirectory]',
})

-- Utility command
vim.api.nvim_create_user_command('ListPhpTemplates', function()
  php_utils.list_templates()
end, {
  desc = 'List available PHP templates',
})

vim.api.nvim_create_user_command('ListPropertiesLsp', function()
  php_utils.list_properties_lsp()
end, {
  desc = 'List PHP properties via LSP (test command)',
})
