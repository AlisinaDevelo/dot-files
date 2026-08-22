local function env(name)
  local value = vim.env[name]
  return value ~= nil and value ~= "" and value or nil
end

local function default_provider()
  if env("AVANTE_PROVIDER") then
    return env("AVANTE_PROVIDER")
  end
  if vim.fn.executable("opencode") == 1 then
    return "opencode"
  end
  if vim.fn.executable("kimi") == 1 then
    return "kimi-cli"
  end
  if env("ANTHROPIC_API_KEY") then
    return "claude"
  end
  if env("OPENAI_API_KEY") then
    return "openai"
  end
  return "copilot"
end

return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        yaml = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        markdown = true,
        ["."] = false,
      },
    },
  },

  {
    "yetone/avante.nvim",
    opts = function(_, opts)
      opts.provider = default_provider()
      opts.auto_suggestions_provider = "copilot"
      opts.acp_providers = vim.tbl_deep_extend("force", opts.acp_providers or {}, {
        opencode = {
          command = env("OPENCODE_BIN") or "opencode",
          args = { "acp" },
        },
        ["kimi-cli"] = {
          command = env("KIMI_BIN") or "kimi",
          args = { "acp" },
        },
      })
      opts.providers = vim.tbl_deep_extend("force", opts.providers or {}, {
        claude = {
          model = env("AVANTE_CLAUDE_MODEL"),
          timeout = 30000,
        },
        openai = {
          model = env("AVANTE_OPENAI_MODEL"),
          timeout = 30000,
        },
        ollama = {
          endpoint = env("AVANTE_OLLAMA_ENDPOINT") or "http://127.0.0.1:11434",
          model = env("AVANTE_OLLAMA_MODEL") or "qwen2.5-coder",
          is_env_set = require("avante.providers.ollama").check_endpoint_alive,
          extra_request_body = {
            options = {
              temperature = 0,
              num_ctx = 32768,
              keep_alive = "5m",
            },
          },
        },
      })
      opts.behaviour = vim.tbl_deep_extend("force", opts.behaviour or {}, {
        auto_suggestions = false,
        auto_set_keymaps = false,
        auto_apply_diff_after_generation = false,
        auto_approve_tool_permissions = false,
        support_paste_from_clipboard = true,
      })
      opts.selection = vim.tbl_deep_extend("force", opts.selection or {}, {
        hint_display = "none",
      })
      opts.hints = { enabled = true }
      opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
        position = "right",
        wrap = true,
        width = 32,
        sidebar_header = { enabled = true, align = "center", rounded = true },
        input = { prefix = "> ", height = 8 },
        edit = { border = "rounded", start_insert = true },
        ask = { floating = false, start_insert = true, border = "rounded" },
      })
    end,
    keys = {
      { "<leader>aa", "<cmd>AvanteAsk<cr>", desc = "AI: ask", mode = { "n", "v" } },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "AI: edit selection", mode = { "n", "v" } },
      { "<leader>am", "<cmd>AvanteModels<cr>", desc = "AI: choose model" },
      { "<leader>ap", "<cmd>AvanteSwitchProvider<cr>", desc = "AI: choose provider" },
      { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "AI: refresh" },
      { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "AI: toggle sidebar" },
      { "<leader>ac", "<cmd>AvanteClear<cr>", desc = "AI: clear chat" },
    },
  },
}
