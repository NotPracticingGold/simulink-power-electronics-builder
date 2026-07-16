---
name: simulink-power-electronics-builder
description: Safely create, reproduce, modify, tune, diagnose, and validate MATLAB Simulink and Simscape Electrical power-electronics models (.slx), especially paper-reproduction models, LLC and resonant converters, isolated DC-DC converters, PWM/control systems, wiring cleanup, parameter tuning, and waveform export with MATLAB 2025b. Use whenever Codex must build a new Simulink converter model or change an existing model while preserving user layout, creating recoverable backups, hiding all block names, and verifying simulation results.
---

# Simulink Power Electronics Builder

Use MATLAB 2025b and stock Simulink/Simscape Electrical blocks to produce reproducible power-electronics models without risking user-authored layout changes.

## Enforce the safety contract

1. Treat the formal `.slx` file as user data. Never delete, regenerate, or overwrite it before creating a verified backup.
2. Before every edit to an existing model, run `scripts/backup_simulink_model.m`. Store backups under `<formal-model-dir>/backups/<model-name>/` with a timestamp and reason.
3. If the user has manually edited the model, assume the GUI may contain unsaved work. Ask the user to save it or save it as a recovery copy before starting a separate MATLAB batch process. Do not infer that the on-disk file is current.
4. Do not run a builder script against an existing user-modified formal model. Build to a new working filename, or edit only the requested parameters in the backed-up formal file.
5. For parameter-only requests, change only model-workspace variables or requested block parameters. Do not add/delete blocks, reroute lines, call automatic layout functions, or rebuild the model.
6. Preserve block positions, line points, annotations, subsystem boundaries, masks, and signal-routing choices unless the user explicitly asks to change them.
7. Hide every block name in every newly created formal model. Also keep names hidden after later modifications. Run `scripts/hide_and_verify_block_names.m` and require `visible_name_count == 0` before handoff.
8. Never silently promote a working copy to the formal filename. Back up the formal file first, validate the working copy, then state exactly which file is being promoted.

## Run the workflow

### 1. Preflight

- Identify the exact formal model path and MATLAB executable.
- Run `scripts/inspect_simulink_model.m` without saving the model.
- Record file size, modification time, loaded/dirty state when observable, stop time, block count, and visible-name count.
- If a MATLAB GUI session may own unsaved changes, pause and request a save. A separate MATLAB process cannot inspect another session's dirty model reliably.
- Create the timestamped backup before the first mutation.

### 2. Choose the edit mode

- **New model:** create a unique `.slx` filename, use stock library blocks, and hide names before the first formal handoff.
- **Existing parameter edit:** load the backed-up file, update only scoped parameters, save once, and verify without rebuilding.
- **Structural edit:** work on a named copy first. Preserve the formal model until the copy compiles and simulates successfully.
- **Paper reproduction:** extract the topology, operating modes, equations, component table, control law, operating points, and expected waveforms before building. Record assumptions that the paper does not specify.

Read `references/power-electronics-workflow.md` when reproducing a paper, tuning a controller, organizing control wiring, or generating waveform figures.

### 3. Build or modify

- Prefer existing Simulink and Simscape Electrical components over MATLAB Function, S-Function, or custom masked blocks.
- Use short physical power-stage wires. Replace long control/measurement routes with scoped `Goto`/`From` terminals using stable tags.
- Keep gate generation, measurement conversion, control, power stage, and logging visually separated.
- Use model-workspace parameters rather than scattering numeric literals across block masks.
- Preserve paper values separately from simulation-only assumptions and tuned values.
- For controller tuning, collect a baseline first, change one parameter group at a time, and compare the same steady-state and transient windows.
- Do not claim control tuning reduced switching ripple when the ripple is physically set by capacitance, inductance, or switching frequency. Explain when a component or frequency change is required.

### 4. Validate

- Compile with `set_param(model,'SimulationCommand','update')`.
- Simulate all required operating points and transients with the requested stop/step times.
- Check voltage regulation, ripple, current peaks/RMS, duty limits, complementary gates/dead time, device stress, power balance, and solver warnings.
- Compare results with paper equations and experimental plots; label idealized-model efficiency separately from measured hardware efficiency.
- Generate figures with `tiledlayout`: full transient voltages, steady-state voltage zoom, all inductor currents, resonant-current zoom, and gate signals. Use consistent units, legends, grids, and an exported high-resolution PNG.
- Run `scripts/hide_and_verify_block_names.m` last. Reopen read-only with `scripts/inspect_simulink_model.m` and require zero visible names.
- Confirm a valid pre-edit backup exists in the model-specific backup folder.

### 5. Hand off

Report the formal model path, backup path, working-copy path if used, exact parameter changes, simulation metrics, plot paths, assumptions, and remaining limitations. Never describe a model as recovered unless the recovered artifact was opened and verified.

## Use the bundled scripts

From MATLAB, add the skill script folder to the path and call:

```matlab
skillDir = '<path-to-simulink-power-electronics-builder>';
addpath(fullfile(skillDir, 'scripts'));
report = inspect_simulink_model(modelPath);
backupPath = backup_simulink_model(modelPath, "control-tuning");
nameReport = hide_and_verify_block_names(modelPath, false);
```

Pass `false` to the final function only when a valid backup was already created immediately before the edit. Otherwise retain its default backup behavior.
