-- CodeCompanion via OpenRouter. Needs OPENROUTER_API_KEY in your shell env.
local MODEL = "nvidia/nemotron-3.5-lightning:free" -- change the model here

---Build a prompt-library entry that sends the visual selection.
local function selection_prompt(interaction, alias, description, system, ask)
  return {
    interaction = interaction,
    description = description,
    opts = { alias = alias, modes = { "v" }, auto_submit = true, stop_context_insertion = true },
    prompts = {
      { role = "system", content = system },
      {
        role = "user",
        content = function(context)
          local code = require("codecompanion.helpers.code").get_code(context.start_line, context.end_line)
          return ask .. ":\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
        end,
      },
    },
  }
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      vim.cmd([[cab ccc CodeCompanionChat]])
      require("config.modes").define("ai", {
        key = "<leader>a",
        desc = "chat, inline prompts, select code and ask about it",
        keys = {
          { "a", "<cmd>CodeCompanionChat Toggle<CR>", "toggle chat", mode = { "n", "x" } },
          { "n", "<cmd>CodeCompanionChat<CR>", "new chat" },
          { "p", "<cmd>CodeCompanionActions<CR>", "actions", mode = { "n", "x" } },
          { "i", ":CodeCompanion ", "inline prompt", mode = { "n", "x" } },
          { "c", "<cmd>CodeCompanionChat Add<CR>", "add selection", mode = "x" },
          { "e", ":CodeCompanion /explain<CR>", "explain selection", mode = "x" },
          { "r", ":CodeCompanion /review<CR>", "review selection", mode = "x" },
          { "f", ":CodeCompanion /refactor<CR>", "fix selection", mode = "x" },
          { "t", ":CodeCompanion /tests<CR>", "tests for selection", mode = "x" },
        },
      })
    end,
    opts = {
      adapters = {
        http = {
          openrouter = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              env = {
                url = "https://openrouter.ai/api",
                api_key = "OPENROUTER_API_KEY",
                chat_url = "/v1/chat/completions",
              },
              schema = {
                model = { default = MODEL },
                temperature = { default = 0.2 },
                max_tokens = { default = 32768 },
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = "openrouter",
          tools = { opts = { default_tools = { "agent" } } },
        },
        inline = { adapter = "openrouter" },
        cmd = { adapter = "openrouter" },
      },
      mcp = {
        servers = {
          -- scoped to the directory Neovim was opened in
          filesystem = {
            cmd = { "npx", "-y", "@modelcontextprotocol/server-filesystem", vim.fn.getcwd() },
            roots = { vim.fn.getcwd() },
          },
        },
        opts = { default_servers = { "filesystem" } },
      },
      prompt_library = {
        ["Review Code"] = selection_prompt(
          "chat",
          "review",
          "Review code for issues and improvements",
          [[You are a senior code reviewer. Use the available tools when necessary to inspect the actual project.
Analyze code for bugs, security issues, performance, architecture, error handling, maintainability and style.
Do not invent files, tool results, or project details.]],
          "Review this code"
        ),
        ["Explain Code"] = selection_prompt(
          "chat",
          "explain",
          "Explain how the selected code works",
          [[You are a helpful programming assistant. When necessary, use the available tools to inspect
the actual project rather than guessing about files or dependencies.]],
          "Explain what this code does step by step"
        ),
        ["Refactor Code"] = selection_prompt(
          "inline",
          "refactor",
          "Refactor selected code for better quality",
          [[You are an expert programmer. Refactor code to improve readability, performance, maintainability
and correctness. Preserve existing behavior unless a change is necessary. Return only code.]],
          "Refactor this code"
        ),
        ["Write Tests"] = selection_prompt(
          "chat",
          "tests",
          "Generate tests for the selected code",
          [[You are an expert test engineer. Write comprehensive tests covering normal cases, edge cases,
invalid input and error handling, using the project's existing test framework.]],
          "Write tests for this code"
        ),
      },
    },
  },
}
