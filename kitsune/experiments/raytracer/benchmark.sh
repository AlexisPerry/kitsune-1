#!/bin/bash 
for exe in raytrace-kitsune raytrace-kokkos raytrace-clang
do 
	echo "Executable: $exe"
	for num_samples in 2 4 8 16 32 64 128 256 512 1024 2048 
	do 
		echo "	Samples: $num_samples"
		echo -n "	"
		./$exe $num_samples 2> /dev/null
	done
done	

