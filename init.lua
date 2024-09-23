-- 跨平台的基本設定
vim.g.mapleader = " "  -- 設定領導鍵為空格
vim.opt.number = true  -- 顯示行號
vim.opt.relativenumber = true  -- 顯示相對行號
vim.opt.expandtab = true  -- 用空格代替 Tab 符
vim.opt.tabstop = 4  -- 設定 Tab 符寬度為 4 個空格
vim.opt.shiftwidth = 4  -- 自動縮進時使用 4 個空格
vim.opt.smartindent = true  -- 智能縮進
vim.opt.wrap = false  -- 不自動換行
vim.opt.ignorecase = true  -- 搜索時忽略大小寫
vim.opt.smartcase = true  -- 搜索時若包含大寫字母，則區分大小寫
vim.opt.termguicolors = false  -- 不使用真實色彩
vim.opt.signcolumn = "yes"  -- 永遠顯示符號欄
vim.opt.updatetime = 250  -- 更新時間為 250 毫秒
vim.opt.timeoutlen = 300  -- 映射超時時間為 300 毫秒

-- 跨平台剪貼簿設定
vim.opt.clipboard = "unnamedplus"  -- 使用系統剪貼簿

-- 設定正確的 Python 路徑（如果需要）
if vim.fn.has("win32") == 1 then
  vim.g.python3_host_prog = vim.fn.expand("~/AppData/Local/Programs/Python/Python39/python.exe")
elseif vim.fn.has("unix") == 1 then
  vim.g.python3_host_prog = "/usr/bin/python3"
end

-- 安裝 lazy.nvim（跨平台相容）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",  -- 最新穩定版本
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 套件設定
require("lazy").setup({
  -- Mason.nvim（跨平台安裝 LSP）
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",  -- 自動更新 Mason 套件
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", -- lua
          --"ts_ls", -- javascript
          --"clangd", -- c/c++
          --"marksman", -- markdown
          --"pyright", -- python
          --"rust_analyzer", -- rust
        },  -- 自動安裝指定的 LSP
        automatic_installation = true,  -- 自動安裝未安裝的 LSP
      })
    end,
  },

  -- Treesitter（跨平台設定）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",  -- 自動更新 Treesitter 語法資料
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "vim",
          --"vimdoc",
          --"python",
          --"javascript",
          --"c",
          --"cpp",
          --"rust",
          },  -- 安裝指定的解析器
        auto_install = false,  -- 不自動安裝缺少的解析器
        highlight = { enable = true },  -- 啟用語法高亮
        indent = { enable = true },  -- 啟用智能縮進
      })
    end,
  },

  -- LSP 設定
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP 的補全來源
      "hrsh7th/nvim-cmp",  -- 自動補全引擎
      "L3MON4D3/LuaSnip",  -- Snippet 引擎
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- 設置 Lua LSP（跨平台設定）
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',  -- 使用 LuaJIT 作為虛擬機
            },
            diagnostics = {
              globals = {'vim'},  -- 認可全域變數 vim
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),  -- 自動加載工作區
              checkThirdParty = false,  -- 不檢查第三方程式碼
            },
            telemetry = {
              enable = false,  -- 關閉遙測
            },
          },
        },
      })

      -- 跨平台快捷鍵設定
      local opts = { noremap=true, silent=true }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)  -- 跳轉到定義
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)  -- 顯示懸浮文件
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)  -- 執行代碼動作
    end,
  },

  -- 自動補齊
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",  -- 緩衝區補全來源
      "hrsh7th/cmp-path",  -- 路徑補全來源
      "hrsh7th/cmp-nvim-lsp",  -- LSP 補全來源
      "saadparwaiz1/cmp_luasnip",  -- Snippet 補全來源
      "L3MON4D3/LuaSnip",  -- Snippet 引擎
      "rafamadriz/friendly-snippets",  -- 預設的 Snippet
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()  -- 載入 VSCode 風格的 Snippet

      -- 定義一個函數，檢查光標前是否有文字
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and
          vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)  -- 展開 Snippet
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),  -- Ctrl-n 選擇下一個項目
          ["<C-p>"] = cmp.mapping.select_prev_item(),  -- Ctrl-p 選擇上一個項目
          ["<C-Space>"] = cmp.mapping.complete(),  -- Ctrl-Space 呼叫補全
          ["<CR>"] = cmp.mapping.confirm({ select = true }),  -- Enter 確認選擇

          -- 自定義 Tab 和 Shift-Tab 行為
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })  -- 補全選單可見，確認選擇
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()  -- 有可跳轉的 Snippet，展開或跳轉
            elseif has_words_before() then
              cmp.complete()  -- 光標前有文字，呼叫補全
            else
              fallback()  -- 否則，執行縮排
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)  -- Shift-Tab 跳回上一個佔位符
            else
              fallback()  -- 否則，執行默認行為
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },  -- 來自 LSP 的補全
          { name = "luasnip" },  -- 來自 Snippet 的補全
          { name = "buffer" },  -- 來自當前緩衝區的補全
          { name = "path" },  -- 來自檔案路徑的補全
        }),
      })

      -- 與 nvim-autopairs 進行整合
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on(
        "confirm_done",
        cmp_autopairs.on_confirm_done()
      )
    end,
  },

  -- 檔案瀏覽器（使用跨平台相容的設定）
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",  -- 必需的函式庫
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },  -- FZF 支援
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git" },  -- 忽略的目錄
        },
      })
      telescope.load_extension('fzf')  -- 載入 FZF 擴充

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})  -- 查找檔案
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})  -- 全域搜尋
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})  -- 列出緩衝區
    end,
  },

  -- 新增括弧配對插件
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  -- LuaSnip 插件（Snippet 引擎）
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",  -- 預設的 Snippet 集合
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
})

-- 其他跨平台快捷鍵設定
vim.keymap.set("n", "<leader>w", ":w<CR>")  -- 快速保存
vim.keymap.set("n", "<leader>q", ":q<CR>")  -- 快速退出
vim.keymap.set("n", "<C-h>", "<C-w>h")  -- 移動到左邊的窗口
vim.keymap.set("n", "<C-j>", "<C-w>j")  -- 移動到下邊的窗口
vim.keymap.set("n", "<C-k>", "<C-w>k")  -- 移動到上邊的窗口
vim.keymap.set("n", "<C-l>", "<C-w>l")  -- 移動到右邊的窗口

-- 平台特定設定
if vim.fn.has("win32") == 1 then
  -- Windows 特定設定
  vim.opt.shell = "cmd.exe"
elseif vim.fn.has("unix") == 1 then
  -- Unix/Linux 特定設定
  vim.opt.shell = "/bin/sh"
elseif vim.fn.has("mac") == 1 then
  -- macOS 特定設定
  vim.opt.shell = "/bin/zsh"
end

