#!/usr/bin/env python3
"""Build normal binaries and install them on a model-verified Garmin watch."""

import argparse
import json
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIELDS = ("live", "lap", "pace")


def run(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def identity(path, profile):
    model = ET.parse(path).getroot().find("{*}Model")
    if model is None:
        raise ValueError("GarminDevice.xml has no Model element.")
    part = model.findtext("{*}PartNumber")
    allowed = {entry["number"] for entry in profile["partNumbers"]}
    if part not in allowed:
        raise ValueError(
            f"Connected watch does not match {profile['displayName']}: "
            f"part number {part!r}. No files transferred."
        )
    unit_id = ET.parse(path).getroot().findtext("{*}Id")
    if not unit_id:
        raise ValueError("GarminDevice.xml has no device ID; refusing to install.")
    return part, unit_id


class MountedWatch:
    def __init__(self, mount):
        self.garmin = mount.resolve() / "GARMIN"

    def read_identity(self, destination):
        shutil.copyfile(self.garmin / "GarminDevice.xml", destination)

    def check_destination(self, names, overwrite):
        apps = self.garmin / "APPS"
        if not apps.is_dir():
            raise ValueError("The watch has no GARMIN/APPS directory.")
        existing = {path.name.casefold() for path in apps.iterdir()}
        if not overwrite and any(name.casefold() in existing for name in names):
            raise ValueError(
                "An app already exists. Rerun with --overwrite to replace it."
            )

    def push(self, source, overwrite):
        destination = self.garmin / "APPS" / source.name
        # Exclusive create also protects against a file appearing after preflight.
        with (
            destination.open("wb" if overwrite else "xb") as output,
            source.open("rb") as data,
        ):
            shutil.copyfileobj(data, output)


class MtpWatch:
    def __init__(self, index):
        if not shutil.which("garmin-mtp"):
            raise ValueError(
                "Install garmin-mtp first (see README.md), or use --mount PATH "
                "for a mounted watch. Close Garmin Express and OpenMTP before using MTP."
            )
        if index is None:
            devices = run("garmin-mtp", "devices")
            indices = re.findall(r"^\[(\d+)\]", devices, flags=re.MULTILINE)
            if len(indices) != 1:
                raise ValueError(
                    "Expected exactly one MTP device. Connect the watch, or select "
                    "one with --device-index (see garmin-mtp devices)."
                )
            index = int(indices[0])
        self.command = ("garmin-mtp", "--device-index", str(index))

    def read_identity(self, destination):
        # The CLI refuses to overwrite local downloads, so remove only our
        # temporary metadata copy before refreshing it.
        destination.unlink(missing_ok=True)
        run(*self.command, "pull", "/GARMIN/GarminDevice.xml", str(destination))

    def check_destination(self, names, overwrite):
        run(*self.command, "list", "/GARMIN/APPS")
        # garmin-mtp itself refuses existing filenames without --overwrite.

    def push(self, source, overwrite):
        flags = ("--overwrite",) if overwrite else ()
        run(*self.command, "push", *flags, str(source), "/GARMIN/APPS")


def install(args):
    if args.mount and args.device_index is not None:
        raise ValueError("Use either --mount or --device-index, not both.")
    devices = (ROOT / "config/devices.txt").read_text().split()
    if args.device not in devices:
        raise ValueError(f"Unsupported watch model: {args.device}")
    profiles = Path.home() / "Library/Application Support/Garmin/ConnectIQ/Devices"
    profile = json.loads((profiles / args.device / "compiler.json").read_text())
    watch = MountedWatch(args.mount) if args.mount else MtpWatch(args.device_index)
    fields = FIELDS if args.field == "all" else (args.field,)
    # Stable filenames do not accumulate model-specific duplicates on the watch.
    names = [f"VMA-{field.upper()}.PRG" for field in fields]
    with tempfile.TemporaryDirectory(prefix="garmin-vma-install-") as directory:
        staging = Path(directory)
        metadata = staging / "GarminDevice.xml"
        watch.read_identity(metadata)
        original = identity(metadata, profile)
        watch.check_destination(names, args.overwrite)
        print(
            f"Verified {profile['displayName']}. Building {', '.join(fields)}.",
            flush=True,
        )
        for field, name in zip(fields, names, strict=True):
            # Always rebuild without -t. Do not install a previous test binary.
            subprocess.run(
                [str(ROOT / "scripts/ciq"), "build", field, args.device],
                cwd=ROOT,
                check=True,
            )
            shutil.copyfile(
                ROOT / "build" / f"vma-{field}-{args.device}.prg", staging / name
            )
        for name in names:
            # A build can take time: reject a watch swap before each transfer.
            watch.read_identity(metadata)
            if identity(metadata, profile) != original:
                raise ValueError("The connected watch changed. Installation stopped.")
            watch.push(staging / name, args.overwrite)
            print(f"Installed {name}.", flush=True)
    print("Disconnect the watch, then add the fields under Data Screens > Connect IQ.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("field", nargs="?", choices=("all", *FIELDS), default="all")
    parser.add_argument("device", nargs="?", default="fr970")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--device-index", type=int)
    parser.add_argument("--mount", type=Path)
    args = parser.parse_args()
    try:
        install(args)
    except subprocess.CalledProcessError as error:
        parser.exit(1, f"Installation stopped: {error.stderr or error}\n")
    except (OSError, ValueError, KeyError, ET.ParseError) as error:
        parser.exit(1, f"Installation stopped: {error}\n")


if __name__ == "__main__":
    main()
