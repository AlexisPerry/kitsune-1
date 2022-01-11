#ifndef _KITSUNE_LLVM_GPU_ABI_CUDA_H_
#define _KITSUNE_LLVM_GPU_ABI_CUDA_H_

#include<llvm/Target/TargetMachine.h>

void* cudaManagedMalloc(size_t n);
bool initCUDA();
void* launchCUDAKernel(llvm::Module& m, void** args, size_t n);
void waitCUDAKernel(void* wait);


#endif
