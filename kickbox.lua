-- Demo of kickbox engine


engine.name = 'Kickbox'
kick_eng = include('kickbox/lib/kickbox_engine')
s = require 'sequins'
local probs

function init()
  params:add_separator("Kickbox")
  local specs = {
    ["div"] = controlspec.new(1, 8, "lin", 1, 2, ""),
    ["click_mod_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["click_mod_sweep"] = controlspec.new(0, 10, "lin", 0, 0, ""),
    ["click_mod_mod_sweep"] = controlspec.new(0, 10, "lin", 0, 0, ""),
    ["click_mod_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["click_mod_index"] = controlspec.new(0, 1, "lin", 0, 0, ""),

    ["body_mod_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    -- TODO add body for direct out amp env for modulator
    ["body_mod_index"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["body_mod_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),

    ["fm_mod_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["fm_base_ratio"] = controlspec.new(0, 8, "lin", 0, 0, ""),
    ["fm_mod_ratio"] = controlspec.new(0, 8, "lin", 0, 0, ""),
    ["fm_mod_index"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["fm_mod_feedback"] = controlspec.new(0, 1, "lin", 0, 0, ""),

    ["env_mod_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["env_base_curve"] = controlspec.new(-5, 5, "lin", 0, 3, ""), -- bipolar
    ["env_base_sustain"] = controlspec.new(0, 2, "lin", 0, 0.5, ""),
    ["env_mod_curve"] = controlspec.new(-5, 5, "lin", 0, 0, ""), -- bipolar
    ["env_mod_sustain"] = controlspec.new(-2, 2, "lin", 0, 0, ""), -- bipolar

    ["pitch_mod_amt"] = controlspec.new(0, 1, "lin", 0, 0, ""),
    ["pitch_base_note"] = controlspec.new(0, 127, "lin", 1, 0, ""),
    ["pitch_base_hz"] = controlspec.new(0, 100, "exp", 0, 36, "Hz"),
    ["pitch_mod_mult"] = controlspec.new(0, 4, "lin", 0.1, 0, "")
  }

  local param_names = {
    "div",
    "click_mod_amt",
    "body_mod_amt",
    "fm_mod_amt",
    "env_mod_amt",
    "pitch_mod_amt",
    "click_mod_sweep",
    "click_mod_mod_sweep",
    "click_mod_feedback",
    "click_mod_index",
    "body_mod_index",
    "body_mod_feedback",
    "fm_base_ratio",
    "fm_mod_ratio",
    "fm_mod_index",
    "fm_mod_feedback",
    "env_base_curve", -- bipolar
    "env_base_sustain",
    "env_mod_curve", -- bipolar
    "env_mod_sustain", -- bipolar
    "pitch_base_note",
    "pitch_base_hz",
    "pitch_mod_mult"
  }

  for i = 1,#param_names do
    local p_name = param_names[i]
    params:add{
      type = "control",
      id = "Kickbox_"..p_name,
      name = p_name,
      controlspec = specs[p_name]
    }
  end

  kick_eng.add_params()

  local update_scaled_base_param = function(dest, source, base, scale) 
    params:set(dest, params:get(base) + (params:get(source) * params:get(scale)))
  end

  local update_scaled_param = function(dest, source, scale) 
    params:set(dest, params:get(source) * params:get(scale))
  end

  params:set_action("Kickbox_click_mod_amt", function(click_amt)
    update_scaled_param("kickbox_engine_mod_sweep_amt", "Kickbox_click_mod_mod_sweep", "Kickbox_click_mod_amt")
    update_scaled_param("kickbox_engine_click_sweep", "Kickbox_click_mod_sweep", "Kickbox_click_mod_amt")
    update_scaled_param("kickbox_engine_click_index", "Kickbox_click_mod_index", "Kickbox_click_mod_amt")
    update_scaled_param("kickbox_engine_click_feedback", "Kickbox_click_mod_feedback", "Kickbox_click_mod_amt")
  end)

  params:set_action("Kickbox_click_mod_mod_sweep", function(val)
    update_scaled_param("kickbox_engine_mod_sweep_amt", "Kickbox_click_mod_mod_sweep", "Kickbox_click_mod_amt")
  end)

  params:set_action("Kickbox_click_mod_sweep", function(val)
    update_scaled_param("kickbox_engine_click_sweep", "Kickbox_click_mod_sweep", "Kickbox_click_mod_amt")
  end)

  params:set_action("Kickbox_click_mod_index", function(val)
    update_scaled_param("kickbox_engine_click_index", "Kickbox_click_mod_index", "Kickbox_click_mod_amt")
  end)

  params:set_action("Kickbox_click_mod_feedback", function(val)
    update_scaled_param("kickbox_engine_click_feedback", "Kickbox_click_mod_feedback", "Kickbox_click_mod_amt")
  end)

  -- probs = s{1, s{1, 0.25, 0.75, 0.125, 0.5} } 
  probs = s{1}
  playing = false
  sequence = clock.run(
    function()
      while true do
        clock.sync(1/params:get("Kickbox_div"))
        if playing then
          if math.random() < probs() then
            kick_eng.trig(1)
          end
        end
      end
    end
  )
end

function key(n,z)
  if n == 3 and z == 1 then
    playing = not playing
    probs:reset() -- resets 'mults' index to 1
    redraw()
  end
end

function redraw()
  screen.clear()
  screen.move(64,32)
  screen.text(playing and "K3: turn off" or "K3: turn on")
  screen.update()
end