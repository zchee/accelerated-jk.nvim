-- LuaJIT Optimization: Cache vim.api functions as locals to reduce table lookups
local nvim_set_keymap = vim.api.nvim_set_keymap
local str_format = string.format

-- LuaJIT Optimization: Cache require calls at module level
local config_module = require('accelerated-jk.config')

local M = {}

local driver = nil

local create_driver = function()
  if config_module.items.mode == 'time_driven' then
    return require('accelerated-jk.time_driven'):new(config_module.items)
  else
    return require('accelerated-jk.position_driven'):new(config_module.items)
  end
end

local create_keymaps = function()
  -- LuaJIT Optimization: Cache commonly used values as locals
  local acceleration_motions = config_module.items.acceleration_motions
  local keymap_opts = { silent = true, noremap = true }

  -- LuaJIT Optimization: Using ipairs for array iteration (already optimal)
  for _, motion in ipairs(acceleration_motions) do
    nvim_set_keymap('n', motion, str_format("<CMD>lua require'accelerated-jk'.move_to('%s')<CR>", motion), keymap_opts)
  end

  -- LuaJIT Optimization: Pre-define keymaps to avoid allocations in loop
  local keymaps = {
    ['<Plug>(accelerated_jk_j)'] = "<CMD>lua require'accelerated-jk'.move_to('j')<CR>",
    ['<Plug>(accelerated_jk_k)'] = "<CMD>lua require'accelerated-jk'.move_to('k')<CR>",
    ['<Plug>(accelerated_jk_gj)'] = "<CMD>lua require'accelerated-jk'.move_to('gj')<CR>",
    ['<Plug>(accelerated_jk_gk)'] = "<CMD>lua require'accelerated-jk'.move_to('gk')<CR>",
  }

  -- LuaJIT Optimization: pairs() is appropriate for hash tables
  for keymap, motion in pairs(keymaps) do
    nvim_set_keymap('n', keymap, motion, keymap_opts)
  end
end

M.reset_key_count = function()
  driver:reset_key_count()
end

-- LuaJIT Optimization: Hot path function - called on every keystroke
M.move_to = function(movement)
  driver:move_to(movement)
end

M.setup = function(opts)
  config_module.merge_config(opts)
  driver = create_driver()
  create_keymaps()

  -- LuaJIT Optimization: Flush JIT traces after setup to prevent trace pollution
  -- Setup code is only called once and shouldn't interfere with hot path compilation
  local jit_available, jit = pcall(require, 'jit')
  if jit_available and jit.flush then
    jit.flush()
  end
end

-- LuaJIT Optimization: Ensure JIT compilation is enabled for this module
local jit_available, jit = pcall(require, 'jit')
if jit_available and jit.on then
  jit.on(true, true)
end

return M
