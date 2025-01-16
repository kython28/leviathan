from setuptools import setup, find_packages, Command
from setuptools.command.develop import develop
from setuptools.command.install import install
from setuptools.command.build_ext import build_ext
import os, shutil, subprocess, stat, sys

from typing import Literal, Any


zig_mode: Literal['Debug', 'ReleaseSafe'] = "Debug"


class LeviathanTest(Command):
	user_options: list[Any] = []

	def initialize_options(self) -> None:
		pass

	def finalize_options(self) -> None:
		pass

	def run(self) -> None:
		subprocess.check_call(["zig", "build", "test"])

		self.run_command("build_ext")

		errno = subprocess.call([sys.executable, "-m", "pytest", "-s"])
		raise SystemExit(errno)


class ZigBuildCommand(build_ext):
	def run(self) -> None:
		subprocess.check_call(["zig", "build", "install", f"-Doptimize={zig_mode}"])
		self.copy_zig_files()

	def copy_zig_files(self) -> None:
		build_dir = "./zig-out/lib"

		src_path = os.path.join(build_dir, "libleviathan.so")
		src_path2 = os.path.join(build_dir, "libleviathan_single_thread.so")

		dest_path = os.path.join("leviathan", "leviathan_zig.so")
		dest_path2 = os.path.join("leviathan", "leviathan_zig_single_thread.so")
		shutil.copyfile(src_path, dest_path)
		shutil.copyfile(src_path2, dest_path2)

		st = os.stat(dest_path)
		os.chmod(dest_path, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

		st = os.stat(dest_path2)
		os.chmod(dest_path2, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


class ZigDevelopCommand(develop):
	def run(self) -> None:
		self.run_command("build_ext")
		super().run()


class ZigInstallCommand(install):
	def run(self) -> None:
		global zig_mode

		zig_mode = "ReleaseSafe"
		self.run_command("build_ext")
		super().run()


setup(
	name="leviathan",
	version="0.1.0",
	description="Leviathan: A lightning-fast Zig-powered event loop for Python's asyncio.",
	author="Enrique Miguel Mora Meza",
	author_email="kike28.py@pm.me",
	url="https://github.com/kython28/leviathan",
	packages=find_packages(
		exclude=["tests", "zig-out", "src"],
		include=["leviathan", "leviathan.*"]
	),
	package_data={"leviathan": ["leviathan_zig.so"]},
	cmdclass={
		"build_ext": ZigBuildCommand,
		"develop": ZigDevelopCommand,
		"install": ZigInstallCommand,
		"test": LeviathanTest
	}
)
