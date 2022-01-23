#!/bin/bash 

profile_samples=64
for exe in raytrace-cuda raytrace-kitsune raytrace-kokkos raytrace-clang
do 
	echo "Executable: $exe"
	for num_samples in 64 # 1 2 4 8 16 32 64 128 256 512
	do 
		echo -n "   samples: $num_samples"
		echo -n ", "
		./$exe $num_samples 2> /dev/null
	done
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


