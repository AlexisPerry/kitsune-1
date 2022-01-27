#!/bin/bash 

nvidia-smi 

profile_samples=16
for exe in raytrace-cuda raytrace-kitsune raytrace-kokkos raytrace-clang
do 
	echo "Profiling..."
	ncu --section SpeedOfLight \
            --section SpeedOfLight_RooflineChart \
            --section SchedulerStats \
            --section ComputeWorkloadAnalysis \
            --section WarpStateStats \
            --section LaunchStats \
	    --section InstructionStats \
            --section SourceCounters \
            --section Occupancy \
            --section MemoryWorkloadAnalysis \
            --page details \
            --print-summary per-gpu \
            --details-all \
            --log-file $PWD/$exe-ncu.$profile_samples.log \
            --export $PWD/$exe.%i.$profile_samples ./$exe $profile_samples
done	

