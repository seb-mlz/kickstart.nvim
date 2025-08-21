-- ~/.config/nvim/lua/custom/modules/php_utils.lua
local M = {}

-- Template rendering function
local function render_template(template_path, vars)
  local config_path = vim.fn.stdpath 'config'
  local full_path = config_path .. '/templates/' .. template_path

  if not vim.fn.filereadable(full_path) then
    error('Template not found: ' .. full_path)
    return nil
  end

  local template_lines = vim.fn.readfile(full_path)
  local content = table.concat(template_lines, '\n')

  for key, value in pairs(vars or {}) do
    content = content:gsub('{{' .. key .. '}}', value)
  end

  return content
end

-- Enhanced namespace detection
local function get_namespace()
  local composer_file = vim.fn.getcwd() .. '/composer.json'

  if vim.fn.filereadable(composer_file) then
    local composer_content = vim.fn.readfile(composer_file)
    local composer_string = table.concat(composer_content, '\n')
    local namespace = composer_string:match '"autoload".-"psr%-4".-"([^"]+)\\\\"'
    if namespace then
      return namespace
    end
  end

  return 'App'
end

-- Get project root
local function get_project_root()
  local current_dir = vim.fn.getcwd()
  local composer_file = current_dir .. '/composer.json'

  if vim.fn.filereadable(composer_file) then
    return current_dir
  end

  return current_dir
end

-- Convert path to namespace (e.g., "User/Profile" -> "User\\Profile")
local function path_to_namespace(path)
  if not path or path == '' then
    return ''
  end

  -- Remove leading/trailing slashes and convert to namespace
  local clean_path = path:gsub('^/+', ''):gsub('/+$', '')
  if clean_path == '' then
    return ''
  end

  return '\\' .. clean_path:gsub('/', '\\')
end

-- Get user input for subdirectory
local function get_subdirectory(base_type)
  -- Show current directory for context
  local current_dir = vim.fn.getcwd()
  print('Current directory: ' .. current_dir)

  -- Prompt for subdirectory
  local subdirectory = vim.fn.input {
    prompt = 'Subdirectory (e.g., User/Profile or just User): ',
    default = '',
    completion = 'dir',
  }

  -- Clean up input
  if subdirectory then
    subdirectory = subdirectory:gsub('^%s+', ''):gsub('%s+$', '') -- trim whitespace
    subdirectory = subdirectory:gsub('^/+', ''):gsub('/+$', '') -- trim slashes
  end

  return subdirectory or ''
end

-- Command pair creation with subdirectory support
function M.create_command_pair(command_name)
  local subdirectory = get_subdirectory 'Command'

  local project_root = get_project_root()
  local base_namespace = get_namespace()

  -- Build paths
  local command_dir = project_root .. '/src/Command'
  if subdirectory ~= '' then
    command_dir = command_dir .. '/' .. subdirectory
  end

  local command_path = command_dir .. '/' .. command_name .. 'Command.php'
  local handler_path = command_dir .. '/' .. command_name .. 'CommandHandler.php'

  -- Build namespace
  local namespace = base_namespace .. '\\Command'
  if subdirectory ~= '' then
    namespace = namespace .. path_to_namespace(subdirectory)
  end

  -- Template variables
  local vars = {
    namespace = namespace,
    name = command_name,
    name_lower = command_name:lower(),
  }

  -- Render templates
  local command_content = render_template('php/command.php', vars)
  local handler_content = render_template('php/command_handler.php', vars)

  if not command_content or not handler_content then
    print 'Failed to render templates'
    return
  end

  -- Create directory and files
  vim.fn.mkdir(command_dir, 'p')
  vim.fn.writefile(vim.split(command_content, '\n'), command_path)
  vim.fn.writefile(vim.split(handler_content, '\n'), handler_path)

  -- Open the command file
  vim.cmd('edit ' .. command_path)

  local display_path = 'Command'
  if subdirectory ~= '' then
    display_path = display_path .. '/' .. subdirectory
  end

  print('✅ Created ' .. command_name .. 'Command and ' .. command_name .. 'CommandHandler in ' .. display_path)
end

