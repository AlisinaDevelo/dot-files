return {
  -- GitHub Copilot: inline ghost-text completions while you type
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>", -- Alt+l accepts the whole suggestion
          accept_word = "<M-w>", -- Alt+w accepts one word at a time
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false }, -- use Avante for panel-style chat
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

  -- Avante: Cursor-style AI coding assistant inside Neovim
  -- Supports Claude (Anthropic), GPT (OpenAI), Copilot, and local Ollama models.
  -- Set ANTHROPIC_API_KEY or OPENAI_API_KEY in your shell env.
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    -- cross-platform build: requires `make` on macOS/Linux, PowerShell on Windows
    build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
    opts = {
      provider = "claude", -- switch with :AvanteSwitchProvider
      auto_suggestions_provider = "copilot",
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-6", -- or claude-opus-4-7 for max quality
        timeout = 30000,
        temperature = 0,
        max_tokens = 8192,
      },
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o",
        timeout = 30000,
        temperature = 0,
        max_tokens = 8192,
      },
      ollama = {
        -- local models — run: ollama pull qwen2.5-coder
        endpoint = "http://127.0.0.1:11434",
        model = "qwen2.5-coder",
      },
      behaviour = {
        auto_suggestions = false, -- inline suggestions handled by copilot.lua
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
      },
      hints = { enabled = true },
      windows = {
        position = "right",
        wrap = true,
        width = 32,
        sidebar_header = { enabled = true, align = "center", rounded = true },
        input = { prefix = "> ", height = 8 },
        edit = { border = "rounded", start_insert = true },
        ask = { floating = false, start_insert = true, border = "rounded" },
      },
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteAsk<cr>", desc = "AI: ask", mode = { "n", "v" } },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "AI: edit selection", mode = { "n", "v" } },
      { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "AI: refresh" },
      { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "AI: toggle sidebar" },
      { "<leader>ac", "<cmd>AvanteClear<cr>", desc = "AI: clear chat" },
    },
  },
}
