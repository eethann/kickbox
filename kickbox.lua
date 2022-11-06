-- Demo of kickbox engine
-- TODO fix amp to be log instead of lin
-- TODO param controls per  step
-- TODO ratchet count / div looped over tie
-- TODO ties apply all non-trigger when enabled
-- TODO add morph option to steps, interpolate to params locked in next (active?) step
-- TODO add params for current step params (e.g. "current step freq" to make MiDi editing easy)

UI = require("ui")

engine.name = 'Kickbox'
kick_eng = include('kickbox/lib/kickbox_engine')
Seq_Step = include("kickbox/lib/seq_step")
s = require 'sequins'
steps = {}
dials = {}
current_step = 1

-- TODO refactor these into an instrument object
-- TODO redo these to use the macro params
-- TODO move sequence state to its own obj
ui_params = {"amp", "sustain", "freq", "click_sweep", "mod_index", "mod_ratio", "mod_feedback", "sin_shaper_amt" }
ui_param_labels = {"amp", "sus", "freq", "click", "indx", "rtio", "fdbk", "shpr"}

-- We use raw 0-1 for all values, set via param:set_raw and scaled automatically that way
default_param_vals = {
  amp = 1,
  sustain = 0.3,
  freq = util.explin(10,8000,0,1,44),
  click_sweep = util.linlin(0,10,0,1,1),
  mod_index = 0,
  mod_ratio = util.linlin(0,16,0,1,2),
  mod_feedback = 0,
  sin_shaper_amt = util.linlin(0,4,0,1,1)
}
focus_dial_num = 1
focus_dial_name = ui_params[focus_dial_num]

local probs

function int_not(n)
  return 1-math.min(n,1)
end

