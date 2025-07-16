local M = {}

local function write_file(path, content)
  local file = io.open(path, 'w')
  if file then
    file:write(content)
    file:close()
  else
    print('❌ Failed to write file: ' .. path)
  end
end

M.create_cqrs_files = function()
  vim.ui.input({ prompt = 'Enter Directory (e.g. User): ' }, function(directory)
    if not directory or directory == '' then
      print '🚫 No directory provided.'
      return
    end

    vim.ui.input({ prompt = 'Enter Action Name (e.g. Create): ' }, function(entity)
      if not entity or entity == '' then
        print '🚫 No entity name provided.'
        return
      end

      -- Detect project root
      local root = vim.fs.dirname(vim.fs.find({ '.git', 'composer.json' }, { upward = true })[1])
      if not root then
        print '❌ Could not determine project root.'
        return
      end

      local base = root .. '/src/Command/' .. directory
      local cmd_file = base .. '/' .. entity .. 'Command.php'
      local handler_file = base .. '/' .. entity .. 'CommandHandler.php'

      os.execute('mkdir -p ' .. base)

      local cmd_content = [[
<?php

declare(strict_types=1);

namespace App\Command\]] .. directory .. [[;

class ]] .. entity .. [[Command
{
    // TODO: Add properties and constructor
}
]]

      local handler_content = [[
<?php

declare(strict_types=1);

namespace App\Command\]] .. directory .. [[;

class ]] .. entity .. [[CommandHandler
{
    public function __invoke(]] .. entity .. [[Command $command): void
    {
        // TODO: Implement handler logic
    }
}
]]

      write_file(cmd_file, cmd_content)
      write_file(handler_file, handler_content)

      -- Open files
      vim.cmd('edit ' .. cmd_file)
      vim.cmd('vsplit ' .. handler_file)

      print('✅ Created ' .. entity .. 'Command and CommandHandler in ' .. directory)
    end)
  end)
end

vim.api.nvim_create_user_command('CreateCommand', M.create_cqrs_files, {})

return M
