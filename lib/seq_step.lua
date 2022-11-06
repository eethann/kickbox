local Seq_Step = {}

function Seq_Step:new(default_param_vals)
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

function Seq_Step:toggle_state() 
  self.state = 1 - self.state
end

function Seq_Step:toggle_tie()
  self.tie = 1 - self.tie
end

function Seq_Step:set_amp(new_amp)
  self.amp = new_amp
end

function Seq_Step:is_locked(param_name)
  return self.locks[param_name] == 1
end

function Seq_Step:lock(param_name, defaults)
  if self.locks[param_name] ~= 1 then
    self.locks[param_name] = 1
    if self.params[param_name] == nil then
      self.params[param_name] = defaults[param_name]
    end
  end
end

function Seq_Step:unlock(param_name)
  if self.locks[param_name] == 1 then
    self.locks[param_name] = 0 -- todo should this be nil?
  end
end

function Seq_Step:get_param_val(param_name) 
  if self:is_locked(param_name) then
    return self.params[param_name]
  else
    return self.default_param_vals[param_name]
  end
end

function Seq_Step:set_param_val(param_name, param_val)
  if self:is_locked(param_name) then
    self.params[param_name] = param_val
  else
    self.default_param_vals[param_name] = param_val
  end
end

function Seq_Step.steps(n, default_param_vals)
  local t = {}
  n = n or 1
  for i=1,n do
    table.insert(t, Seq_Step:new(default_param_vals))
  end
  return t
end

return Seq_Step
