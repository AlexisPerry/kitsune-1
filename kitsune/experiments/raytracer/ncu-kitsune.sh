#/bin/bash 
ncu \
    --section SpeedOfLight \
    --section SpeedOfLight_RooflineChart \
    --section SchedulerStats \
    --section ComputeWorkloadAnalysis \
    --section WarpStateStats \
    --section LaunchStats \
    --page all \
    --print-summary per-gpu \
    --details-all \
    --log-file $PWD/kitsune-raytrace-ncu.log \
    --export $PWD/kitsune-raytrace.%i \
    ./raytrace-kitsune 32


