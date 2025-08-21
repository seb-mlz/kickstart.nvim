-- lua/custom/commands/i18n.lua
local i18n_utils = require 'custom.modules.i18n'

-- Command to add a new translation key
vim.api.nvim_create_user_command('I18nAdd', function(opts)
  local key = opts.args
  if key == '' then
    vim.ui.input({ prompt = 'Enter translation key: ' }, function(input_key)
      if input_key and input_key ~= '' then
        i18n_utils.add_translation_key(input_key)
      end
    end)
  else
    i18n_utils.add_translation_key(key)
  end
end, {
  nargs = '?',
  desc = 'Add a new translation key to i18n files',
})

-- Command to update an existing translation key
vim.api.nvim_create_user_command('I18nUpdate', function(opts)
  local key = opts.args
  if key == '' then
    vim.ui.input({ prompt = 'Enter translation key to update: ' }, function(input_key)
      if input_key and input_key ~= '' then
        i18n_utils.update_translation_key(input_key)
      end
    end)
  else
    i18n_utils.update_translation_key(key)
  end
end, {
  nargs = '?',
  desc = 'Update an existing translation key in i18n files',
})

-- Command to list all translation keys
vim.api.nvim_create_user_command('I18nList', function()
  i18n_utils.list_translation_keys()
end, {
  desc = 'List all translation keys',
})

-- Command to validate JSON files
vim.api.nvim_create_user_command('I18nValidate', function()
  i18n_utils.validate_json_files()
end, {
  desc = 'Validate i18n JSON files',
})
