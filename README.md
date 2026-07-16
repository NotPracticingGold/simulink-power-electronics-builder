# Simulink Power Electronics Builder

A reusable Codex skill for safely creating, reproducing, modifying, tuning, and validating MATLAB Simulink and Simscape Electrical power-electronics models.

该技能面向 MATLAB/Simulink 电力电子建模，重点解决用户模型保护、论文拓扑复现、控制参数整定、波形验证和模型交付一致性问题。

## Highlights

- Create a verified, timestamped backup before editing an existing `.slx` model.
- Group backups by circuit under `formal-model-dir/backups/model-name/`.
- Refuse file-based automation when the loaded model contains unsaved changes.
- Preserve user-authored block positions, routing, annotations, and subsystem layout.
- Hide and verify every block name before delivering a model.
- Prefer stock Simulink and Simscape Electrical blocks for converter reproduction.
- Provide paper-reproduction, control-tuning, wiring, simulation, and waveform-figure guidance.

## Requirements

- Codex with local skill support.
- MATLAB R2025b recommended; the helper scripts are tested with MATLAB R2025b.
- Simulink.
- Simscape and Simscape Electrical for power-electronics model construction.

The bundled safety helpers only require MATLAB and Simulink. The converter-building workflow requires the Simscape products used by the target model.

## Repository layout

```text
skills/
  simulink-power-electronics-builder/
    SKILL.md
    agents/openai.yaml
    scripts/
    references/
docs/
  LITERATURE_AND_COPYRIGHT.md
  PUBLISHING.md
tests/
  test_skill_helpers.m
```

The actual skill is intentionally self-contained under `skills/simulink-power-electronics-builder`. Repository documentation remains outside the skill package.

## Installation

Clone this repository, then copy the skill folder into your personal Codex skills directory.

### Windows PowerShell

```powershell
git clone https://github.com/<YOUR_GITHUB_USERNAME>/simulink-power-electronics-builder.git
cd simulink-power-electronics-builder

$source = Join-Path $PWD 'skills\simulink-power-electronics-builder'
$target = Join-Path $HOME '.codex\skills\simulink-power-electronics-builder'
if (Test-Path -LiteralPath $target) {
    throw "Target already exists: $target. Back it up before upgrading."
}
Copy-Item -LiteralPath $source -Destination $target -Recurse
```

### macOS or Linux

```bash
git clone https://github.com/<YOUR_GITHUB_USERNAME>/simulink-power-electronics-builder.git
cd simulink-power-electronics-builder
test ! -e "$HOME/.codex/skills/simulink-power-electronics-builder"
cp -R skills/simulink-power-electronics-builder "$HOME/.codex/skills/"
```

Restart Codex after installation if the skill is not discovered immediately.

## Usage

Invoke the skill explicitly:

```text
Use $simulink-power-electronics-builder to tune this Simulink converter without changing its wiring.
```

```text
使用 $simulink-power-electronics-builder 复现这篇论文的电力电子拓扑，并在修改前创建模型备份。
```

The skill can also trigger implicitly for Simulink/Simscape power-electronics modeling tasks.

## Test the helper scripts

From the repository root:

```powershell
matlab -batch "run('tests/test_skill_helpers.m')"
```

If MATLAB is not on `PATH`, replace `matlab` with the executable path for your installation. The test creates and removes an isolated temporary model; it does not modify a user model.

## Literature and licensing

No paper PDF is required to run this skill. Do not upload publisher PDFs unless their licenses explicitly permit redistribution. See [docs/LITERATURE_AND_COPYRIGHT.md](docs/LITERATURE_AND_COPYRIGHT.md).

This repository is released under the [MIT License](LICENSE), copyright 2026 NotPracticingGold.
