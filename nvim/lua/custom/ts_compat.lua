-- Compatibility shim for treesitter query handlers written against Neovim < 0.12.
--
-- Neovim 0.12 dropped the `all` option of `vim.treesitter.query.add_predicate()`
-- and `add_directive()`: handlers now always receive `match` as
-- `table<integer, TSNode[]>` (a *list* of nodes per capture id). Plugins still
-- written against the old single-node API keep asking for `all = false` and then
-- call node methods on a plain table, which throws while highlighting -- e.g. on
-- a markdown fenced code block, via nvim-treesitter's `set-lang-from-info-string!`:
--
--   Decoration provider "start" (ns=nvim.treesitter.highlighter):
--   ...treesitter.lua:197: attempt to call method 'range' (a nil value)
--
-- Affected here: nvim-treesitter (`master` branch) and nvim-treesitter-endwise.
--
-- This restores the wrapper Neovim itself used to install for `all = false`:
-- each capture is unwrapped to its last node. Only callers that explicitly opt
-- into the old semantics are wrapped, so handlers written for the new API are
-- left untouched.

local M = {}

---@param opts boolean|table|nil Third argument given to add_predicate/add_directive.
---@return boolean
local function wants_single_node(opts)
  -- Legacy signature: the third argument was a boolean `force`, and back then
  -- handlers always received one node per capture.
  if type(opts) ~= 'table' then
    return true
  end
  -- Only an explicit opt-out; `all = nil` is assumed to be new-style code.
  return opts.all == false
end

---Unwrap `table<integer, TSNode[]>` into `table<integer, TSNode>`, keeping the
---last node of each capture -- the exact behaviour of Neovim's own pre-0.12 shim.
---@param handler function
---@return function
local function unwrap_matches(handler)
  return function(match, ...)
    local single = {} ---@type table<integer, TSNode>
    for id, nodes in pairs(match) do
      single[id] = nodes[#nodes]
    end
    return handler(single, ...)
  end
end

local function patch(query, name)
  local original = query[name]
  query[name] = function(pred_name, handler, opts)
    if wants_single_node(opts) then
      handler = unwrap_matches(handler)
    end
    -- `all` is no longer a valid option; drop it so it is never forwarded.
    if type(opts) == 'table' then
      local cleaned = {} ---@type table
      for k, v in pairs(opts) do
        if k ~= 'all' then
          cleaned[k] = v
        end
      end
      opts = cleaned
    end
    return original(pred_name, handler, opts)
  end
end

function M.setup()
  -- Nothing to do once the plugins catch up (or on older Neovim, which still
  -- handles `all` itself).
  if vim.fn.has 'nvim-0.12' ~= 1 then
    return
  end

  local query = require 'vim.treesitter.query'
  patch(query, 'add_predicate')
  patch(query, 'add_directive')
end

return M
