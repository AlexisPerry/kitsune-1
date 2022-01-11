all: raytrace-kitsune raytrace-kokkos


opt_flags=-O3

kitsune_prefix=/home/pat/Projects/kitsune/build/local
kitsune_flags=-fno-exceptions -fkokkos -fkokkos-no-init -ftapir=gpu ${opt_flags}

kokkos_prefix=/home/pat/Projects/kitsune/build/local/kokkos
nvcc_wrapper=/home/pat/Projects/kitsune/build/local/kokkos/bin/nvcc_wrapper
kokkos_flags=-fno-exceptions -I${kokkos_prefix}/include -I${kitsune_prefix}/include ${opt_flags}

raytrace-kitsune: raytrace-kitsune.cpp
	clang++ ${kitsune_flags} -o raytrace-kitsune raytrace-kitsune.cpp -Xlinker -rpath=${kitsune_prefix}/lib

raytrace-kokkos: raytrace-kokkos.cpp 
	${nvcc_wrapper} ${kokkos_flags} -o raytrace-kokkos raytrace-kokkos.cpp -L${kokkos_prefix}/lib -lkokkoscore -Xlinker -rpath=${kokkos_prefix}/lib 

.PHONY: clean
clean:
	rm -f raytrace-kitsune raytrace-kokkos
