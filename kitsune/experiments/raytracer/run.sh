#!/bin/bash 
ncu --section SpeedOfLight --section SchedulerStats --section ComputeWorkloadAnalysis --section WarpStateStats --section LaunchStats --section SpeedOfLight_RooflineChart --export $PWD/kokkos-raytrace.%i ./raytrace-kokkos 32

ncu --export $PWD/kitsune-raytrace.%i \
    --section ComputeWorkloadAnalysis \
    --section LaunchStats \
    --section MemoryWorkloadAnalysis_Chart \
    --section Occupancy \
    --section SpeedOfLight \
    --section SpeedOfLight_RooflineChart \
    --section WarpStateStats \
    $PWD/raytrace-kitsune 32

ncu --export $PWD/kitsune-kokkos.%i \
    --target-processes application-only \
    --replay-mode kernel \
    --kernel-name-base function \
    --launch-skip-before-match 0 \
    --section ComputeWorkloadAnalysis \
    --section LaunchStats \
    --section MemoryWorkloadAnalysis_Chart \
    --section Occupancy \
    --section SpeedOfLight \
    --section SpeedOfLight_RooflineChart \
    --section WarpStateStats \
    --sampling-interval auto \
    --sampling-max-passes 5 \
    --sampling-buffer-size 33554432 \
    --profile-from-start 1 \
    --cache-control all \
    --clock-control base \
    --apply-rules yes \
    --import-source no \
    --check-exit-code yes \
    $PWD/raytrace-kokkos 32

