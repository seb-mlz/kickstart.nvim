-- lua/custom/modules/i18n.lua
local M = {}

-- Configuration
M.config = {
  i18n_dir = 'i18n/lang',
  languages = { 'fr', 'en' },
  script_path = vim.fn.stdpath 'config' .. '/lua/custom/scripts/i18n-manager.js',
}

-- UI Configuration
M.ui_config = {
  width = 80,
  height = 20,
  border = 'rounded',
  title_pos = 'center',
}

-- Helper function to create centered floating window
local function create_popup(title, lines, opts)
  opts = opts or {}
  local width = opts.width or M.ui_config.width
  local height = opts.height or math.min(#lines + 4, M.ui_config.height)

  -- Calculate position for centering
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Window options
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = M.ui_config.border,
    title = title,
    title_pos = M.ui_config.title_pos,
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', opts.modifiable ~= false)
  vim.api.nvim_buf_set_option(buf, 'filetype', opts.filetype or 'text')

  -- Add close keymap
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<cr>', { noremap = true, silent = true })

  return buf, win
end

-- Helper function to show notification popup
local function show_notification(message, level)
  level = level or 'info'
  local icon = level == 'error' and '✗' or level == 'warn' and '⚠' or '✓'
  local title = ' ' .. icon .. ' i18n ' .. string.upper(level) .. ' '

  local lines = {}
  for line in message:gmatch '[^\r\n]+' do
    table.insert(lines, line)
  end

  local buf, win = create_popup(title, lines, {
    width = math.max(40, #message + 10),
    height = #lines + 2,
    modifiable = false,
  })

  vim.cmd 'stopinsert'
  vim.api.nvim_set_current_win(win)

  -- Auto-close after 3 seconds for success messages
  if level == 'info' then
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, 3000)
  end

  -- Set colors based on level
  local hl_group = level == 'error' and 'ErrorMsg' or level == 'warn' and 'WarningMsg' or 'MoreMsg'
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:' .. hl_group)
end

-- Helper function to create input popup
local function create_input_popup(prompt, default_value, callback)
  local lines = { '', '  ' .. prompt, '' }
  if default_value then
    table.insert(lines, '  Current: ' .. default_value)
    table.insert(lines, '')
  end
  table.insert(lines, '  Enter your text below:')
  table.insert(lines, '  ─────────────────────────')
  table.insert(lines, default_value or '')

  local buf, win = create_popup(' 📝 i18n Input ', lines, {
    width = 60,
    height = #lines + 2,
    filetype = 'text',
  })

  -- Position cursor on input line
  vim.api.nvim_win_set_cursor(win, { #lines, #(default_value or '') })

  -- Enter insert mode
  vim.cmd 'startinsert!'

  -- Set up keymaps for input
  local function submit()
    local input_line = vim.api.nvim_buf_get_lines(buf, #lines - 1, #lines, false)[1]
    vim.api.nvim_win_close(win, true)
    callback(input_line)
  end

  local function cancel()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end

  -- Keymaps
  vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
    noremap = true,
    silent = true,
    callback = submit,
  })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    noremap = true,
    silent = true,
    callback = submit,
  })
  vim.api.nvim_buf_set_keymap(buf, 'i', '<C-c>', '', {
    noremap = true,
    silent = true,
    callback = cancel,
  })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    noremap = true,
    silent = true,
    callback = cancel,
  })
end
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
    show_notification('Translation key cannot be empty', 'error')
    return
  end

  -- Check if key already exists
  local success, result = run_bun_script('check', key)
  if success and #result > 0 and result[1] == 'exists' then
    show_notification('Key "' .. key .. '" already exists. Use I18nUpdate to modify it.', 'warn')
    return
  end

  local translations = {}

  -- Get French translation with popup
  create_input_popup('French translation for "' .. key .. '":', nil, function(fr_translation)
    if not fr_translation or fr_translation == '' then
      show_notification('French translation is required', 'error')
      return
    end

    translations.fr = fr_translation

    -- Get English translation with popup
    create_input_popup('English translation for "' .. key .. '":', nil, function(en_translation)
      if not en_translation or en_translation == '' then
        show_notification('English translation is required', 'error')
        return
      end

      translations.en = en_translation

      -- Add translations using bun script
      local success, result = run_bun_script('add', key, translations)
      if success then
        show_notification('Translation key "' .. key .. '" added successfully! 🎉', 'info')
      else
        show_notification('Error adding translation:\n' .. table.concat(result, '\n'), 'error')
      end
    end)
  end)
