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

## Layout and wiring refinement

Treat layout cleanup as a structural edit even when topology and parameters must remain unchanged:

1. Save a baseline screenshot and record the top-level block names, positions, line points, block count, and per-block adjacency.
2. Create a verified backup and a named working copy. Never experiment on the formal filename.
3. Identify exact block-overlap pairs and the smallest set of blocks that must move.
4. Preserve the existing power-stage wiring skeleton. Move repeated control, conversion, measurement, and logging groups before moving power components.
5. Save, reopen, visually inspect, compile, and compare connectivity before promotion.

### Reconstruct layout from a reference topology figure

When a paper, datasheet, or user drawing is the visual reference, use it as a layout constraint rather than merely a connectivity source:

1. Crop or render the topology figure at readable resolution and identify the main energy path, shared electrical nodes, shunt branches, isolated networks, and control-only connections.
2. Map every depicted device to the existing Simulink block before moving anything. Record the original block set, port-specific adjacency, orientations, positions, parameters, and line points.
3. Place the source, switching cells, transformer/resonant tank, rectifier, output capacitors, and load in the same relative order as the figure. Reproduce vertical shunt elements and stacked branches with matching orientations where Simscape ports permit.
4. Place switches belonging to the same cell with consistent orientation and spacing. Keep the reference figure's visual grouping even when a common node requires an orthogonal bus above or below the devices.
5. Route intentional common electrical nodes as one readable bus. Route independent nodes on visibly separated tracks; do not mistake branch-handle normalization for a topology change.
6. Place measurement and conversion blocks only after the power skeleton matches the reference. Keep them outside the main current path and connect their physical-signal ports locally.
7. Save and reopen the working copy, then compare a hidden-name screenshot against the reference figure. Reject layouts whose device order, branch direction, or functional grouping no longer resembles the source drawing.
8. Compile and compare block parameters and port-specific adjacency with the baseline before promotion. Do not use serialized line-object count as the topology criterion.

Apply these compact-sizing rules during the same pass:

- Reduce current and voltage sensor footprints when they dominate the nearby power components. Use consistent dimensions for equivalent sensors, retain recognizable icons and accessible conserving/physical-signal ports, and never overlap the measured branch.
- Reduce repeated Simulink-PS Converter blocks as a family. Keep equivalent converters the same size and align them with their destination gates or controlled sources; do not shrink only one member to solve a local collision.
- Make each MOSFET `Coss` block smaller than its associated switch and place it immediately beside or below that MOSFET as a compact parallel branch. Keep the two `Coss` connections local, avoid crossing the gate lead, and use matching size, orientation, and offset for equivalent switches.
- After any family resize, re-run block-overlap and line-geometry checks because Simulink may move port attachment points and normalize branch bends after saving.

Use these layout rules:

- Keep the main energy path readable, normally source to primary stage to transformer/tank to secondary stage to load.
- Separate control generation, gate conditioning, physical power, measurement conversion, and logging into recognizable zones.
- Permit short, necessary crossings. Reject independent signals that share or nearly share a long horizontal or vertical track.
- Do not count an intentional Simscape common node as a wiring defect merely because branch line handles contain the same geometric segment. Map candidate lines to ports and electrical nodes before changing them.
- Put a gate signal chain beside its switch gate. Align equivalent `From`, conversion, gain, and Simulink-PS blocks with consistent spacing and sizes; connect the final physical-signal line with the shortest orthogonal path.
- Resize only complete functional families. If one gate-chain converter is reduced, apply the same dimensions to the equivalent converters in the other gate chains. Preserve readable port labels.
- Rotate a block or arrange a repeated group vertically when that reduces wire length or prevents occlusion. Keep orientation consistent within the family unless port geometry requires otherwise.
- Keep logging `From`/workspace pairs compact and away from measurement terminals. Use scoped `Goto`/`From` tags for genuinely long control or measurement routes.

Avoid these failure modes:

- `Simulink.BlockDiagram.arrangeSystem` on the whole converter can turn a readable horizontal topology into a tall narrow diagram with full-height parallel buses.
- Routing every line can place gate physical-signal lines on top of switch-node, capacitor, or ground-bus segments.
- Moving blocks without replacing obsolete bend points can leave long loops even when endpoints are close.
- Clearing every geometric overlap blindly can split or distort a legitimate common electrical bus.

For a moved connection, inspect `LineHandles`, `PortConnectivity`, block `Position`, and line `Points`. Route only that connection or explicitly replace its bend points. After saving and reopening, re-run the geometry audit because Simulink can normalize branch handles and line points.

Use `scripts/audit_simulink_layout.m` as a read-only first pass. Require zero block overlaps. Review long collinear and near-parallel findings as candidates, not automatic failures. The visual acceptance criterion is no block occlusion, no independent long-distance line covering, compact local control wiring, and a clear main power path.

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
- No top-level blocks overlap; equivalent signal-module families have consistent sizes and spacing.
- Independent control or measurement signals do not cover each other over long runs. Necessary crossings and intentional same-node buses are acceptable.
- A verified pre-edit backup exists under `backups/<model-name>/`.
