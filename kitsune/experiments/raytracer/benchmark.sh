#!/bin/bash 

nvidia-smi 

profile_samples=64
for exe in raytrace-cuda raytrace-kitsune raytrace-forall raytrace-kokkos raytrace-clang
do 
	echo "Executable: $exe"
	for num_samples in 1 2 4 8 16 32 64 128 256 512 
	do 
		echo -n "   samples: $num_samples, "
		./$exe $num_samples 2> /dev/null
	done
	echo "---------------------------"
	echo "  "
done	

