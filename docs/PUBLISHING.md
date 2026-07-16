# GitHub publishing guide

## 1. Review the release package

From the repository root, confirm that no models, simulation results, local backups, publisher PDFs, credentials, or absolute user paths are tracked:

```powershell
git status --short
git diff --cached --check
```

Also search the staged files for your user name, local drive paths, tokens, passwords, and secrets before committing.

## 2. Confirm the license

The release package contains an MIT `LICENSE` with `Copyright (c) 2026 NotPracticingGold`. Confirm that this is the intended public identity before the first commit.

Do not claim a license for third-party papers, figures, MATLAB products, or MathWorks library blocks. They are not part of this repository.

## 3. Create an empty GitHub repository

In GitHub:

1. Select **New repository**.
2. Use `simulink-power-electronics-builder` as the repository name.
3. Add a short description such as `Codex skill for safe Simulink power-electronics modeling`.
4. Select **Public** if anyone should be able to clone it.
5. Create an empty repository without an auto-generated README to avoid an unnecessary merge.

## 4. Commit locally

```powershell
cd '<PATH_TO_CLONED_OR_PREPARED_REPOSITORY>'
git init -b main
git add .
git status
git commit -m "Initial release of Simulink power electronics builder skill"
```

If Git requests your identity:

```powershell
git config user.name "YOUR NAME"
git config user.email "YOUR GITHUB EMAIL"
```

Use repository-local configuration unless you intentionally want to change Git settings for every repository.

## 5. Push to GitHub

```powershell
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/simulink-power-electronics-builder.git
git push -u origin main
```

Authenticate through Git Credential Manager, a personal access token, GitHub CLI, or the Codex GitHub plugin. Never store a token in the repository or a script.

## 6. Create the first release

After verifying the public repository:

```powershell
git tag -a v1.0.0 -m "First public release"
git push origin v1.0.0
```

Create a GitHub Release from tag `v1.0.0`. GitHub automatically provides ZIP and TAR source archives, so a separate binary package is unnecessary.

## 7. Verify from a clean clone

Clone the public repository into a different directory, copy only `skills/simulink-power-electronics-builder` into a test Codex skill directory, restart Codex, and invoke the skill explicitly. Run `tests/test_skill_helpers.m` with MATLAB R2025b if available.

For later releases, update the installed skill first, validate it, synchronize the repository copy, inspect the diff, and use semantic version tags such as `v1.0.1` or `v1.1.0`.
