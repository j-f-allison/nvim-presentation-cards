local config = require('nvim-presenter.config')
local parser = require('nvim-presenter.parser')
local server = require('nvim-presenter.server')

local M = {}

local augroup = vim.api.nvim_create_augroup('NvimPresenter', { clear = true })

local function write_outline(bufnr)
  local path = server.outline_path()
  if not path then
    return
  end

  local nodes = parser.parse_buffer(bufnr)
  local ok, json = pcall(vim.json.encode, nodes)
  if not ok then
    vim.notify('nvim-presenter: failed to encode outline', vim.log.levels.ERROR)
    return
  end

  vim.fn.writefile({ json }, path)
end

function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = augroup,
    callback = function()
      server.stop()
    end,
  })
end

--- :PresenterStart
-- Reopens the browser tab with no changes if a session is already
-- running for the current buffer. Otherwise stops any session running
-- for a different buffer (only one session exists at a time) and
-- starts a fresh one here.
function M.start()
  local bufnr = vim.api.nvim_get_current_buf()

  if server.is_active_for(bufnr) then
    vim.ui.open(server.url())
    return
  end

  local moved_session = server.is_active()

  local ok, err = pcall(server.start, bufnr, config.options)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_clear_autocmds({ group = augroup, event = 'BufWritePost' })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup,
    buffer = bufnr,
    callback = function()
      write_outline(bufnr)
    end,
  })

  write_outline(bufnr)

  -- give the server a brief moment to bind before pointing a browser at it
  vim.defer_fn(function()
    vim.ui.open(server.url())
  end, 200)

  if moved_session then
    vim.notify('nvim-presenter: moved session to this buffer', vim.log.levels.INFO)
  end
end

--- :PresenterStop
function M.stop()
  if not server.is_active() then
    return
  end
  server.stop()
  vim.api.nvim_clear_autocmds({ group = augroup, event = 'BufWritePost' })
end

return M
