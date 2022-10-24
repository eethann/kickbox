-- Demo of kickbox engine


engine.name = 'Kickbox'
kick_eng = include('kickbox/lib/kickbox_engine')
Seq_Step = include("kickbox/lib/seq_step")
s = require 'sequins'
steps = {}
local probs

function init()
  print("Start kickbox init")

  params:add_separator("Kickbox")
  kick_eng.add_params()
  
  print("Initializing kickbox module params")

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


  -- probs = s{1, s{1, 0.25, 0.75, 0.125, .5} } 
  print("Making sequencer steps")
  steps = s(Seq_Step.steps(16))
  print("starting redraw clock")
  redraw_clock_id = clock.run(redraw_clock)
  print("Starting kickbox sequencer")
  start_seq()
  print("End kickbox init")
end

function seq_func()
  while true do
    local step = steps()
    steps:step(step.length)
    local length = step.length * 1/(params:get("Kickbox_div") > 0 and params:get("Kickbox_div") or 1)
    for i=1,step.subdiv do
      if (step.state == 1) and (math.random() <= step.prob) then
        kick_eng.trig(0.75 + (0.25 * step.accent))
      end
      clock.sync(length / step.subdiv)
    end
  end
end

function start_seq()
  -- TODO make this a proper stop/start
  playing = true
  screen_dirty = true
  sequence_id = clock.run(seq_func)
end

function stop_seq()
  playing = false
  clock.cancel(sequence_id)
  screen_dirty = true
end

function toggle_seq()
  if playing then
    stop_seq()
  else
    start_seq()
  end
end

focus_step = 1
ui_mode = 1

function key(n,z)
  if z == 1 then
    if n == 3 then
      toggle_seq()
    elseif n == 2 then
      steps[focus_step].state = 1 - steps[focus_step].state
    end
  end
  screen_dirty = true
end

function enc(e, d)
  if e == 3 then
    focus_step = util.wrap(focus_step + d, 1, steps.length)
  elseif e ==2 then
    steps[focus_step].subdiv = util.clamp(steps[focus_step].subdiv + d, 1, 16)  
  elseif e == 1 then
    steps[focus_step].length = util.clamp(steps[focus_step].length + d, 1, 16)  
  end
  screen_dirty = true
end

function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end

function redraw()
  if screen_dirty then
    screen.clear()
    screen.move(64,32)
    if focus_step > 0 then
      screen.text(focus_step .. ": " .. steps[focus_step].state .. "(" .. steps[focus_step].length .. "/" .. steps[focus_step].subdiv .. ")")
    end
    screen.update()
  end
end