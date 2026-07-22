-- Parses a buffer's lines into the same outline structure the browser
-- page understands: a flat list of {text, section} nodes, one per
-- talking point. Lines starting with `#` don't produce a node of their
-- own -- they just set the section name attached to the bullets that
-- follow, until the next header.

local M = {}

local function strip_bullet_prefix(line)
  local text = line:gsub('^[%-*]%s*', '')
  return text
end

function M.parse_lines(lines)
  local nodes = {}
  local section = nil

  for _, raw_line in ipairs(lines) do
    local line = vim.trim(raw_line)
    if line ~= '' then
      if vim.startswith(line, '#') then
        section = line:gsub('^#+%s*', '')
      else
        local text = strip_bullet_prefix(line)
        table.insert(nodes, { text = text, section = section })
      end
    end
  end

  return nodes
end

function M.parse_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return M.parse_lines(lines)
end

return M
