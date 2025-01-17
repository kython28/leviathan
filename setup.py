from setuptools import setup, find_packages, Command
from setuptools.command.develop import develop
from setuptools.command.install import install
from setuptools.command.build_ext import build_ext
from setuptools.command.build import build
import os, shutil, subprocess, stat, sys

from typing import Literal, Any


zig_mode: Literal['Debug', 'ReleaseSafe'] = "Debug"


class LeviathanBench(Command):
	user_options: list[Any] = []

	def initialize_options(self) -> None:
		pass

	def finalize_options(self) -> None:
		pass

	def run(self) -> None:
		global zig_mode
		zig_mode = "ReleaseSafe"
		
		self.run_command("build")

		build_lib_path = os.path.join("build", "lib")
		
		benchmarks_path = os.path.join(build_lib_path, "benchmarks")
		benchmark_py_path = os.path.join(build_lib_path, "benchmark.py")
		shutil.copytree("./benchmarks", benchmarks_path, dirs_exist_ok=True)
		shutil.copyfile("./benchmark.py", benchmark_py_path)

		build_lib_path = os.path.join("build", "lib")
		errno = subprocess.call([sys.executable, "benchmark.py"], cwd=build_lib_path)
		
		shutil.rmtree(benchmarks_path)
		os.remove(benchmark_py_path)
		
		raise SystemExit(errno)

class LeviathanTest(Command):
	user_options: list[Any] = []

	def initialize_options(self) -> None:
		pass

	def finalize_options(self) -> None:
		pass
	
	def run(self) -> None:
		self.run_command("build")
		subprocess.check_call(["zig", "build", "test"])

		build_lib_path = os.path.join("build", "lib")
		errno = subprocess.call([sys.executable, "-m", "pytest", "-s"], cwd=build_lib_path)

		raise SystemExit(errno)

class ZigBuildExtCommand(build_ext):
	def run(self) -> None:
		subprocess.check_call(["zig", "build", "install", f"-Doptimize={zig_mode}"])
		self.copy_zig_files()

	def copy_zig_files(self) -> None:
		build_dir = "./zig-out/lib"

		src_path = os.path.join(build_dir, "libleviathan.so")
		src_path2 = os.path.join(build_dir, "libleviathan_single_thread.so")

		dest_path = os.path.join("build", "lib", "leviathan", "leviathan_zig.so")
		dest_path2 = os.path.join("build", "lib", "leviathan", "leviathan_zig_single_thread.so")
		shutil.copyfile(src_path, dest_path)
		shutil.copyfile(src_path2, dest_path2)

		st = os.stat(dest_path)
		os.chmod(dest_path, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

		st = os.stat(dest_path2)
		os.chmod(dest_path2, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

class ZigBuildCommand(build):
	def run(self) -> None:
		self.run_command("build_py")

		build_lib_path = os.path.join("build", "lib")
		tests_path = os.path.join(build_lib_path, "tests")
		shutil.copytree("./tests", tests_path, dirs_exist_ok=True)

		self.run_command("build_ext")

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
		"build_ext": ZigBuildExtCommand,
		"build": ZigBuildCommand,
		"develop": ZigDevelopCommand,
		"install": ZigInstallCommand,
		"bench": LeviathanBench,
		"test": LeviathanTest
	}
)
