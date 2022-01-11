#/bin/bash 
ncu --export $PWD/kitsune-raytrace.%i \
    --target-processes application-only \
    --replay-mode kernel \
    --kernel-name-base function \
    --launch-skip-before-match 0 \
    --section ComputeWorkloadAnalysis \
    --section InstructionStats \
    --section LaunchStats \
    --section MemoryWorkloadAnalysis \
    --section MemoryWorkloadAnalysis_Chart \
    --section MemoryWorkloadAnalysis_Tables \
    --section Occupancy \
    --section SchedulerStats \
    --section SourceCounters \
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
    $PWD/raytrace-kitsune 32

