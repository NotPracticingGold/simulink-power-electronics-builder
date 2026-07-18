# MATLAB MCP and Simulink Agentic Toolkit workflow

Use this reference only when deciding on or executing the MCP/SATK path.

## Decision checklist

Use MCP/SATK if any answer is yes:

- Did the user explicitly request MATLAB MCP, Simulink Agentic Toolkit, `model_edit`, `model_read`, or `model_check`?
- Is the model unfamiliar enough that block IDs, hierarchy, connectivity, or physical port domains must be inspected before editing?
- Must structural edits be captured as bounded, machine-readable operations?
- Is a structured topology or health report part of the deliverable?
- Are two construction toolchains being compared while electrical content must stay invariant?

Prefer direct MATLAB if all answers are no and the task is limited to known parameter changes, layout preservation, backup, name hiding, simulation, plotting, or a deterministic new-model builder.

Prefer hybrid mode when construction is large but only the final structure needs MCP evidence.

## Token-efficient MCP sequence

1. Confirm MATLAB R2025b, Simulink, Simscape Electrical, MATLAB MCP Server, and SATK availability.
2. Run `satk_initialize` in the intended MATLAB session. For `existing` mode, ensure `shareMATLABSession` uses that same session.
3. Confirm the SATK block-policy/custom-library prerequisite. If only stock MathWorks blocks are permitted, record `confirmed_none` through the official SATK configuration API; do not hand-write policy JSON.
4. Inspect before editing:
   - Start with `model_overview` for an unfamiliar large model.
   - Use `model_read` with `depth="0"` or a targeted subsystem first.
   - Use `model_query_params` only for parameters not already returned.
5. Build a single bounded edit plan for one scope.
6. Execute related structural work in as few `model_edit` calls as practical:
   - Use `layout_mode="full"` only for an empty scope.
   - Use `layout_mode="incremental"` for an existing laid-out scope.
   - Use `ref`/`#ref` to connect blocks created in the same call.
   - Keep the operations argument single-line JSON.
7. Use `->` for Simulink signals and `<->` for Simscape conserving or physical-signal connections.
8. Run one targeted `model_read` after editing and one final `model_check` with the required checks.
9. Compile and simulate through the normal validation workflow. `model_check` does not replace numerical simulation.
10. Save compact reports to files. Summarize results instead of returning the entire model graph repeatedly.

## New-model construction notes

- Use a valid Simulink model name beginning with a letter. Names beginning with `_` are invalid.
- If `model_edit` requires an existing diagram, create and save an empty `.slx` container first. Do not populate it with direct structural APIs.
- Use stock block types and explicit names. Keep parameters identical when comparing direct and MCP construction routes.
- For a fair toolchain comparison, electrical topology, component values, control timing, solver settings, initial conditions, and layout targets must match. Only the construction and audit mechanism should differ.
- Positioning may be adjusted after structural creation only because the user explicitly requested a reference-oriented layout. Do not use this exception to rebuild or reroute unrelated user wiring.

## Simscape port rules

- Read `physical_ports` from `model_read` when a port role is uncertain.
- Typical patterns:
  - Two-terminal element: `LConn1` and `RConn1`.
  - Ideal switching MOSFET: gate `LConn1`, drain `RConn1`, source `RConn2`.
  - Current/voltage sensor: electrical positive `LConn1`, physical output `RConn1`, electrical negative `RConn2`.
  - Simulink-PS Converter: Simulink input `u1`, physical output `RConn1`.
  - PS-Simulink Converter: physical input `LConn1`, Simulink output `y1`.
- A conserving port may branch to several components. Rewiring an existing port requires disconnecting the old branch first.
- Give isolated primary and secondary electrical networks their required Electrical Reference blocks.

## MCP availability and session failures

Installation success does not guarantee that the current Codex task exposes the seven Simulink model tools. Check callable tools before designing the workflow.

For `existing` mode:

1. Run `satk_initialize` in the intended MATLAB session.
2. Confirm the connector is running and call `shareMATLABSession` if needed.
3. Retry attachment once after reinitialization.
4. If attachment still fails, do not start multiple hidden MATLAB sessions. Multiple stale sessions increase ambiguity and resource use.
5. If the user did not mandate MCP, fall back to direct MATLAB and state that the MCP audit was unavailable.
6. If MCP is mandatory, pause and ask the user to keep one MATLAB R2025b session open, run `satk_initialize`, and confirm it is ready.

When the base MATLAB MCP tools are available but the Simulink model tools are not listed, it is acceptable to call the installed SATK functions from the MCP-connected MATLAB session, provided:

- all structural changes still go through `model_edit`;
- `model_read` and `model_check` are executed afterward;
- direct `add_block`, `add_line`, or structural `set_param` is not used to imitate the MCP path;
- the handoff accurately states how the functions were invoked.

## Conditions that never justify MCP

Do not select MCP solely because it is newer, installed, or perceived as more capable. Do not use it to:

- avoid creating a backup;
- edit an unsaved GUI model from another process;
- reroute a user layout without authorization;
- claim numerical correctness without simulation;
- print a full model graph when a small scope answers the question;
- run duplicate direct and MCP builds when the user asked for only one result.

## Required handoff evidence

State:

- why MCP, direct, or hybrid mode was selected;
- which model and scope were edited;
- whether `model_edit`, `model_read`, and `model_check` ran;
- the final structural health status;
- compile/simulation results and waveform paths;
- any MCP/session limitation or fallback;
- Token-sensitive choices such as scoped reads or batched edits.
