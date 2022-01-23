all: raytrace-kitsune raytrace-kokkos raytrace-clang raytrace-cuda

kitsune_prefix=/home/pat/local/kitsune/x86-ampere
kokkos_prefix=/home/pat/local/kitsune/x86-ampere/kokkos
cuda_prefix=/projects/darwin-nv/centos8/x86_64/packages/cuda/11.5.0

cxx_flags=-std=c++17 -fno-exceptions -I${kitsune_prefix}/include
opt_flags=-O3

kitsune_tapir_flags=${cxx_flags} -fkokkos -fkokkos-no-init -ftapir=gpu ${opt_flags}

kokkos_cxx_flags=${cxx_flags} -I${kokkos_prefix}/include 
kokkos_ld_flags=-L${kokkos_prefix}/lib64 -lkokkoscore

nvcc_wrapper=${kokkos_prefix}/bin/nvcc_wrapper
nvcc_args=--expt-extended-lambda -arch=sm_80 -m64 

clang=${kitsune_prefix}/bin/clang++ 

clang_cuda_flags=-xcuda --cuda-gpu-arch=sm_80 --cuda-path=/projects/darwin-nv/centos8/x86_64/packages/cuda/11.5.0
clang_cxx_flags=${kokkos_cxx_flags} --gcc-toolchain=/projects/opt/centos8/x86_64/gcc/9.4.0/ ${clang_cuda_flags} ${opt_flags}
clang_ld_flags=-L${kokkos_prefix}/lib64 -L/projects/darwin-nv/centos8/x86_64/packages/cuda/11.5.0/lib64 -lkokkoscore -lcudart -ldl


raytrace-kitsune: raytrace-kitsune.cpp
	${clang} ${kitsune_tapir_flags} -o raytrace-kitsune raytrace-kitsune.cpp -Xlinker -rpath=${kitsune_prefix}/lib

raytrace-kokkos: raytrace-kokkos.cpp 
	${nvcc_wrapper} ${cxx_flags} ${kokkos_cxx_flags} ${nvcc_args} -o raytrace-kokkos raytrace-kokkos.cpp ${kokkos_ld_flags} 

raytrace-clang: raytrace-kokkos.cpp
	${clang} ${clang_cxx_flags} -o raytrace-clang raytrace-kokkos.cpp  ${clang_ld_flags} 

raytrace-cuda: raytrace-cuda.cu
	nvcc ${opt_flags} ${nvcc_flags} -I${kitsune_prefix}/include -o raytrace-cuda raytrace-cuda.cu 

.PHONY: clean
clean:
	rm -f raytrace-kitsune raytrace-kokkos raytrace-clang
