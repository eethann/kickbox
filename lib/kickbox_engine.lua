local Kickbox = {}
local Formatters = require 'formatters'

local specs = {
	["freq"] = controlspec.new(20, 1000, "exp", 0, 44, "Hz"),
	["mod_ratio"] = controlspec.new(0, 10, "lin", 0, 2, ""),
	["amp"] = controlspec.new(0, 1, "lin", 0, 1, ""),
	["sustain"] = controlspec.new(0, 1, "lin", 0, 0.33, ""),
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
	["sin_shaper_amt"] = controlspec.new(0, 4, "lin", 0, 1, "") 
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

local glue_specs = {
	["drum_comp_mix"] = controlspec.new(0, 1, "lin", 0, 1, ""),
	["in_sidechain_mix"] = controlspec.new(0, 1, "lin", 0, 1, ""),
	["in_sig_lvl"] = controlspec.new(0, 2, "lin", 0, 1, ""),
	["drum_sig_lvl"] = controlspec.new(0, 2, "lin", 0, 0.5, ""),
	["drum_cntrl_lvl"] = controlspec.new(0, 2, "lin", 0, 1, ""),
	["sidechain_makeup_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
	["sidechain_ratio"] = controlspec.new(0, 8, "lin", 0, 0.5, ""),
	["sidechain_thresh"] = controlspec.new(0, 1, "lin", 0, 0.3, ""),
	["sidechain_release"] = controlspec.new(0, 1, "lin", 0, 0.5, ""),
	["sidechain_attack"] = controlspec.new(0, 1, "lin", 0, 0.05, ""),
	["comp_makeup_amt"] = controlspec.new(0, 1, "lin", 0, 1, ""),
	["comp_ratio"] = controlspec.new(0, 8, "lin", 0, 2, ""),
	["comp_thresh"] = controlspec.new(0, 1, "lin", 0, 0.5, ""),
	["comp_release"] = controlspec.new(0, 1, "lin", 0, 0.1, ""),
	["comp_attack"] = controlspec.new(0, 1, "lin", 0, 0.05, "")
}

local glue_param_names = {
	"drum_comp_mix",
	"in_sidechain_mix",
	"in_sig_lvl",
	"drum_sig_lvl",
	"drum_cntrl_lvl",
	"sidechain_makeup_amt",
	"sidechain_ratio",
	"sidechain_thresh",
	"sidechain_release",
	"sidechain_attack",
	"comp_makeup_amt",
	"comp_ratio",
	"comp_thresh",
	"comp_release",
	"comp_attack"
}

function Kickbox.add_params()
  params:add_group("Kickbox Engine", #param_names + #glue_param_names + 2)
  params:add_separator("Drum")
  for i = 1,#param_names do
    local p_name = param_names[i]
    params:add{
      type = "control",
      id = "kickbox_engine_"..p_name,
      name = p_name,
      controlspec = specs[p_name],
      action = function(x)
        engine[p_name](x) 
      end
    }
  end
  params:add_separator("Compressor")
  for i = 1,#glue_param_names do
    local p_name = glue_param_names[i]
    params:add{
      type = "control",
      id = "kickbox_engine_"..p_name,
      name = p_name,
      controlspec = glue_specs[p_name],
      action = function(x)
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