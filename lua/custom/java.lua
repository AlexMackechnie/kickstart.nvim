local M = {}

function M.setup()
  local function setup_java()
    local jdtls_ok, jdtls = pcall(require, 'jdtls')
    if not jdtls_ok then
      vim.notify('JDTLS not found, please install nvim-jdtls', vim.log.levels.ERROR)
      return
    end

    -- Find the Java executable
    local function get_java_executable()
      local java_home = os.getenv('JAVA_HOME')
      if java_home then
        return java_home .. '/bin/java'
      end
      return 'java'  -- Fall back to PATH
    end

    local home = os.getenv('HOME')
    -- Project specific workspace
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    local workspace_dir = home .. '/.local/share/eclipse/' .. project_name

    -- Get OS specific config
    local config_dir
    if vim.fn.has('mac') == 1 then
      config_dir = 'config_mac'
    elseif vim.fn.has('unix') == 1 then
      config_dir = 'config_linux'
    else
      config_dir = 'config_win'
    end

    local config = {
      cmd = {
        get_java_executable(),
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-jar', vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration', home .. '/.local/share/nvim/mason/packages/jdtls/' .. config_dir,
        '-data', workspace_dir,
      },

      -- root_dir = require('jdtls.setup').find_root({'.git', 'gradlew', 'mvnw', 'build.gradle', 'pom.xml'}),
      root_dir = require('jdtls.setup').find_root({'build.gradle'}),

      settings = {
        java = {
          eclipse = {
            downloadSources = true,
          },
          maven = {
            downloadSources = true,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          referencesCodeLens = {
            enabled = true,
          },
          references = {
            includeDecompiledSources = true,
          },
          inlayHints = {
            parameterNames = {
              enabled = "all",
            },
          },
          format = {
            enabled = true,
          },
        },
        signatureHelp = { enabled = true },
        completion = {
          favoriteStaticMembers = {
            "org.junit.Assert.*",
            "org.junit.Assume.*",
            "org.junit.jupiter.api.Assertions.*",
            "org.junit.jupiter.api.Assumptions.*",
            "org.junit.jupiter.api.DynamicContainer.*",
            "org.junit.jupiter.api.DynamicTest.*",
          },
        },
        contentProvider = { preferred = 'fernflower' },
        extendedClientCapabilities = jdtls.extendedClientCapabilities,
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
      },

      flags = {
        allow_incremental_sync = true,
      },

      init_options = {
        bundles = {},
        extendedClientCapabilities = jdtls.extendedClientCapabilities,
      },
    }

    -- This starts a new client & server
    jdtls.start_or_attach(config)
  end

  -- Create an augroup for Java files
  vim.api.nvim_create_augroup("jdtls_setup", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    group = "jdtls_setup",
    callback = setup_java,
  })
end

return M
