# -*- Python -*-

import os
import platform
import re
import subprocess
import tempfile

import lit.formats

from lit.llvm import llvm_config
from lit.llvm.subst import ToolSubst
from lit.llvm.subst import FindTool

# Configuration file for the 'lit' test runner.

# name: The name of this test suite.
config.name = "Kitsune"

# testFormat: The test format to use to interpret tests.
#
# For now we require '&&' between commands, until they get globally killed and
# the test runner updated.
config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)

# suffixes: A list of file extensions to treat as test files.
config.suffixes = [
    ".c",
    ".cpp",
    ".cu",
    ".f",
    ".f90",
    ".hip",
    ".ll",
    ".s",
    ".S",
    ".test",
    ".rs",
    ".ifs",
    ".rc",
]

# Exclude some files and directories.
# TODO: tests and tests.old are old names for some tests that are still in the
# repo for the moment, but should be removed eventually - both from the repo
# and this list.
config.excludes = [
    "CMakeLists.txt", "tests", "tests.old"
]

# test_source_root: The root path where tests are located.
config.test_source_root = os.path.dirname(__file__)

# test_exec_root: The root path where tests should be run.
config.test_exec_root = os.path.join(config.kitsune_obj_root, "test")

llvm_config.use_default_substitutions()

llvm_config.use_clang()

config.substitutions.append(
    ("%src_include_dir", config.kitsune_src_dir + "/include")
)

config.substitutions.append(("%target_triple", config.target_triple))

config.substitutions.append(("%PATH%", config.environment["PATH"]))

# For each occurrence of a clang tool name, replace it with the full path to
# the build directory holding that tool.  We explicitly specify the directories
# to search to ensure that we get the tools just built and not some random
# tools that might happen to be in the user's PATH.
tool_dirs = [config.llvm_tools_dir]

tools = [
    "clang-linker-wrapper",
    "not",
    "opt",
    "llvm-lto",
    "llvm-lto2",
    ToolSubst(
        "%flang",
        command=FindTool("flang-new"),
        unresolved="fatal",
    ),
]

llvm_config.add_tool_substitutions(tools, tool_dirs)

config.substitutions.append(("%host_cc", config.host_cc))
config.substitutions.append(("%host_cxx", config.host_cxx))
config.substitutions.append(("%kitcc", config.kitcc))
config.substitutions.append(("%kitxx", config.kitxx))

# Features
def calculate_arch_features(arch_string):
    features = []
    for arch in arch_string.split():
        features.append(arch.lower() + "-registered-target")
    return features

llvm_config.feature_config([
    ("--assertion-mode", {
        "ON": "asserts"
    }), ("--cxxflags", {
        r"-D_GLIBCXX_DEBUG\b": "libstdcxx-safe-mode"
    }), ("--targets-built", calculate_arch_features),
])

if config.kitsune_kokkos_enable:
    config.available_features.add("kitsune-kokkos")
else:
    config.available_features.add("kitsune-no-kokkos")

if config.kitsune_cuda_enable:
    config.available_features.add("kitsune-cuda")
else:
    config.available_features.add("kitsune-no-cuda")

if config.kitsune_hip_enable:
    config.available_features.add("kitsune-hip")
else:
    config.available_features.add("kitsune-no-hip")

if config.kitsune_opencilk_enable:
    config.available_features.add("kitsune-opencilk")
else:
    config.available_features.add("kitsune-no-opencilk")

if config.kitsune_openmp_enable:
    config.available_features.add("kitsune-openmp")
else:
    config.available_features.add("kitsune-no-openmp")

if config.kitsune_qthreads_enable:
    config.available_features.add("kitsune-qthreads")
else:
    config.available_features.add("kitsune-no-qthreads")

if config.kitsune_realm_enable:
    config.available_features.add("kitsune-realm")
else:
    config.available_features.add("kitsune-no-realm")

# It is not realistically possible to account for all options that could
# possibly be present in system and user configuration files, so disable
# default configs for the test runs.
config.environment["CLANG_NO_DEFAULT_CONFIG"] = "1"
