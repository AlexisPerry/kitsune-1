kitsune_prefix=/projects/kitsune/12.x/x86_64
kokkos_prefix=/projects/kitsune/12.x/x86_64/opt/kokkos-cuda
#kokkos_uvm_prefix=/home/pat/local/opt/x86_64/kokkos-cuda-uvm
cuda_prefix=$(CUDA_HOME) 

nvcc_wrapper=${kokkos_prefix}/bin/nvcc_wrapper
clang=${kitsune_prefix}/bin/clang++ 
opt=${kitsune_prefix}/bin/opt

cxx_flags=-std=c++17 -fno-exceptions -I${kitsune_prefix}/include
opt_flags=-O3

kitsune_tapir_flags=${cxx_flags} -fkokkos -fkokkos-no-init -ftapir=gpu ${opt_flags}
kokkos_cxx_flags=${cxx_flags} -I${kokkos_prefix}/include 
kokkos_ld_flags=-L${kokkos_prefix}/lib64 -lkokkoscore

nvcc_flags=--expt-extended-lambda -arch=sm_80 -m64 

clang_cuda_flags=-xcuda --cuda-gpu-arch=sm_80 # --cuda-path=$(CUDA_HOME)
cuda_flags=${cxx_flags} ${opt_flags} -m64 -arch=sm_80

clang_cxx_flags=${cxx_flags} ${clang_cuda_flags} -I${kokkos_prefix}/include ${opt_flags} 
clang_ld_flags=-L${kokkos_prefix}/lib64 -L$(CUDA_HOME)/lib64 -lkokkoscore -lcudart -ldl

all: raytrace-kitsune raytrace-kokkos raytrace-clang raytrace-cuda



# raytrace-kitsune: kitsune+tapir code 
# 
raytrace-kitsune: raytrace-kitsune.cpp
	${clang} ${kitsune_tapir_flags} -o raytrace-kitsune raytrace-kitsune.cpp -Xlinker -rpath=${kitsune_prefix}/lib

raytrace-kitsune-print-all.txt: raytrace-kitsune.cpp
	${clang} ${kitsune_tapir_flags} -o raytrace-kitsune raytrace-kitsune.cpp -Xlinker -rpath=${kitsune_prefix}/lib -mllvm -print-after-all 2>&1 | tee raytrace-kitsune-print-all.txt 

%.kit.pdf : %.cpp
	-@rm -rf $<-cfg-tmp
	${clang} -fkokkos -fkokkos-no-init -ftapir=gpu -c -emit-llvm -o $<.bc $<
	-@mkdir -p $<-cfg-tmp
	${opt} -O3 --dot-cfg -cfg-dot-filename-prefix=$<-cfg-tmp/$< $<.bc 2> /dev/null
	dot -Tpdf -o $@ $<-cfg-tmp/$<.main.outline_.*.dot
	@-rm -rf $@-cfg-tmp 
#
###

raytrace-kokkos: raytrace-kokkos.cpp 
	${nvcc_wrapper} ${kokkos_cxx_flags} ${nvcc_flags} -o raytrace-kokkos raytrace-kokkos.cpp ${kokkos_ld_flags} 

raytrace-clang: raytrace-kokkos.cpp
	${clang} ${clang_cxx_flags} -o raytrace-clang raytrace-kokkos.cpp  ${clang_ld_flags} 

raytrace-cuda: raytrace-cuda.cu
	nvcc ${opt_flags} ${nvcc_flags} -I${kitsune_prefix}/include -o raytrace-cuda raytrace-cuda.cu 

details: raytrace-kitsune.kit.pdf 
	@echo detailed info target complete. 

.PHONY: clean
clean:
	-rm -f raytrace-kitsune raytrace-kokkos raytrace-clang raytrace-cuda
	-rm -rf *-cfg-tmp 
	-rm -f *.bc 
