return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- nvim-lint doesn't ship a slim-lint definition, so define one here.
      -- Needs the gem: `gem install slim_lint` (or add it to the app's Gemfile).
      lint.linters.slim_lint = {
        cmd = 'slim-lint',
        stdin = true,
        args = {
          '--reporter',
          'json',
          '--stdin-file-path',
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        },
        -- Read both streams: RuboCop (which slim-lint drives) can write pages of
        -- warnings to stderr, and an unread stderr pipe deadlocks the process.
        stream = 'both',
        ignore_exitcode = true,
        parser = function(output, bufnr)
          -- The report is a single JSON line, mixed in with any stderr chatter.
          local decoded
          for line in vim.gsplit(output, '\n', { trimempty = true }) do
            local ok, report = pcall(vim.json.decode, line)
            if ok and type(report) == 'table' and report.files then
              decoded = report
            end
          end
          if not decoded then
            return {}
          end
          local severities = {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
          }
          local diagnostics = {}
          for _, file in ipairs(decoded.files or {}) do
            for _, offense in ipairs(file.offenses or {}) do
              -- slim-lint reports a line but no column, so span the whole line.
              local lnum = math.max((offense.location or {}).line or 1, 1) - 1
              local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ''
              table.insert(diagnostics, {
                lnum = lnum,
                col = 0,
                end_lnum = lnum,
                end_col = #line,
                message = offense.message,
                code = offense.linter,
                severity = severities[offense.severity] or vim.diagnostic.severity.WARN,
                source = 'slim-lint',
              })
            end
          end
          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        ruby = { 'ruby' },
        slim = { 'slim_lint' },
        clojure = { 'clj-kondo' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