function init()
  print("Start kickbox init")

  params:add_separator("Kickbox")
  kick_eng.add_params()
  
  local specs = {
    ["div"] = controlspec.new(1, 8, "lin", 1, 4, ""),
  }

  local param_names = {
    "div",
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

  init_dials()

  -- probs = s{1, s{1, 0.25, 0.75, 0.125, .5} } 
  print("Making sequencer steps")
  steps = s(Seq_Step.steps(16, default_param_vals))
  print("starting redraw clock")
  redraw_clock_id = clock.run(redraw_clock)
  print("Starting kickbox sequencer")
  start_seq()
  print("End kickbox init")
end

function init_dials()
  screen.aa(1) -- provides smoother screen drawing
  -- UI.Dial.new (x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title)
  for i=1,#ui_params do
    -- local range = params:get_range("kickbox_engine_" .. ui_params[i])
    -- TODO get actual quant from param for rounding
    dials[i] = UI.Dial.new(
      10 + 32 * math.floor((i-1)/2), 30 + 20 * ((i-1)%2), 
    8, 
      default_param_vals[ui_params[i]], 
      0, 1, 1 / 256 ,
      0,
      {}, "", 
      ui_param_labels[i])
    if i ~= focus_dial_num then
      dials[i].active = false
    end
  end
end

function seq_func()
  while true do
    local step = steps()
    -- FIXME this should move into the loop so it can be updated mid-step / mid-repeat cycle
    local step_length = 1/(params:get("Kickbox_div") > 0 and params:get("Kickbox_div") or 1)
    local length = 1
    for i=steps.ix+1,steps.length do
      if steps[i].tie == 1 then
        length = length + 1
      else
        break
      end
    end
    if (step.state == 1) and (math.random() <= step.prob) then
      -- plan to pick back up at the next un-tied step
      steps:step(length)
      local inc_steps = 0
      local repeat_ix = 0 -- this gets init'd on first loop
      local repeat_steps = step.period > 0 and (step.period / step.subdiv) or length
      local amp = step.amp
      -- TODO add acceleration / deceleration
      repeat
        if ((steps.ix + math.floor(inc_steps)) > repeat_ix) then
          repeat_ix = steps.ix + math.floor(inc_steps)
          if (steps[repeat_ix].state == 1) and (math.random() <= steps[repeat_ix].prob) then
            if steps[repeat_ix].period > 0 then
              repeat_steps = steps[repeat_ix].period / steps[repeat_ix].subdiv
            end
            -- TODO also apply other param locks from this step
            for i=1,#ui_params do
              params:set_raw("kickbox_engine_" .. ui_params[i], steps[repeat_ix]:get_param_val(ui_params[i]))
            end
            amp = steps[repeat_ix].amp
          end
        end
        kick_eng.trig(amp)
        -- Either the repeat length, or the amount of time till the next non-tie fires
        -- We need to use clock.sleep because we want this note to start anywhere, not just on a grid of repeat_steps
        current_step = steps.ix + inc_steps
        screen_dirty = true
        clock.sleep(math.min(repeat_steps, length - inc_steps) * step_length * clock.get_beat_sec())
        inc_steps = inc_steps + repeat_steps
      screen_dirty = true
      until inc_steps >= length
    else
      current_step = steps.ix
      screen_dirty = true
      steps:step(1)
      clock.sync(step_length)
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

keys_down = {}
function key(n,z)
  keys_down[n] = z
  if z == 1 then
    if keys_down[2] == 1 then
      if n == 3 then
        steps[focus_step]:toggle_tie()
      elseif n == 1 then
        toggle_seq()
      end
    else
      if n == 3 then
        steps[focus_step].state = 1 - steps[focus_step].state
      end
    end
  end
  screen_dirty = true
end

function enc(e, d)
  if keys_down[2] == 1 then
    if e == 1 then
      if d > 0 then
        steps[focus_step]:lock(focus_dial_name, default_param_vals)
        dials[focus_dial_num]:set_value(steps[focus_step].params[focus_dial_name])
      elseif d < 0 then
        steps[focus_step]:unlock(focus_dial_name)
        dials[focus_dial_num]:set_value(default_param_vals[focus_dial_name])
      end
    elseif e ==2 then
      steps[focus_step].period = util.clamp(steps[focus_step].period + d, 1, 16)  
    elseif e == 3 then
      steps[focus_step].subdiv = util.clamp(steps[focus_step].subdiv + d, 1, 16)  
    end
  else
    if e == 1 then
      focus_step = util.wrap(focus_step + d, 1, steps.length)
      dials[focus_dial_num]:set_value(steps[focus_step]:get_param_val(focus_dial_name))
    elseif e ==2 then
      -- TODO move prob elsewhere
      -- steps[focus_step].prob = util.clamp(steps[focus_step].prob + (d / 10), 0, 1)  
      dials[focus_dial_num].active = false
      focus_dial_num = util.clamp(focus_dial_num + d, 1, 8)
      focus_dial_name = ui_params[focus_dial_num]
      dials[focus_dial_num].active = true
    elseif e == 3 then
      -- TODO
      if focus_dial_num == 1 then
        steps[focus_step].amp = util.clamp(steps[focus_step].amp + (d / 64), 0, 1)  
      else 
        -- TODO use delta coeficient = to param step val
        dials[focus_dial_num]:set_value_delta(d * 1/64)
        steps[focus_step]:set_param_val(focus_dial_name, dials[focus_dial_num].value)
      end
    end
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

function draw_grid(steps,x,y,w,h,focus_step)
  local xd = w / steps.length
  local x_pad = 1
  local do_highlight = (1 + (focus_step - 1) % 8) == j
  
  -- Ticks for each step
  for i=1,steps.length do
    screen.level(((i == focus_step) and 11 or 4) + ((i == current_step) and 4 or 0))
    screen.rect(x+(i-1)*xd, y + h - 2, xd - x_pad, 1)
    screen.fill()
  end
  -- -- Add bar for the tie status of the current step
  -- screen.rect(
  --   x + (focus_step - 1) * xd, 
  --   y + h, 
  --   xd * steps[focus_step].length - x_pad, -- obsolete
  --   2
  -- )
  -- Display bars for all tied steps
  -- TODO change depending on the current random play state
  for j=1,steps.length do
    local cur_step = steps[j]
    local h_ratio = cur_step.amp
    local level = 10
    level = level + ((j == current_step) and 4 or 0)
    if cur_step.tie == 1 then
      screen.level(level)
      screen.rect(x+(j-1)*xd, y + h - 5 , xd - x_pad, 2)
      screen.fill()
    end
  end
  
  -- Display amp level of each step
  -- TODO see if this can be merged with the above loop
  for i=1,steps.length do
    local cur_step = steps[i]
    local top = y + (h-5) * (1-cur_step.amp)
    screen.level(((i == focus_step) and 11 or 4) + ((i == current_step) and 4 or 0))
    -- local level = 10 + ((i == current_step) and 4 or 0)
    -- screen.level(level)
    if cur_step.state == 1 then
      screen.rect(x+(i-1)*xd, top, xd - x_pad, (h - 5) * cur_step.amp)
      screen.fill()
    end
    local level = 2 + ((i == current_step) and 4 or 0)
    screen.move(x+(i-1)*xd, top)
    screen.line(x+i*xd-x_pad, top)
    screen.stroke()
  end
end

function redraw()
  if screen_dirty then
    screen.clear()
    if (steps and steps.length > 0) then
      draw_grid(steps, 10, 4, 108, 20, focus_step)
    end
    for i=1,#dials do
      dials[i]:redraw()
      if (steps[focus_step].locks[ui_params[i]] == 1) then
        screen.blend_mode(1)
        -- screen.level(4)
        screen.rect(6 + 32 * math.floor((i-1)/2), 28 + 20 * ((i-1)%2), 16, 16) 
        screen.fill()
        -- screen.level(15)
        screen.blend_mode(0)
      end
    end
    screen.move(64,32)
    if focus_step > 0 then
      -- TODO compute length from # of ties following
      screen.text(focus_step .. "(" .. steps[focus_step].prob .. "): " .. steps[focus_step].state .. "(" .. steps[focus_step].period .. "/".. steps[focus_step].subdiv .. ")")
    end
    screen.update()
  end
end