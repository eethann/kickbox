local Seq_Step = {
  -- TODO add conditional steps
  state = 0, -- whether or not this step should trigger
  prob = 1,
  tie = 0, -- whether or not this step is tied to the previous one
  -- TODO add euclidean option
  period = 0,
  subdiv = 1, -- how many repeats should be played within the length (repeat len = len/subdiv)
  accent = 0,
  amp = 1, -- TODO move into params
  params = {}
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
