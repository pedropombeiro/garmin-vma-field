# Garmin VMA fields

Three independent Connect IQ data fields for running with maximum aerobic speed
(VMA, also called MAS or vVO2max). Add them to ordinary activity screens alongside
Garmin's heart rate, pace, distance, and timer fields.

| Field | Watch display | FIT recording |
| --- | --- | --- |
| `VMA` | Live %VMA, 3-second average | %VMA chart |
| `Lap VMA` | Lap distance / timer time, as %VMA | Lap average %VMA |
| `VMA pace range` | Fast-to-slow pace range for two chosen percentages | None |

Defaults: **15 km/h VMA**, with a **75-88%** target range. The pace field shows
`4:33-5:20`, always in minutes per kilometer. Its label identifies the percentages
and `/km`. This is a fixed reference range, not the current workout step's target.

## Build

Requirements:

- [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), an installed
  SDK, and the device profiles in `config/devices.txt`.
- [mise](https://mise.jdx.dev/). The project pins Java 21 without changing your
  global Java configuration.
- Python 3 to regenerate project metadata after changing the device list.
- [1Password CLI](https://developer.1password.com/docs/cli/) with access to the
  signing-key document in your Private vault.

1. Install the project runtime:

   ```shell
   mise trust
   mise install
   ```

1. Build a field:

   ```shell
   mise run build live fr970
   mise run build lap fr970
   mise run build pace fr970
   mise run build live venu3s
   ```

   Outputs are `build/vma-FIELD-DEVICE.prg`.

The scripts find the current SDK through SDK Manager's macOS configuration.
Set `CIQ_SDK_HOME` to override it. Builds retrieve the signing key from the
**Garmin VMA fields signing key** document in 1Password's **Private** vault.
Set `CIQ_SIGNING_KEY_ITEM` and `CIQ_SIGNING_KEY_VAULT` to override the
document title or ID and vault. You might need to approve access in 1Password.

Each invocation downloads the key into a private temporary directory with mode
`0600`, validates it, and removes it on exit, including ordinary errors and
interruptions. No persistent key is generated or used. A forced kill or system
crash can prevent cleanup. Keep the original 1Password document: Store updates
need the same signing identity.

## Test and simulate

```shell
mise run test fr970
mise run test venu3s
mise run check
mise run sim live fr970
mise run sim pace venu3s
```

`test` runs all three apps' tests sequentially in Garmin's simulator. Tests cover
the calculations, timestamp-based smoothing, missing speeds, pause handling,
lap boundaries, settings reload, FIT field creation and updates, and pace
rounding. `check` compiles all three fields for the FR970, Venu 3S, Venu 2S,
Instinct 2S, and FR55.

In the simulator, use **Simulation > FIT Data** to replay a FIT file and check the
display with realistic speed changes. Check manual laps and automatic laps, and
inspect the recorded activity in Garmin Connect after an actual watch run.
Calculation tests do not establish device FIT output or visual fit in every slot.

SDK 9.3.0 can return a nonzero `monkeydo` exit code even when its test summary
reports success. The test task requires an explicit summary with zero failures
and zero errors.

## Install on a watch

The install task builds normal binaries, verifies the connected watch's model
and device ID, and copies only the selected fields:

```shell
mise run install all fr970
mise run install live venu3s
mise run install all fr970 --overwrite
```

Existing files require `--overwrite`. The task uses stable names such as
`VMA-LIVE.PRG`. If you previously copied differently named binaries manually,
remove those copies manually to avoid duplicate apps.

For MTP on macOS, install
[Garmin MTP CLI](https://github.com/Likenttt/garmin-mtp-cli) and its dependencies
using its build instructions (`brew install libmtp pkgconf`, then build and
install the CLI). Ensure `garmin-mtp` is on `PATH`. Close Garmin Express and
OpenMTP before using the task. It does not install dependencies or close apps.

If multiple USB MTP devices are connected, use `garmin-mtp devices` and select
one with `--device-index INDEX`. A normally mounted watch instead supports:

```shell
mise run install all fr970 --mount /Volumes/GARMIN
```

Model verification uses `GARMIN/GarminDevice.xml` and the downloaded SDK device
profile. Disconnect the watch after installation, then add the fields under
the activity's **Data Screens > Connect IQ** settings. Transfers are sequential,
not transactional: if a later transfer fails, earlier fields remain installed.

To test installation logic without a connected watch or 1Password access:

```shell
python3 -m unittest discover -s tests -p 'test_*.py'
```

Alternatively, install manually:

1. Build each desired field for that exact watch model. If you just ran tests,
   build again to replace the test-enabled binary.
1. Connect the watch over USB and copy its `.prg` files into `GARMIN/APPS`.
   For MTP devices on macOS, use a client such as OpenMTP. Close Garmin Express
   if it prevents another client from connecting.
1. Disconnect the watch. In the activity's data-screen settings, select a slot,
   open **Connect IQ**, and choose the field.

Each field has a separate app ID, so it can occupy a separate slot alongside
standard fields. Your watch's per-activity Connect IQ limit still applies.
The long pace-range string might need a wider slot than either percentage field.

## Change settings

Each app has its own VMA setting. Change all installed fields when your VMA
changes. The pace app also has lower and upper percentage settings. An inverted
range displays `--`.

For Store-installed apps, use the Connect IQ app or Garmin Express. For local
testing, use the simulator's app-settings editor. Do not assume that phone app
settings are available for USB-sideloaded apps. For a personal sideloaded build,
change the defaults in `resources/resources.xml` and
`apps/pace/resources/resources.xml` before building. Existing on-watch settings
can override compiled defaults.

## Timing and missing data

- The live field averages available speed samples with timer timestamps in the
  last 3 seconds. It resets on pauses, stops, missing speed, zero speed, timer
  resets, and gaps of 3 seconds or more. It shows `--` while stationary or when
  speed is unavailable. FIT records a known stationary speed as `0%`, and an
  unknown speed as FIT's invalid `UINT16` value.
- Lap averages use **timer time**, not moving time. Pauses are excluded, but
  standing still with the timer running lowers the average. No activity or
  Auto Pause setting is changed by these fields.
- A lap event resets the baseline after Garmin writes the previous lap record.
  The last computed lap value is recorded, so a lap boundary between updates can
  differ slightly from Garmin's native final lap average.
- If the lap field starts partway through an activity, it shows `--` until the
  next lap boundary because Connect IQ does not supply the earlier lap baseline.
- VMA changes apply immediately. For consistent lap summaries, change VMA
  between activities.

## Supported watches and packages

`config/devices.txt` is the explicit device allowlist. It covers modern
Forerunner, Venu, vívoactive, fēnix, epix, Enduro, Instinct, MARQ, and D2 watches,
including the FR970 and Venu 3S. The minimum API level is `3.2.0`.

After editing the list, download the matching profiles and run:

```shell
python3 scripts/generate-projects.py
mise run package
```

The generator updates all three manifests, Jungle build files, app resources,
and device-sized launcher icons. It preserves app IDs. Package outputs are
`build/vma-live.iq`, `build/vma-lap.iq`, and `build/vma-pace.iq`. Packaging builds
all listed products and their SDK variants. It does not publish anything.
