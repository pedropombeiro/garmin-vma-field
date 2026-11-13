# Garmin VMA fields

Read `README.md` for build, simulator, installation, and timing behavior.

- `source/` contains shared Monkey C calculations and settings.
- `apps/{live,lap,pace}/source/` contains each data field and app entry point.
- `config/devices.txt` owns the device allowlist.
- `scripts/generate-projects.py` generates manifests, Jungle files, app resources,
  and `icons/`. Preserve app IDs when regenerating.
- Use `mise run test DEVICE` to test all three fields. Simulator tests must run
  sequentially because they share one simulator instance.
- Do not compile or package concurrently with tests. Builds for the same device
  share generated compiler outputs under `build/gen/`.
- `mise run check` builds normal, non-test binaries for representative watches.
- When adding or changing mise task arguments, include `usage` help and defaults,
  fixed `choices` for field names, and device completion from `config/devices.txt`.
  Verify help with `mise run TASK --help` and completion with
  `mise __complete_word__ --shell zsh --line 'mise run TASK PREFIX'` without
  running builds or tests. Argument-free tasks use built-in task-name completion.
- Signing keys are private and live outside the repository. Never add one to Git.
- No remote repository or Store entry is created by the build tasks. Ask before
  publishing or pushing anything.
