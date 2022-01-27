# Copyright (c) 2020 Triad National Security, LLC
#                         All rights reserved.
#
# This file is part of the kitsune/llvm project.  It is released under
# the LLVM license.
#
if (NOT KITSUNE_EXPERIMENTS)
  set_property(DIRECTORY PROPERTY EXCLUDE_FROM_ALL ON)
  set(EXCLUDE_FROM_ALL ON)
endif()

message(STATUS "Enabling kitsune experiments directory.")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/kitsune.mk.cmake
      ${CMAKE_CURRENT_SOURCE_DIR}/kitsune.mk)

#add_subdirectory(raytracer)
