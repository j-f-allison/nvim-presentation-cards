-- Parses a buffer's lines into the same outline structure the browser
-- page understands: a flat list of {type, text, section} nodes.
-- Lines starting with `#` open a new section; every other non-blank
-- line is a talking point belonging to the current section.

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
        table.insert(nodes, { type = 'section', text = section })
      else
        local text = strip_bullet_prefix(line)
        table.insert(nodes, { type = 'bullet', text = text, section = section })
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
