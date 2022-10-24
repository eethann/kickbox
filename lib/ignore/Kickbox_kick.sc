Kickbox_kick {

	var <kick, <params, <kick_bus;

	*initClass {

		StartUp.add {
      // TODO should this be context instead
			var s = Server.default;

			s.waitForBoot {

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
          out_sig = ((sin_osc * contour_env) + (mod_osc * body_mod_amp * body_env)) * amp;
          Out.ar(out,[out_sig,out_sig]);

          // Free when all envs are done
          FreeSelf.kr(if((click_env + body_env + contour_env) > 0, 0, 1))

        }).add;

			} // s.waitForBoot
		} // StartUp
	} // *initClass

	*new {
		^super.new.init;  // ...run the 'init' below.
	}

	init {
		var s = Server.default;

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

		// Instantiate ongoing synth
		// passthrough = Synth.new(\porousPassthrough, [
		// 	\amp1, 1,
		// 	\amp2, 1
		// ]);

		s.sync; // sync the changes above to the server
	}

  trig {
    |amp, sources_group|
    Synth.new(\kickbox_kick, args: params.getPairs ++ [kick, \out, kick_bus], target: sources_group)
  }
	// create a command to control the synth's 'amp' value:
	// setAmp1 { arg amp;
	// 	passthrough.set(\amp1, amp);
	// }

	// IMPORTANT!
	// free our synth after we're done with it:
	free {
		// passthrough.free;
	}

}
