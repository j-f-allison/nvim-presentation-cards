-- Manages the single local server process that hosts the presenter
-- page + outline.json. Neovim's cursor/window state never reaches this
-- module or the page it serves; this only ever writes outline.json and
-- starts/stops a static file server.

local M = {}

local state = {
  job = nil, -- vim.SystemObj
  port = nil,
  bufnr = nil,
  data_dir = nil,
}

M.state = state

local function find_server_script()
  local matches = vim.api.nvim_get_runtime_file('server/server.py', false)
  return matches[1]
end

local function python_cmd()
  if vim.fn.executable('python3') == 1 then
    return 'python3'
  elseif vim.fn.executable('python') == 1 then
    return 'python'
  end
  return nil
end

--- Is a session already running for this exact buffer?
function M.is_active_for(bufnr)
  return state.job ~= nil and state.bufnr == bufnr
end

function M.is_active()
  return state.job ~= nil
end

function M.url()
  return state.port and ('http://127.0.0.1:' .. state.port .. '/') or nil
end

function M.outline_path()
  return state.data_dir and (state.data_dir .. '/outline.json') or nil
end

--- Stop the running server, if any.
function M.stop()
  if state.job then
    pcall(function()
      state.job:kill('sigterm')
    end)
    state.job = nil
  end
  state.port = nil
  state.bufnr = nil
  state.data_dir = nil
end

--- Start (or take over) the server for `bufnr`. Caller is responsible
--- for checking is_active_for() first if it wants no-op-on-repeat
--- behavior; this function always (re)starts the process.
function M.start(bufnr, cfg)
  if state.job then
    M.stop()
  end

  local server_script = find_server_script()
  if not server_script then
    error('nvim-presenter: could not find server/server.py on the runtimepath')
  end

  local python = python_cmd()
  if not python then
    error('nvim-presenter: no python3 (or python) executable found on PATH')
  end

  local static_dir = vim.fs.dirname(server_script)
  local data_dir = vim.fn.stdpath('data') .. '/nvim-presenter'
  vim.fn.mkdir(data_dir, 'p')

  -- A pre-flight "is this port free" TCP probe is unreliable here: on
  -- some platforms a bind()+listen() probe succeeds even when another
  -- process already holds the port (SO_REUSEADDR semantics). Instead,
  -- actually try to start the server on each candidate port in turn and
  -- watch whether it exits immediately (bind failure) or keeps running.
  local last_err

  for offset = 0, cfg.port_search_range - 1 do
    local port = cfg.port + offset
    local exited = false
    local exit_result

    local job = vim.system(
      { python, server_script, tostring(port), static_dir, data_dir },
      { detach = false, stderr = true },
      function(result)
        exited = true
        exit_result = result
      end
    )

    vim.wait(300, function()
      return exited
    end, 20)

    if not exited then
      state.job = job
      state.port = port
      state.bufnr = bufnr
      state.data_dir = data_dir
      return port
    end

    last_err = vim.trim((exit_result and exit_result.stderr) or '')
  end

  error(string.format(
    'nvim-presenter: no free port in range %d-%d (%s)',
    cfg.port, cfg.port + cfg.port_search_range - 1, last_err or 'unknown error'
  ))
end

return M
