all: raytrace-kitsune raytrace-kokkos


opt_flags=-O3

kitsune_prefix=/home/pat/local/x86-volta/
kitsune_flags=-fno-exceptions -fkokkos -fkokkos-no-init -ftapir=gpu ${opt_flags}

kokkos_prefix=/home/pat/local/x86-volta/kokkos-cuda/
nvcc_wrapper=/${kokkos_prefix}/bin/nvcc_wrapper
kokkos_flags=-fno-exceptions -I${kokkos_prefix}/include -I${kitsune_prefix}/include ${opt_flags}

raytrace-kitsune: raytrace-kitsune.cpp
	${kitsune_prefix}/bin/clang++ ${kitsune_flags} -o raytrace-kitsune raytrace-kitsune.cpp -Xlinker -rpath=${kitsune_prefix}/lib

raytrace-kokkos: raytrace-kokkos.cpp 
	${nvcc_wrapper} ${kokkos_flags} -o raytrace-kokkos raytrace-kokkos.cpp -L${kokkos_prefix}/lib64 -lkokkoscore -Xlinker -rpath=${kokkos_prefix}/lib64 

.PHONY: clean
clean:
	rm -f raytrace-kitsune raytrace-kokkos
