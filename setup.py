from setuptools import setup, find_packages, Command
from setuptools.command.develop import develop
from setuptools.command.install import install
from setuptools.command.build_ext import build_ext
from setuptools.command.build import build

import os, shutil, subprocess, stat, sys, sysconfig

from typing import Literal, Any

if sys.version_info < (3, 13):
    raise RuntimeError("leviathan requires Python 3.13 or later")

zig_mode: Literal["Debug", "ReleaseSafe"] = "Debug"
zig_compiler_options = []

include_dir = sysconfig.get_config_var("INCLUDEPY")
zig_compiler_options.append(f"-Dpython-include-dir={include_dir}")

so_path = sysconfig.get_config_var("LIBDIR")
so_name = sysconfig.get_config_var("INSTSONAME")
full_path = f"{so_path}/{so_name}"
zig_compiler_options.append(f"-Dpython-lib-dir={so_path}")
zig_compiler_options.append(f"-Dpython-lib={full_path}")

is_gil_enabled = sys._is_gil_enabled()  # type: ignore
if not is_gil_enabled:
    zig_compiler_options.append("-Dpython-gil-disabled")


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
        subprocess.check_call(["zig", "build", "test", *zig_compiler_options])
        self.run_command("build")

        errno = subprocess.call(
            [sys.executable, "-m", "pytest", "-s", "--verbose", "--full-trace"],
            cwd=os.path.join("build", "lib"),
        )
        raise SystemExit(errno)


class ZigBuildExtCommand(build_ext):
    def run(self) -> None:
        subprocess.check_call(
            ["zig", "build", "install", f"-Doptimize={zig_mode}", *zig_compiler_options]
        )
        self.copy_zig_files()

    def copy_zig_files(self) -> None:
        build_dir = "./zig-out/lib"

        src_path = os.path.join(build_dir, "libleviathan.so")
        dest_path = os.path.join("build", "lib", "leviathan", "leviathan_zig.so")
        shutil.copyfile(src_path, dest_path)

        st = os.stat(dest_path)
        os.chmod(dest_path, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


class ZigBuildCommand(build):
    def run(self) -> None:
        self.run_command("build_py")

        build_lib_path = os.path.join("build", "lib")
        tests_path = os.path.join(build_lib_path, "tests")
        shutil.copytree("./tests", tests_path, dirs_exist_ok=True)

        self.run_command("build_ext")


class ZigDevelopCommand(develop):
    def run(self) -> None:
        self.run_command("build")
        super().run()


class ZigInstallCommand(install):
    def run(self) -> None:
        global zig_mode

        zig_mode = "ReleaseSafe"
        self.run_command("build")
        super().run()


setup(
    name="leviathan",
    version="0.2.0",
    description="Leviathan: A lightning-fast Zig-powered event loop for Python's asyncio.",
    author="Enrique Miguel Mora Meza",
    author_email="kike28.py@pm.me",
    url="https://github.com/kython28/leviathan",
    packages=find_packages(
        exclude=["tests", "zig-out", "src"], include=["leviathan", "leviathan.*"]
    ),
    package_data={
        "leviathan": ["leviathan_zig.so"],
        "": ["tests/"],
    },
    cmdclass={
        "build_ext": ZigBuildExtCommand,
        "build": ZigBuildCommand,
        "develop": ZigDevelopCommand,
        "install": ZigInstallCommand,
        "bench": LeviathanBench,
        "test": LeviathanTest,
    },
)
