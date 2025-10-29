-- LuaJIT Optimization: FFI for high-performance timing (replaces vim.fn.reltime)
local ffi_available, ffi = pcall(require, 'ffi')
local use_ffi = false
local timeval_ct, C

if ffi_available then
  local ok = pcall(function()
    ffi.cdef([[
      typedef long time_t;
      typedef long suseconds_t;
      struct timeval {
        time_t tv_sec;
        suseconds_t tv_usec;
      };
      int gettimeofday(struct timeval *tv, void *tz);
    ]])
    timeval_ct = ffi.typeof('struct timeval')
    C = ffi.C
    use_ffi = true
  end)
  if not ok then
    use_ffi = false
  end
end

-- LuaJIT Optimization: Cache vim.api and vim.fn functions as locals
local nvim_get_vvar = vim.api.nvim_get_vvar
local nvim_command = vim.api.nvim_command
local fn_reltime = vim.fn.reltime
local fn_reltimestr = vim.fn.reltimestr
local fn_split = vim.fn.split
local str_sub = string.sub

-- LuaJIT Optimization: Pre-allocate tables with table.new if available
local table_new
local table_new_available, table_lib = pcall(require, 'table.new')
if table_new_available then
  table_new = table_lib
end

local TimeDrivenAcceleration = {}

function TimeDrivenAcceleration:new(config)
  -- LuaJIT Optimization: Pre-allocate previous_timestamp table for 4 movements (j, k, gj, gk)
  local previous_timestamp
  if table_new then
    previous_timestamp = table_new(0, 4)
  else
    previous_timestamp = {}
  end

  local o = {
    key_count = 0,
    previous_timestamp = previous_timestamp,
    acceleration_table = config.acceleration_table,
    deceleration_table = config.deceleration_table,
    end_of_count = config.acceleration_table[#config.acceleration_table],
    acceleration_limit = config.acceleration_limit,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function TimeDrivenAcceleration:decelerate(delay)
  -- LuaJIT Optimization: Cache table length and use ipairs() for array iteration
  local deceleration_table = self.deceleration_table
  local dec_table_len = #deceleration_table
  local deceleration_count = deceleration_table[dec_table_len][2]
  local prev_dec_count = 0

  -- LuaJIT Optimization: Use ipairs() instead of pairs() for arrays - fully JIT-compiled
  for idx = 1, dec_table_len do
    local entry = deceleration_table[idx]
    local elapsed = entry[1]
    local dec_count = entry[2]
    if delay < elapsed then
      deceleration_count = prev_dec_count
      break
    else
      prev_dec_count = dec_count
    end
  end

  -- LuaJIT Optimization: Avoid repeated table lookups
  local key_count = self.key_count - deceleration_count
  self.key_count = key_count < 0 and 0 or key_count
end

function TimeDrivenAcceleration:get_acceleration_step()
  -- LuaJIT Optimization: Cache table and length as locals
  local acceleration_table = self.acceleration_table
  local len = #acceleration_table
  local key_count = self.key_count

  for idx = 1, len do
    if acceleration_table[idx] > key_count then
      return idx
    end
  end
  return len + 1
end

-- LuaJIT Optimization: Hot path function - called on every keystroke
function TimeDrivenAcceleration:move_to(movement)
  -- LuaJIT Optimization: Cache vvar lookup result
  local step = nvim_get_vvar('count')
  if step and step ~= 0 then
    nvim_command('normal! ' .. step .. movement)
    return
  end

  -- LuaJIT Optimization: FFI-based timing for zero-allocation, fully JIT-compiled performance
  local msec
  if use_ffi then
    -- FFI path: direct C timing, no string operations, no allocations
    local previous_tv = self.previous_timestamp[movement]
    local current_tv = timeval_ct()
    C.gettimeofday(current_tv, nil)

    if previous_tv then
      -- Calculate milliseconds: (sec_delta * 1000) + (usec_delta / 1000)
      msec = (current_tv.tv_sec - previous_tv.tv_sec) * 1000 + (current_tv.tv_usec - previous_tv.tv_usec) / 1000
    else
      msec = 999999 -- First call, ensure deceleration doesn't trigger
    end

    self.previous_timestamp[movement] = current_tv
  else
    -- Fallback path: original vim.fn.reltime() implementation
    local previous_timestamp = self.previous_timestamp[movement] or { 0, 0 }
    local current_timestamp = fn_reltime()
    local delta = fn_split(fn_reltimestr(fn_reltime(previous_timestamp, current_timestamp)), '\\.')
    msec = tonumber(delta[1] .. str_sub(delta[2], 1, 3))
    self.previous_timestamp[movement] = current_timestamp
  end

  -- LuaJIT Optimization: Cache frequently accessed values
  if msec > self.acceleration_limit then
    self:decelerate(msec)
  end

  step = self:get_acceleration_step()
  nvim_command('normal! ' .. step .. movement)

  -- LuaJIT Optimization: Avoid repeated table lookup
  local key_count = self.key_count
  if key_count < self.end_of_count then
    self.key_count = key_count + 1
  end
end

-- LuaJIT Optimization: Ensure JIT compilation is enabled for this module
local jit_available, jit = pcall(require, 'jit')
if jit_available and jit.on then
  jit.on(true, true)
end

return TimeDrivenAcceleration