-- Advanced versions that accept subdirectory as parameter
function M.create_command_pair_at(command_name, subdirectory)
  local project_root = get_project_root()
  local base_namespace = get_namespace()

  -- Clean subdirectory input
  if subdirectory then
    subdirectory = subdirectory:gsub('^%s+', ''):gsub('%s+$', '')
    subdirectory = subdirectory:gsub('^/+', ''):gsub('/+$', '')
  end

  -- Build paths
  local command_dir = project_root .. '/src/Command'
  if subdirectory and subdirectory ~= '' then
    command_dir = command_dir .. '/' .. subdirectory
  end

  local command_path = command_dir .. '/' .. command_name .. 'Command.php'
  local handler_path = command_dir .. '/' .. command_name .. 'CommandHandler.php'

  -- Build namespace
  local namespace = base_namespace .. '\\Command'
  if subdirectory and subdirectory ~= '' then
    namespace = namespace .. path_to_namespace(subdirectory)
  end

  local vars = {
    namespace = namespace,
    name = command_name,
    name_lower = command_name:lower(),
  }

  local command_content = render_template('php/command.php', vars)
  local handler_content = render_template('php/command_handler.php', vars)

  if not command_content or not handler_content then
    print 'Failed to render templates'
    return
  end

  vim.fn.mkdir(command_dir, 'p')
  vim.fn.writefile(vim.split(command_content, '\n'), command_path)
  vim.fn.writefile(vim.split(handler_content, '\n'), handler_path)
  vim.cmd('edit ' .. command_path)

  local display_path = 'Command'
  if subdirectory and subdirectory ~= '' then
    display_path = display_path .. '/' .. subdirectory
  end

  print('✅ Created ' .. command_name .. 'Command and ' .. command_name .. 'CommandHandler in ' .. display_path)
end

-- List available templates
function M.list_templates()
  local config_path = vim.fn.stdpath 'config'
  local templates_dir = config_path .. '/templates/php'

  if vim.fn.isdirectory(templates_dir) then
    local templates = vim.fn.readdir(templates_dir)
    print '📁 Available PHP templates:'
    for _, template in ipairs(templates) do
      print('  • ' .. template:gsub('%.php$', ''))
    end
  else
    print('❌ Templates directory not found: ' .. templates_dir)
  end
end

-- Minimal LSP property detection (test function)
function M.list_properties_lsp()
  -- Check if LSP is available
  local clients = vim.lsp.get_clients { bufnr = 0 }

  if #clients == 0 then
    print '❌ No LSP client available for current buffer'
    print '   Make sure you have a PHP LSP server running (Intelephense, phpactor, etc.)'
    return
  end

  print('🔍 Found ' .. #clients .. ' LSP client(s). Requesting document symbols...')

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
  }

  -- Request document symbols from LSP
  vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result, ctx)
    if err then
      print('❌ LSP error: ' .. vim.inspect(err))
      return
    end

    if not result or #result == 0 then
      print '❌ No symbols returned from LSP'
      return
    end

    print '\n📋 LSP Document Symbols:'
    print '═══════════════════════'

    -- Parse LSP symbols
    for _, symbol in ipairs(result) do
      print(string.format('🏷️  %s (%s)', symbol.name, vim.lsp.protocol.SymbolKind[symbol.kind] or symbol.kind))

      if symbol.kind == vim.lsp.protocol.SymbolKind.Class then
        print('   📁 Class found: ' .. symbol.name)

        -- Look for properties in class children
        if symbol.children then
          print '   🔍 Scanning for properties...'

          for _, child in ipairs(symbol.children) do
            local kind_name = vim.lsp.protocol.SymbolKind[child.kind] or tostring(child.kind)

            if child.kind == vim.lsp.protocol.SymbolKind.Property or child.kind == vim.lsp.protocol.SymbolKind.Field then
              local prop_name = child.name:gsub('^%$', '') -- Remove $ prefix if present
              local detail = child.detail or 'no type info'
              local line_num = child.range.start.line + 1

              print(string.format('   ✅ Property: %s (line %d) - %s', prop_name, line_num, detail))
            else
              -- Show other class members for debugging
              print(string.format('   ➡️  %s: %s (%s)', kind_name, child.name, child.detail or ''))
            end
          end
        else
          print '   ⚠️  No children found in class'
        end
      end
    end
  end)
end

return M
