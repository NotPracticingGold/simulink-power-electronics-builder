# Power-electronics Simulink workflow

## Paper reproduction

Extract and record these items before opening Simulink:

- source citation, topology figure, rated input/output, power, and load;
- switch arrangement, rectifier type, transformer ratio convention, and grounding;
- switching/resonant frequencies, dead time, modulation, and control bandwidth;
- `Lr`, `Cr`, `Lm`, transformer leakage assumptions, output capacitors, ESR, and device loss parameters;
- equations used for gain, quality factor, soft-switching boundaries, and current stress;
- experimental operating points and waveform scales;
- missing values that require explicit simulation assumptions.

Keep paper values and tuned simulation values in separate model-workspace variables or a project note. Do not silently change a paper parameter to force agreement.

## Model construction

Prefer stock Simscape Electrical devices and sensors. Include one electrical reference per isolated physical network, Solver Configuration blocks as required, explicit parasitics needed for numerical stability, and physically meaningful initial capacitor voltages.

Lay out the model in this order where practical:

1. references and input source;
2. gate/control generation;
3. primary power stage;
4. transformer and resonant tank;
5. secondary rectifier and output filter;
6. measurements and logging.

Use `Goto`/`From` for long control and measurement signals. Keep physical conserving connections visible and short. Never use automatic arrangement on a user-laid-out model unless requested.

## Safe edits

For an existing model:

1. Confirm the user saved GUI edits.
2. Inspect the disk file without saving.
3. Create and byte-verify the model-specific backup.
4. Make the narrowest requested edit.
5. Compile and simulate a working copy when the edit is structural.
6. Hide and verify all block names.
7. Preserve the backup and report its path.

Parameter-only changes must not alter blocks, lines, positions, annotations, or routing. Capture pre/post parameter values in the handoff.

## Controller tuning

Measure a baseline using identical windows before changing parameters. Separate:

- average-value regulation error;
- low-frequency closed-loop oscillation or overshoot;
- switching-frequency ripple;
- numerical noise caused by solver step size.

Tune feedforward, filters, PI gains, saturations, anti-windup, and dead time only within the requested scope. Switching ripple normally requires changes to switching frequency or energy-storage components; do not misattribute it to PI gains.

For input steps, report pre-step steady state, peak deviation, settling time, post-step steady state, duty limits, and current peaks. Check gate complementarity and dead time at both operating points.

## Waveform figures

Create a high-resolution PNG using a compact `tiledlayout`, normally with:

1. full-duration `Vin`, intermediate/bus voltage, and `Vout`;
2. zoomed steady-state voltage ripple before and after the step;
3. all inductor currents over the transient;
4. zoomed resonant and magnetizing currents over several switching cycles;
5. regulator gate signals over several regulator cycles;
6. main-bridge gate signals over several main switching cycles.

Use SI units, descriptive legends, aligned time axes, light grids, consistent colors, and titles identifying the operating point. Export at 180 dpi or higher. Avoid plotting millions of points when decimation preserves switching edges and extrema.

## Minimum validation

- Model update completes without unresolved blocks or invalid connections.
- Requested simulation time and step time are stored in the formal model.
- Output regulation and power balance are credible.
- Peak/RMS currents and device voltage stress are within expected ranges.
- Complementary gates do not overlap.
- Solver warnings and initialization conflicts are resolved or documented.
- Every block has `ShowName='off'` in the saved formal model.
- A verified pre-edit backup exists under `backups/<model-name>/`.