end

-- Update an existing translation key
function M.update_translation_key(key)
  if not key or key == '' then
    show_notification('Translation key cannot be empty', 'error')
    return
  end

  -- Check if key exists and get current values
  local success, result = run_bun_script('get', key)
  if not success or #result == 0 then
    show_notification('Key "' .. key .. '" not found', 'error')
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

  -- Update French translation with popup
  create_input_popup('French translation for "' .. key .. '":', current_translations.fr, function(fr_translation)
    if fr_translation and fr_translation ~= '' then
      translations.fr = fr_translation
    elseif current_translations.fr then
      translations.fr = current_translations.fr
    else
      show_notification('French translation is required', 'error')
      return
    end

    -- Update English translation with popup
    create_input_popup('English translation for "' .. key .. '":', current_translations.en, function(en_translation)
      if en_translation and en_translation ~= '' then
        translations.en = en_translation
      elseif current_translations.en then
        translations.en = current_translations.en
      else
        show_notification('English translation is required', 'error')
        return
      end

      -- Update translations using bun script
      local success, result = run_bun_script('update', key, translations)
      if success then
        show_notification('Translation key "' .. key .. '" updated successfully! ✨', 'info')
      else
        show_notification('Error updating translation:\n' .. table.concat(result, '\n'), 'error')
      end
    end)
  end)
end

-- List all translation keys
function M.list_translation_keys()
  local success, result = run_bun_script 'list'
  if success then
    if #result == 0 then
      show_notification('No translation keys found', 'warn')
    else
      -- Add header
      local display_lines = {
        '🌍 i18n Translation Keys',
        '═══════════════════════════════════════════════════════════════════════════════',
        '',
      }

      -- Add each translation line with better formatting
      for _, line in ipairs(result) do
        local key, rest = line:match '([^:]+):(.*)'
        if key and rest then
          table.insert(display_lines, '🔑 ' .. key)
          -- Parse translations
          for lang_translation in rest:gmatch '(%w+="[^"]*")' do
            local lang, translation = lang_translation:match '(%w+)="([^"]*)"'
            if lang and translation then
              local flag = lang == 'fr' and '🇫🇷' or lang == 'en' and '🇬🇧' or '🌐'
              table.insert(display_lines, '   ' .. flag .. ' ' .. lang .. ': ' .. translation)
            end
          end
          table.insert(display_lines, '')
        end
      end

      -- Create popup with nice formatting
      local buf, win = create_popup(' 🌍 i18n Translation Keys ', display_lines, {
        width = 100,
        height = math.min(#display_lines + 4, 30),
        modifiable = false,
        filetype = 'markdown',
      })

      -- Add syntax highlighting
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'syntax match i18nKey /🔑.*$/'
        vim.cmd 'syntax match i18nFlag /🇫🇷\\|🇬🇧\\|🌐/'
        vim.cmd 'hi i18nKey guifg=#61AFEF gui=bold'
        vim.cmd 'hi i18nFlag guifg=#E06C75'
      end)
    end
  else
    show_notification('Error listing translation keys:\n' .. table.concat(result, '\n'), 'error')
  end
end

-- Validate JSON files
function M.validate_json_files()
  local success, result = run_bun_script 'validate'
  if success then
    show_notification('All i18n JSON files are valid! 🎉', 'info')
  else
    show_notification('JSON validation errors:\n' .. table.concat(result, '\n'), 'error')
  end
end

return M
