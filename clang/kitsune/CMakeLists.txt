#
# Copyright (c) 2021 Triad National Security, LLC
#                         All rights reserved.
#
# This file is part of the kitsune/llvm project.  It is released under
# the LLVM license.
#
# Supports configuration of extensions to Clang in support of
# the Kitsune+Tapir feature set.
cmake_minimum_required(VERSION 3.14)

option(KITSUNE_ENABLE_KOKKOS_SUPPORT
    "Enable custom recognition and compilation of Kokkos." ON)

if (KITSUNE_ENABLE_KOKKOS_SUPPORT)
  set(KITSUNE_KOKKOS_CFG_FILENAME "kokkos.cfg"
    CACHE STRING "Default Kokkos .cfg filename.")
  set(KITSUNE_KOKKOS_CXX_FLAGS
      "-I${CMAKE_INSTALL_PREFIX}/include -I${CMAKE_INSTALL_PREFIX}/include/kokkos"
      CACHE STRING "Additional C++ compile flags needed by Kokkos applications.")
  set(KITSUNE_KOKKOS_LINK_LIBS_FLAGS
      "-L${CMAKE_INSTALL_PREFIX}/lib -lkokkoscore"
      CACHE STRING "Library flags (e.g. -lkokkoscore) needed by Kokkos applications.")
  set(KITSUNE_KOKKOS_EXTRA_LINK_FLAGS
      ""
      CACHE STRING "Additional link flags needed for Kokkos applications.")
  set(KITSUNE_KOKKOS_EXTRA_LINK_LIBS
     ""
     CACHE STRING "Additional link libraries needed for Kokkos applications.")


  configure_file(${CLANG_SOURCE_DIR}/kitsune/${KITSUNE_KOKKOS_CFG_FILENAME}.in
    ${LLVM_BINARY_DIR}/share/kitsune/${KITSUNE_KOKKOS_CFG_FILENAME})

endif()


# The none target (-ftapir=none) is always enabled, just provide a
# config filename and process the default .cfg.in file so it lands in
# the build/install.
set(TAPIR_NONE_TARGET_CFG_FILENAME "none.cfg"
    CACHE STRING "Default serial runtime ABI target Clang .cfg filename.")
configure_file(${CLANG_SOURCE_DIR}/kitsune/none.cfg.in
    ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_NONE_TARGET_CFG_FILENAME})

# The serial target (-ftapir=serial) is always enabled, just provide a
# config filename and process the default .cfg.in file so it lands in
# the build/install.
set(TAPIR_SERIAL_TARGET_CFG_FILENAME "serial.cfg"
    CACHE STRING "Default serial runtime ABI target Clang .cfg filename.")
configure_file(${CLANG_SOURCE_DIR}/kitsune/serial.cfg.in
    ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_SERIAL_TARGET_CFG_FILENAME})

# OpenCilk is always enabled.
set(KITSUNE_OPENCILK_TARGET_ENABLED ON CACHE BOOL "The OpenCilk runtime is always enabled -- this is a doppelganger for use in macros...")
if (NOT KITSUNE_OPENCILK_TARGET_ENABLED)
  message(WARNING "The OpenCilk runtime is always enabled, resetting it to ON.")
  set(KITSUNE_OPENCILK_TARGET_ENABLED ON BOOL FORCE)
endif()
set(TAPIR_OPENCILK_TARGET_CFG_FILENAME "opencilk.cfg"
    CACHE STRING "Default OpenCilk runtime ABI target Clang .cfg filename.")
set(KITSUNE_OPENCILK_TARGET_EXTRA_LINK_FLAGS
    ""
    CACHE
    STRING "Additional link flags needed for the OpenCilk runtime ABI target.")
# Note that link libraries are hard-coded into Clang source for OpenCilk support.
configure_file(${CLANG_SOURCE_DIR}/kitsune/opencilk.cfg.in
    ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_OPENCILK_TARGET_CFG_FILENAME})


option(KITSUNE_ENABLE_OPENMP_TARGET
    "Enable the Kitsune+Tapir OpenMP runtime codegen target." OFF)
if (KITSUNE_ENABLE_OPENMP_TARGET)
  set(TAPIR_OPENMP_TARGET_CFG_FILENAME
      "openmp.cfg"
      CACHE
      STRING "Default OpenMP runtime ABI target Clang .cfg filename.")
  set(KITSUNE_OPENMP_TARGET_EXTRA_LINK_FLAGS
      "-fopenmp"
      CACHE
      STRING "Additional link flags needed for the OpenMP runtime ABI target.")
  set(KITSUNE_OPENMP_TARGET_LINK_LIBS_FLAGS
      ""
      CACHE
      STRING "Link library flags (-L, -lxxx) for the OpenMP runtime ABI target.")
  #
  configure_file(${CLANG_SOURCE_DIR}/kitsune/openmp.cfg.in
      ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_OPENMP_TARGET_CFG_FILENAME})
