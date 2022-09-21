local Kickbox = {}
local Formatters = require 'formatters'

local specs = {
	["freq"] = controlspec.new(20, 1000, "exp", 0, 36, "Hz"),
	["mod_ratio"] = controlspec.new(0, 10, "lin", 0, 1, ""),
	["amp"] = controlspec.new(0, 1, "lin", 0, 1, ""),
	["sustain"] = controlspec.new(0, 1, "lin", 0, 0.5, ""),
	["contour"] = controlspec.new(-5, 5, "lin", 0, -3, ""),
	["click_length"] = controlspec.new(0, 1, "lin", 0, 0.2, ""),
	["click_curve"] = controlspec.new(-5, 5, "lin", 0, -4, ""),
	["body_length"] = controlspec.new(0, 1, "lin", 0, 0.3, ""),
	["body_curve"] = controlspec.new(-5, 5, "lin", 0, 1, ""),
	["body_mod_amp"] = controlspec.new(-5, 5, "lin", 0, 0, ""),
	["click_sweep"] = controlspec.new(0, 10, "lin", 0, 4, ""),
	["click_index"] = controlspec.new(0, 10, "lin", 0, 0, ""),
	["click_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),
	["body_index"] = controlspec.new(0, 10, "lin", 0, 0, ""),
	["body_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),
	["mod_index"] = controlspec.new(0, 10, "lin", 0, 0, ""),
	["mod_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),
	["mod_sweep_amt"] = controlspec.new(0, 10, "lin", 0, 0, ""),
	["sin_shaper_amt"] = controlspec.new(-1, 4, "lin", 0, 1, "") 
}

local param_names = {
  "freq",
  "mod_ratio",
  "amp",
  "sustain",
  "contour",
  "click_length",
  "click_curve",
  "body_length",
  "body_curve",
  "click_sweep",
  "click_index",
  "click_feedback",
  "body_index",
  "body_feedback",
  "body_mod_amp",
  "mod_index",
  "mod_feedback",
  "mod_sweep_amt",
  "sin_shaper_amt"
}

function Kickbox.add_params()
  params:add_group("Kickbox Engine",#param_names)

  for i = 1,#param_names do
    local p_name = param_names[i]
    params:add{
      type = "control",
      id = "kickbox_engine_"..p_name,
      name = p_name,
      controlspec = specs[p_name],
      -- formatter = p_name == "pan" and Formatters.bipolar_as_pan_widget or nil,
      action = function(x)
        print(p_name) 
        engine[p_name](x) 
      end
    }
  end
  
  params:bang()
end

function Kickbox.trig(amp)
  if amp ~= nil and amp ~= 0 then
    engine.trig(amp)
  end
end

return Kickbox