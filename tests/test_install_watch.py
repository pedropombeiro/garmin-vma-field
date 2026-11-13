"""Exercise installation with temporary directories and mocked USB/build commands."""

import argparse
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "install_watch", Path(__file__).resolve().parents[1] / "scripts/install-watch.py"
)
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.watch = self.root / "watch"
        (self.watch / "GARMIN/APPS").mkdir(parents=True)
        self.metadata = self.watch / "GARMIN/GarminDevice.xml"
        self.write_identity()
        (self.root / "config").mkdir()
        (self.root / "config/devices.txt").write_text("fr970\n")
        (self.root / "build").mkdir()
        profile = (
            self.root / "Library/Application Support/Garmin/ConnectIQ/Devices/fr970"
        )
        profile.mkdir(parents=True)
        (profile / "compiler.json").write_text(
            json.dumps(
                {"displayName": "FR970", "partNumbers": [{"number": "006-B4565-00"}]}
            )
        )
        self.args = argparse.Namespace(
            mount=self.watch,
            device_index=None,
            device="fr970",
            field="all",
            overwrite=False,
        )

    def write_identity(self, part="006-B4565-00", unit="123"):
        self.metadata.write_text(
            f'<Device xmlns="urn:garmin"><Model><PartNumber>{part}</PartNumber>'
            f"</Model><Id>{unit}</Id></Device>"
        )

    def fake_build(self, command, **kwargs):
        self.assertEqual(command[1], "build")
        (self.root / "build" / f"vma-{command[2]}-fr970.prg").write_bytes(b"normal app")

    def install(self, build=None):
        with (
            patch.object(installer, "ROOT", self.root),
            patch.object(Path, "home", return_value=self.root),
            patch.object(
                installer.subprocess, "run", side_effect=build or self.fake_build
            ),
        ):
            installer.install(self.args)

    def test_all_fields_are_built_and_copied(self):
        self.install()
        for field in installer.FIELDS:
            self.assertEqual(
                (self.watch / f"GARMIN/APPS/VMA-{field.upper()}.PRG").read_bytes(),
                b"normal app",
            )

    def test_wrong_model_never_builds_or_writes(self):
        self.write_identity(part="wrong")
        with self.assertRaisesRegex(ValueError, "does not match"):
            self.install(build=lambda *_args, **_kwargs: self.fail("Build was invoked"))
        self.assertEqual(list((self.watch / "GARMIN/APPS").iterdir()), [])

    def test_existing_app_requires_overwrite(self):
        app = self.watch / "GARMIN/APPS/VMA-LIVE.PRG"
        app.write_bytes(b"old")
        with self.assertRaisesRegex(ValueError, "already exists"):
            self.install()
        self.assertEqual(app.read_bytes(), b"old")
        self.args.overwrite = True
        self.args.field = "live"
        self.install()
        self.assertEqual(app.read_bytes(), b"normal app")

    def test_swapped_watch_is_rejected(self):
        def build(command, **kwargs):
            self.fake_build(command, **kwargs)
            self.write_identity(unit="456")

        with self.assertRaisesRegex(ValueError, "watch changed"):
            self.install(build=build)
        self.assertEqual(list((self.watch / "GARMIN/APPS").iterdir()), [])

    def test_build_failure_does_not_copy(self):
        def build(command, **kwargs):
            raise subprocess.CalledProcessError(1, command)

        with self.assertRaises(subprocess.CalledProcessError):
            self.install(build=build)
        self.assertEqual(list((self.watch / "GARMIN/APPS").iterdir()), [])

    def test_mtp_transfer_arguments(self):
        with (
            patch.object(installer.shutil, "which", return_value="/fake/garmin-mtp"),
            patch.object(installer, "run", return_value="[0] Garmin watch\n") as run,
        ):
            watch = installer.MtpWatch(None)
            run.return_value = "d  -            Apps/\nd  -            Activity/\n"
            watch.check_destination(["VMA-LIVE.PRG"], False)
            run.assert_called_with(
                "garmin-mtp", "--device-index", "0", "list", "/GARMIN/Apps"
            )
            watch.push(Path("VMA-LIVE.PRG"), False)
            run.assert_called_with(
                "garmin-mtp",
                "--device-index",
                "0",
                "push",
                "VMA-LIVE.PRG",
                "/GARMIN/Apps",
            )
            watch.push(Path("VMA-LIVE.PRG"), True)
            self.assertIn("--overwrite", run.call_args.args)

    def test_mtp_requires_unambiguous_device(self):
        with patch.object(installer.shutil, "which", return_value="/fake/garmin-mtp"):
            for devices in ("No MTP devices detected.", "[0] Garmin\n[1] Garmin\n"):
                with (
                    self.subTest(devices=devices),
                    patch.object(installer, "run", return_value=devices),
                    self.assertRaisesRegex(ValueError, "exactly one"),
                ):
                    installer.MtpWatch(None)


if __name__ == "__main__":
    unittest.main()
