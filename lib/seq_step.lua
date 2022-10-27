local Seq_Step = {
  -- TODO add conditional steps
  state = 0, -- whether or not this step should trigger
  prob = 1,
  length = 1, -- length of this step, will advance next step to t+val
  subdiv = 1, -- how many repeats should be played within the length (repeat len = len/subdiv)
  amp = 1,
  accent = 0
}

function Seq_Step:new(init)
  init = init or {}
  setmetatable(init, self)
  self.__index = self
  return init
end

function Seq_Step.steps(n)
  local t = {}
  n = n or 1
  for i=1,n do
    table.insert(t, Seq_Step:new())
  end
  return t
end

return Seq_Step
