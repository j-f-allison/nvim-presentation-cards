local M = {}

M.defaults = {
  -- first port tried for the local server
  port = 7777,
  -- how many ports to try (port, port+1, ...) before giving up
  port_search_range = 5,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts or {})
end

return M