endif()


option(KITSUNE_ENABLE_QTHREADS_TARGET
    "Enable the Kitsune+Tapir Qthreads runtime codegen target." OFF)
if (KITSUNE_ENABLE_QTHREADS_TARGET)
  set(TAPIR_QTHREADS_TARGET_CFG_FILENAME
      "qthreads.cfg"
      CACHE
      STRING "Default Qthreads runtime ABI target Clang .cfg filename.")
  set(KITSUNE_QTHREADS_TARGET_EXTRA_LINK_FLAGS
      ""
      CACHE
      STRING "Additional link flags needed for Qthreads runtime ABI target.")
  set(KITSUNE_QTHREADS_TARGET_LINK_LIBS_FLAGS
      "-lqthread -lhwloc -lpthread"
      CACHE
      STRING "Link library flags (-L, -lxxx) needed for the Qthreads runtime ABI target.")
  #
  configure_file(${CLANG_SOURCE_DIR}/kitsune/qthreads.cfg.in
      ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_QTHREADS_TARGET_CFG_FILENAME})
endif()


option(KITSUNE_ENABLE_REALM_TARGET
    "Enable the Kitsune+Tapir Realm runtime codegen target." OFF)
if (KITSUNE_ENABLE_REALM_TARGET)
  set(TAPIR_REALM_TARGET_CFG_FILENAME
      "realm.cfg"
      CACHE
      STRING "Default Realm runtime ABI target Clang .cfg filename.")
  set(KITSUNE_REALM_TARGET_EXTRA_LINK_FLAGS
      ""
      CACHE
      STRING "Additional link flags needed for the Realm runtime ABI target.")
  set(KITSUNE_REALM_TARGET_LINK_LIBS_FLAGS
      "-lrealm"
      CACHE
      STRING "Link library flags (-L, -lxx) needed for the Realm runtime ABI target.")
  #
  configure_file(${CLANG_SOURCE_DIR}/kitsune/realm.cfg.in
      ${LLVM_BINARY_DIR}/share/kitsune/${TAPIR_REALM_TARGET_CFG_FILENAME})
endif()

option(KITSUNE_ENABLE_GPU_TARGET "Enable the Kitsune+Tapir GPU target and supporting runtime." ON)
if (KITSUNE_ENABLE_GPU_TARGET)

  if (NOT LLVM_BUILD_LLVM_DYLIB)
    set(LLVM_BUILD_LLVM_DYLIB ON)
  endif()

  find_package(CUDAToolkit 11.5)
  if (CUDAToolkit_FOUND)
    message(STATUS "Kitsune: CUDA Toolkit version found.")
  endif()
  option(KITSUNE_ENABLE_CUDA_SUPPORT "Enable the Kitsune+Tapir CUDA Toolkit target and codegen library." ${CUDAToolkit_FOUND})
  if (KITSUNE_ENABLE_CUDA_SUPPORT)
    set(KITSUNE_GPU_TARGET_CFG_FILENAME
      "gpu.cfg"
      CACHE
      STRING "Default LLVM GPU ABI Clang .cfg file.")
    set(KITSUNE_CUDA_TARGET_EXTRA_LINK_FLAGS
      "" CACHE
      STRING "Additional link flags needed for the CUDA Toolkit runtime ABI target.")
    set(KITSUNE_CUDA_TARGET_LINK_LIBS_FLAGS
      "-L${CUDAToolkit_LIBRARY_DIR} -lcudart -lpthread -lLLVM -lrt -ldl -lnvptxcompiler_static"
      CACHE
      STRING "Link library flags (-L, -lxxx) needed for the NVIDIA/CUDA ABI target.")
    configure_file(${CLANG_SOURCE_DIR}/kitsune/${KITSUNE_GPU_TARGET_CFG_FILENAME}.in
      ${LLVM_BINARY_DIR}/share/kitsune/${KITSUNE_GPU_TARGET_CFG_FILENAME})
  endif()
  #
  # TODO: Need to get HIP and SPIRV rolled into this when ready...
  #
endif()


file(GLOB KITSUNE_CLANG_CFG_FILES
    ${LLVM_BINARY_DIR}/share/kitsune/*.cfg)

install(DIRECTORY ${LLVM_BINARY_DIR}/share/kitsune/
  DESTINATION share/kitsune  COMPONENT install-clang-cfgs
  FILES_MATCHING PATTERN "*.cfg")
