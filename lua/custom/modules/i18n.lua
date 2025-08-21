-- lua/custom/modules/i18n.lua
local M = {}

-- Configuration
M.config = {
  i18n_dir = 'i18n/lang',
  languages = { 'fr', 'en' },
  script_path = vim.fn.stdpath 'config' .. '/lua/custom/scripts/i18n-manager.js',
}

-- Helper function to get project root
local function get_project_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':p:h')

  -- Look for package.json, nuxt.config.js, or .git to determine project root
  local markers = { 'package.json', 'nuxt.config.js', 'nuxt.config.ts', '.git' }

  local function find_root(path)
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(path .. '/' .. marker) == 1 or vim.fn.isdirectory(path .. '/' .. marker) == 1 then
        return path
      end
    end
    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then
      return nil
    end
    return find_root(parent)
  end

  return find_root(current_dir) or vim.fn.getcwd()
end

-- Helper function to run bun script
local function run_bun_script(action, key, translations)
  local project_root = get_project_root()
  local script_path = M.config.script_path

  -- Build command arguments
  local args = { 'bun', script_path, action, key }

  -- Add translations if provided
  if translations then
    for lang, translation in pairs(translations) do
      table.insert(args, lang .. ':' .. translation)
    end
  end

  -- Add project root
  table.insert(args, '--root=' .. project_root)

  -- Execute command
  local result = vim.fn.systemlist(args)
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    return true, result
  else
    return false, result
  end
end

-- Add a new translation key
function M.add_translation_key(key)
  if not key or key == '' then
    vim.notify('Translation key cannot be empty', vim.log.levels.ERROR)
    return
  end

  -- Check if key already exists
  local success, result = run_bun_script('check', key)
  if success and #result > 0 and result[1] == 'exists' then
    vim.notify('Key "' .. key .. '" already exists. Use I18nUpdate to modify it.', vim.log.levels.WARN)
    return
  end

  local translations = {}

  -- Get French translation
  vim.ui.input({
    prompt = 'French translation for "' .. key .. '": ',
  }, function(fr_translation)
    if not fr_translation or fr_translation == '' then
      vim.notify('French translation is required', vim.log.levels.ERROR)
      return
    end

    translations.fr = fr_translation

    -- Get English translation
    vim.ui.input({
      prompt = 'English translation for "' .. key .. '": ',
    }, function(en_translation)
      if not en_translation or en_translation == '' then
        vim.notify('English translation is required', vim.log.levels.ERROR)
        return
      end

      translations.en = en_translation

      -- Add translations using bun script
      local success, result = run_bun_script('add', key, translations)
      if success then
        vim.notify('Translation key "' .. key .. '" added successfully', vim.log.levels.INFO)
      else
        vim.notify('Error adding translation: ' .. table.concat(result, '\n'), vim.log.levels.ERROR)
      end
    end)
  end)
end

-- Update an existing translation key
function M.update_translation_key(key)
  if not key or key == '' then
    vim.notify('Translation key cannot be empty', vim.log.levels.ERROR)
    return
  end

  -- Check if key exists and get current values
  local success, result = run_bun_script('get', key)
  if not success or #result == 0 then
    vim.notify('Key "' .. key .. '" not found', vim.log.levels.ERROR)
    return
  end

  -- Parse current translations (format: "lang:translation")
  local current_translations = {}
  for _, line in ipairs(result) do
    local lang, translation = line:match '(%w+):(.+)'
    if lang and translation then
      current_translations[lang] = translation
    end
  end

  local translations = {}

  -- Update French translation
  vim.ui.input({
    prompt = 'French translation for "' .. key .. '" (' .. (current_translations.fr or '') .. '): ',
  }, function(fr_translation)
    if fr_translation and fr_translation ~= '' then
      translations.fr = fr_translation
    elseif current_translations.fr then
      translations.fr = current_translations.fr
    else
      vim.notify('French translation is required', vim.log.levels.ERROR)
      return
    end

    -- Update English translation
    vim.ui.input({
      prompt = 'English translation for "' .. key .. '" (' .. (current_translations.en or '') .. '): ',
    }, function(en_translation)
      if en_translation and en_translation ~= '' then
        translations.en = en_translation
      elseif current_translations.en then
        translations.en = current_translations.en
      else
        vim.notify('English translation is required', vim.log.levels.ERROR)
        return
      end

      -- Update translations using bun script
      local success, result = run_bun_script('update', key, translations)
      if success then
        vim.notify('Translation key "' .. key .. '" updated successfully', vim.log.levels.INFO)
      else
        vim.notify('Error updating translation: ' .. table.concat(result, '\n'), vim.log.levels.ERROR)
      end
    end)
  end)
end

-- List all translation keys
function M.list_translation_keys()
  local success, result = run_bun_script 'list'
  if success then
    if #result == 0 then
      vim.notify('No translation keys found', vim.log.levels.INFO)
    else
      -- Create a new buffer to show the keys
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'json')

      -- Open in a new window
      vim.cmd 'split'
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_buf_set_name(buf, 'I18n Keys')
    end
  else
    vim.notify('Error listing translation keys: ' .. table.concat(result, '\n'), vim.log.levels.ERROR)
  end
end

-- Validate JSON files
function M.validate_json_files()
  local success, result = run_bun_script 'validate'
  if success then
    vim.notify('All i18n JSON files are valid', vim.log.levels.INFO)
  else
    vim.notify('JSON validation errors:\n' .. table.concat(result, '\n'), vim.log.levels.ERROR)
  end
end

return M
