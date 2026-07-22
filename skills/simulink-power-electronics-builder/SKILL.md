---
name: simulink-power-electronics-builder
description: Safely create, reproduce, modify, lay out, route, tune, diagnose, and validate MATLAB Simulink and Simscape Electrical power-electronics models (.slx), optionally using MATLAB MCP and the Simulink Agentic Toolkit for model_edit/model_read/model_check workflows and machine-readable audits. Use for paper reproduction, LLC and resonant converters, isolated DC-DC converters, PWM/control systems, layout and wiring cleanup, parameter tuning, waveform export, or any model change that must preserve user-authored layout, create recoverable backups, hide block names, and verify MATLAB 2025b simulation results.
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
9. For layout or wiring edits, capture a baseline image and work on a named copy. Preserve the top-level block set, connectivity, parameters, subsystem boundaries, and unaffected line points.
10. Do not globally call `arrangeSystem` or route every line on a user-laid-out power model. Prefer explicit positions and routing only for moved blocks. Reject an automatic result that creates a tall/narrow canvas, long return loops, or parallel buses spanning the model.

## Select the MATLAB and MCP path

Choose the lowest-cost path that still provides the required evidence.

| Path | Select when | Avoid when |
|---|---|---|
| **Direct MATLAB + this skill** | Creating a new model with a deterministic builder; changing known parameters; preserving or repairing a user layout; running simulations, sweeps, backups, name hiding, and waveform export | The user explicitly requires MCP/SATK or the topology and port domains are unknown and need structured inspection |
| **MATLAB MCP + Simulink Agentic Toolkit** | The user explicitly requests MCP/SATK; structural edits must use `model_edit`; an unfamiliar model needs `model_overview`/`model_read`; Simscape port domains must be discovered; or a machine-readable `model_check` audit is a deliverable | A small parameter-only or layout-only task; a strict Token/latency budget; unsaved GUI work; or an unhealthy/unavailable MCP session |
| **Hybrid (preferred for complex delivery)** | Use direct scripts for backup, paper extraction, simulation, plots, and compact parameter sweeps; use MCP only for scoped structural edits and final topology/health audit | Do not duplicate every action through both paths merely to claim MCP usage |

Apply these rules:

1. If the user explicitly requests or forbids MCP, obey that choice.
2. Default to direct MATLAB for known, localized work. MCP is not required merely because it is installed.
3. Prefer hybrid mode for a complex paper reproduction: construct efficiently, then run one targeted `model_read` and one `model_check` before handoff.
4. Do not use MCP to bypass the backup, dirty-model, layout-preservation, hidden-name, compile, or simulation requirements.
5. Treat Token cost as a design constraint. Use `model_overview` before `model_read`, request the smallest useful scope/depth, batch related `model_edit` operations, and never repeatedly print a full large-model graph.
6. If Simulink MCP tools are not exposed but MATLAB MCP is connected and SATK is initialized, invoke SATK `model_edit`, `model_read`, and `model_check` inside that MCP-connected MATLAB session. Never replace structural `model_edit` operations with `add_block`, `add_line`, or structural `set_param` calls in this path.
7. If `existing` session attachment fails after one clean `satk_initialize`/`shareMATLABSession` retry, stop spawning sessions. Record the failure, clean up only agent-created MATLAB processes, and use direct MATLAB unless the user explicitly requires MCP.

Read `references/mcp-satk-workflow.md` whenever MCP/SATK is requested, considered, or used.

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
- **Layout/wiring edit:** keep the topology and parameters invariant, move only conflicting blocks, reroute only affected connections, audit geometry after saving and reopening, then promote the validated copy.
- **Paper reproduction:** extract the topology, operating modes, equations, component table, control law, operating points, and expected waveforms before building. Record assumptions that the paper does not specify.

Read `references/power-electronics-workflow.md` when reproducing a paper, tuning a controller, organizing control wiring, or generating waveform figures.

Read `references/interleaved-iibbl-llc-notes.md` when building, repairing, or tuning an interleaved integrated Buck-Boost-LLC converter, especially ISOP 9 kW GaN models with a reused LLC primary bridge, four full-wave secondary rectifier cells, ZVS qualification, or loss breakdowns.

