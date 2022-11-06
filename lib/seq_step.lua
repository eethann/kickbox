s = require 'sequins'

local Step = {}
local Track = {}

function Step:new(default_param_vals)
  local init = {
    -- TODO add conditional steps
    state = 0, -- whether or not this step should trigger
    prob = 1,
    tie = 0, -- whether or not this step is tied to the previous one
    -- TODO add euclidean option
    period = 0,
    subdiv = 1, -- how many repeats should be played within the length (repeat len = len/subdiv)
    accent = 0,
    amp = 1, -- TODO move into params
    params = {},
    locks = {}
  }
  self.__index = self
  setmetatable(init, self)
  default_param_vals = default_param_vals or {}
  init.default_param_vals = default_param_vals
  return init
end

function Step:toggle_state() 
  self.state = 1 - self.state
end

function Step:toggle_tie()
  self.tie = 1 - self.tie
end

function Step:set_amp(new_amp)
  self.amp = new_amp
end

function Step:is_locked(param_name)
  return self.locks[param_name] == 1
end

function Step:lock(param_name, defaults)
  if self.locks[param_name] ~= 1 then
    self.locks[param_name] = 1
    if self.params[param_name] == nil then
      self.params[param_name] = defaults[param_name]
    end
  end
end

function Step:unlock(param_name)
  if self.locks[param_name] == 1 then
    self.locks[param_name] = 0 -- todo should this be nil?
  end
end

function Step:get_param_val(param_name) 
  if self:is_locked(param_name) then
    return self.params[param_name]
  else
    return self.default_param_vals[param_name]
  end
end

function Step:set_param_val(param_name, param_val)
  if self:is_locked(param_name) then
    self.params[param_name] = param_val
  else
    self.default_param_vals[param_name] = param_val
  end
end

function Step.steps(n, default_param_vals)
  local t = {}
  n = n or 1
  for i=1,n do
    table.insert(t, Step:new(default_param_vals))
  end
  return t
end

function Track:new(num_steps, default_param_vals)
  local init = {}
  self.__index = self
  setmetatable(init, self)
  local track_default_param_vals = {}
  for k,v in pairs(default_param_vals) do
    track_default_param_vals[k] = v
  end
  init.default_param_vals = track_default_param_vals
  local steps = {}
  for i=1,num_steps do
    table.insert(steps, Step:new(init.default_param_vals))
  end
  init.seq = s(steps)
  return init
end

function Track:get_step(n)
  return self.seq[n]
end

return Track
