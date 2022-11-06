Engine_Kickbox : CroneEngine {

  var params;
  var glue_params;
  var sources_group;
  var kick_bus;
  var glue;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

    sources_group = ParGroup.new(context.xg);
    kick_bus = Bus.audio(server: context.server, numChannels: 2);

    SynthDef(\kickbox_gluestick,
      {
        arg drum_in = 0,
        sig_in = 0,
        out = 0,
        drum_comp_mix = 1,
        in_sidechain_mix= 1,
        drum_sig_lvl = 0.5,
        drum_cntrl_lvl = 1,
        in_sig_lvl = 1,
        // default to no sidechain makeup so it's more pronounced
        sidechain_makeup_amt = 0, // 0 is no makeup, 1 is normalized to 0-1
        sidechain_ratio = 0.5,
        sidechain_thresh = 0.3,
        sidechain_release = 0.5,
        sidechain_attack = 0.05,
        comp_makeup_amt = 1,
        comp_ratio = 2,
        comp_thresh = 0.5,
        comp_release = 0.1,
        comp_attack = 0.05;

        var drum_sig, drum_ctrl, in_sig, comp_sig, sidechain_sig, out_sig;
        // Compute makeup amplitude to normalize compression curve to 0-1
        // (formula is actually thresh / slopeBelow, but slopeBelow is always 1)
        var sidechain_makeup = reciprocal(sidechain_thresh + ((1 - (sidechain_thresh)) * reciprocal(sidechain_ratio)));
        var comp_makeup = reciprocal(comp_thresh + ((1 - (comp_thresh)) * reciprocal(comp_ratio)));
        sidechain_makeup = 1 + ((sidechain_makeup - 1) * sidechain_makeup_amt);
        comp_makeup = 1 + ((comp_makeup - 1) * comp_makeup_amt);

        drum_sig = In.ar(drum_in, 2);
        drum_ctrl = drum_sig * drum_cntrl_lvl;
        drum_sig = drum_sig.madd(drum_sig_lvl);
        in_sig = In.ar(sig_in, 2).madd(in_sig_lvl);

        // TODO use custom env follower (rectify -> lpf) to get soft/hard knee compression
        sidechain_sig = Compander.ar(in_sig, drum_ctrl, thresh: sidechain_thresh, slopeBelow: 1, slopeAbove: 1/sidechain_ratio, clampTime: sidechain_attack, relaxTime: sidechain_release, mul: sidechain_makeup);
        comp_sig = Compander.ar(drum_sig, drum_ctrl, thresh: comp_thresh, slopeBelow: 1, slopeAbove: 1/comp_ratio, clampTime: comp_attack, relaxTime: comp_release, mul: comp_makeup);
        out_sig = XFade2.ar(drum_sig, comp_sig, drum_comp_mix) + XFade2.ar(in_sig, sidechain_sig, in_sidechain_mix);
        // TODO find a good way to keep the mix of the two in -1 to 1, currently distorts too easily
        // Obligatory nornifying tanh softclip before out
        out_sig = tanh(out_sig).softclip;
        ReplaceOut.ar(out, out_sig);
      }
    ).add;

    SynthDef(\kickbox_kick,
    { arg out = 0,
      freq = 36,
      mod_ratio = 1,
      amp = 1,
      sustain = 0.5,
      contour = -3,
      click_length = 0.2,
      click_curve = -4,
      body_length = 0.3,
      body_curve = 1,
      click_sweep = 4,
      click_index = 0,
      click_feedback = 0,
      body_index = 0,
      body_feedback = 0,
      body_mod_amp = 0,
      mod_index = 0,
      mod_feedback = 0,
      mod_sweep_amt = 0,
      sin_shaper_amt = 1;

      var sr = SampleRate.ir;
      var click_env, body_env, contour_env;
      var mod_osc, saw_osc, tri_osc, sin_osc, out_sig;
      var sin_shaper_makeup;
      var car_freq, mod_freq, pitch_env, amp_env;
      var index_amt, feedback_amt;

      click_env = EnvGen.ar(Env.perc(0.0001, click_length, level: 1, curve: click_curve));
      body_env = EnvGen.ar(Env.perc(0.0001, body_length, level: 1, curve: body_curve));
      contour_env = EnvGen.ar(Env.perc(0.0001, sustain, level: 1, curve: contour));
      car_freq = freq * ((click_env * click_sweep) + 1);
      mod_freq = freq * mod_ratio * ((click_env * mod_sweep_amt) + 1);

      // Generate modulator as a simple SinOsc (for now)
      feedback_amt = mod_feedback + ((click_env * click_feedback)) + ((body_env * body_feedback));
      mod_osc = SinOscFB.ar(mod_freq, feedback_amt * pi);

      // Generate saw carrier, scale -2 to 2
      // Use wrap with offset (0-4 not -2 - +2) so we start at 0 to avoid clicks
      saw_osc = Wrap.ar(Phasor.ar(rate: 4 * car_freq / sr, start: 0, end: 4.0), -2.0, 2.0);

      // Add modulator to carrier, wrap -1 to 1 (saw -> triangle waveshaping)
      index_amt = mod_index + (click_env * click_index) + (body_env * body_index);
      tri_osc = Fold.ar(saw_osc + (mod_osc * index_amt), -1.0, 1.0);

      // Sin waveshape through tanh
      // (use pre / post mult compensation for tri to sin fade)
      sin_shaper_amt = sin_shaper_amt max: 0.001;
      // sin_shaper_amt = -1 is tri, 1 is toward square
      // 2.2 is a fairly decent approximation of a sin (by experiment).
      // sin_shaper_amt = 2.2*(2**((2*sin_shaper_amt)));
      sin_shaper_amt = 2.2*sin_shaper_amt;
      sin_shaper_makeup = 1 / tanh(sin_shaper_amt);
      sin_osc = tri_osc.madd(sin_shaper_amt).tanh().madd(sin_shaper_makeup);

      // TODO compensate for potential >1 overloading (* 0.5 for all?)
      // TODO determine if just using DB is better, this is using a logarithmic 0-1 scale
      out_sig = ((sin_osc * contour_env) + (mod_osc * body_mod_amp * body_env)) * (10 ** (amp - 1));
      Out.ar(out,[out_sig,out_sig]);

      // Free when all envs are done
      FreeSelf.kr(if((click_env + body_env + contour_env) > 0, 0, 1))

    }).add;

    // should this be context.server.sync; ?
		Server.default.sync;

    glue = Synth.new(\kickbox_gluestick, target: context.xg, args: [\sig_in, context.in_b, \out, context.out_b, \drum_in, kick_bus], addAction: \addToTail);

    params = Dictionary.newFrom([
      \freq, 36,
      \mod_ratio, 2,
      \amp, 1,
      \sustain, 0.5,
      \contour, -3,
      \click_length, 0.2,
      \click_curve, -4,
      \body_length, 0.3,
      \body_curve, 1,
      \click_sweep, 6,
      \click_index, 0.2,
      \click_feedback, 0.5,
      \body_index, 0,
      \body_mod_amp, 0,
      \body_feedback, 0.3,
      \mod_index, 0,
      \mod_feedback, 0,
      \mod_sweep_amt, 0,
      \sin_shaper_amt, 0.5;
		]);

    glue_params = Dictionary.newFrom([
        \drum_comp_mix , 1,
        \in_sidechain_mix, 1,
        \in_sig_lvl, 1,
        \drum_sig_lvl, 0.5,
        \drum_cntrl_lvl , 1,
        \sidechain_makeup_amt , 0,
        \sidechain_ratio , 0.5,
        \sidechain_thresh , 0.3,
        \sidechain_release , 0.5,
        \sidechain_attack , 0.05,
        \comp_makeup_amt , 1,
        \comp_ratio , 2,
        \comp_thresh , 0.5,
        \comp_release , 0.1,
        \comp_attack , 0.05;
    ]);

    glue_params.keysDo({ arg key;
      this.addCommand(key, "f", { arg msg;
        glue.set(key, msg[1]);
      })
    });

    params.keysDo({ arg key;
		this.addCommand(key, "f", { arg msg;
				params[key] = msg[1];
			});
		});

 	this.addCommand("trig", "f", { arg msg;
		Synth.new(\kickbox_kick, args: params.getPairs ++ [\amp, msg[1], \out, kick_bus], target: sources_group)
	});

	}

  free {
    glue.free;
    kick_bus.free;
    sources_group.free;
  }
}