### 3. Build or modify

- Prefer existing Simulink and Simscape Electrical components over MATLAB Function, S-Function, or custom masked blocks.
- Use short physical power-stage wires. Replace long control/measurement routes with scoped `Goto`/`From` terminals using stable tags.
- Keep gate generation, measurement conversion, control, power stage, and logging visually separated.
- When a paper or reference schematic is supplied, treat its power-topology figure as the layout contract: preserve the depicted left-to-right energy path, relative device order, branch placement, and component orientation unless Simscape port geometry makes a small deviation necessary.
- Allow necessary wire crossings, but eliminate long collinear covering and closely spaced parallel runs between independent signals. Preserve a single visible common bus when multiple Simscape branches belong to the same electrical node.
- Place gate-conditioning and Simulink-PS conversion chains beside the corresponding gate ports. Use short orthogonal paths instead of routing gate signals around the switching stage.
- Resize signal blocks only by functional family: use the same size for equivalent gate-chain blocks, logging blocks, repeated sensors, and repeated converters. Current/voltage sensors and Simulink-PS Converter blocks may be reduced to make the schematic compact, but apply a visually consistent size to equivalent blocks and keep ports and icon content readable.
- Draw each MOSFET output capacitance compactly beside its associated switch. Make repeated `Coss` blocks consistently smaller than the MOSFETs, orient them as local parallel branches, and keep both connections short without covering gate wiring or the main bus.
- Preserve user-authored power wiring whenever possible. Move the smallest conflict set, keep unaffected line points unchanged, and inspect the result visually after save/reload.
- Use model-workspace parameters rather than scattering numeric literals across block masks.
- Preserve paper values separately from simulation-only assumptions and tuned values.
- For controller tuning, collect a baseline first, change one parameter group at a time, and compare the same steady-state and transient windows.
- Do not claim control tuning reduced switching ripple when the ripple is physically set by capacitance, inductance, or switching frequency. Explain when a component or frequency change is required.

### 4. Validate

- Compile with `set_param(model,'SimulationCommand','update')`.
- For layout edits, run `scripts/audit_simulink_layout.m`. Require zero block overlaps and zero visible names. Treat long-line findings as candidates: map their endpoints and retain intentional same-node buses.
- Verify the top-level block names and per-block adjacency are unchanged. Do not use line-object count alone because saving or branch normalization can merge or split line handles without changing connectivity.
- Simulate all required operating points and transients with the requested stop/step times.
- Check voltage regulation, ripple, current peaks/RMS, duty limits, complementary gates/dead time, device stress, power balance, and solver warnings.
- Compare results with paper equations and experimental plots; label idealized-model efficiency separately from measured hardware efficiency.
- Generate figures with `tiledlayout`: full transient voltages, steady-state voltage zoom, all inductor currents, resonant-current zoom, and gate signals. Use consistent units, legends, grids, and an exported high-resolution PNG.
- Run `scripts/hide_and_verify_block_names.m` last. Reopen read-only with `scripts/inspect_simulink_model.m` and require zero visible names.
- Confirm a valid pre-edit backup exists in the model-specific backup folder.
- When MCP/SATK is selected, retain compact evidence of the final `model_read` scope and require `model_check` to report a healthy structure or document every intentional warning.

### 5. Hand off

Report the formal model path, backup path, working-copy path if used, selected access path (direct, MCP, or hybrid), exact parameter changes, simulation metrics, plot paths, assumptions, and remaining limitations. For MCP work, report which of `model_edit`, `model_read`, and `model_check` actually ran. Never describe a model as recovered unless the recovered artifact was opened and verified.

## Use the bundled scripts

From MATLAB, add the skill script folder to the path and call:

```matlab
skillDir = '<path-to-simulink-power-electronics-builder>';
addpath(fullfile(skillDir, 'scripts'));
report = inspect_simulink_model(modelPath);
backupPath = backup_simulink_model(modelPath, "control-tuning");
layoutReport = audit_simulink_layout(modelPath);
nameReport = hide_and_verify_block_names(modelPath, false);
```

Pass `false` to the final function only when a valid backup was already created immediately before the edit. Otherwise retain its default backup behavior.
