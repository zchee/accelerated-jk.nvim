-- LuaJIT Optimization: Cache vim.api functions as locals to reduce table lookups
local nvim_get_vvar = vim.api.nvim_get_vvar
local nvim_command = vim.api.nvim_command
local nvim_win_get_cursor = vim.api.nvim_win_get_cursor

-- LuaJIT Optimization: Pre-allocate tables with table.new if available
local table_new
local table_new_available, table_lib = pcall(require, 'table.new')
if table_new_available then
  table_new = table_lib
end

local PositionDrivenAcceleration = {}

function PositionDrivenAcceleration:new(config)
  -- LuaJIT Optimization: Pre-allocate previous_position table for 4 movements (j, k, gj, gk)
  local previous_position
  if table_new then
    previous_position = table_new(0, 4)
  else
    previous_position = {}
  end

  -- Initialize with current cursor positions (maintains original behavior)
  previous_position.j = nvim_win_get_cursor(0)
  previous_position.k = nvim_win_get_cursor(1)
  previous_position.gj = nvim_win_get_cursor(0)
  previous_position.gk = nvim_win_get_cursor(1)

  local o = {
    key_count = 0,
    previous_position = previous_position,
    acceleration_table = config.acceleration_table,
    end_of_count = config.acceleration_table[#config.acceleration_table],
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function PositionDrivenAcceleration:reset_key_count()
  self.key_count = 0
end

vim.cmd([[
augroup accelerated-jk-position-driven-reset
    autocmd!
    autocmd CursorHold,CursorHoldI * lua require('accelerated-jk').reset_key_count()
augroup END
]])

function PositionDrivenAcceleration:calclate_step()
  -- LuaJIT Optimization: Cache table and length as locals, use numeric for loop
  local acceleration_table = self.acceleration_table
  local acc_len = #acceleration_table
  local key_count = self.key_count

  -- LuaJIT Optimization: Use numeric for loop instead of pairs() for arrays
  for idx = 1, acc_len do
    if key_count < acceleration_table[idx] then
      return idx
    end
  end
  return acc_len + 1
end

-- LuaJIT Optimization: Hot path function - called on every keystroke
function PositionDrivenAcceleration:move_to(movement)
  -- LuaJIT Optimization: Cache vvar lookup result
  local step = nvim_get_vvar('count')
  if step and step ~= 0 then
    nvim_command('normal! ' .. step .. movement)
    return
  end

  -- LuaJIT Optimization: Inline position comparison to eliminate function call overhead
  -- Original: if not self:position_equal(self.previous_position[movement], nvim_win_get_cursor(0))
  local prev_pos = self.previous_position[movement]
  local curr_pos = nvim_win_get_cursor(0)
  if not (prev_pos[1] == curr_pos[1] and prev_pos[2] == curr_pos[2]) then
    self.key_count = 0
  end

  step = self:calclate_step()
  nvim_command('normal! ' .. step .. movement)

  -- LuaJIT Optimization: Avoid repeated table lookup
  local key_count = self.key_count
  if key_count < self.end_of_count then
    self.key_count = key_count + 1
  end

  -- Update position for next call
  self.previous_position[movement] = curr_pos
end

-- LuaJIT Optimization: Ensure JIT compilation is enabled for this module
local jit_available, jit = pcall(require, 'jit')
if jit_available and jit.on then
  jit.on(true, true)
end

return PositionDrivenAcceleration
