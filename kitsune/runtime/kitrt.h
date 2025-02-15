//
//===- kitrt.h - Kitsune ABI runtime debug support     ------------------===//
//
// TODO: Need to update LANL/Triad Copyright notice.
//
// Copyright (c) 2021, Los Alamos National Security, LLC.
// All rights reserved.
//
//  Copyright 2021. Los Alamos National Security, LLC. This software was
//  produced under U.S. Government contract DE-AC52-06NA25396 for Los
//  Alamos National Laboratory (LANL), which is operated by Los Alamos
//  National Security, LLC for the U.S. Department of Energy. The
//  U.S. Government has rights to use, reproduce, and distribute this
//  software.  NEITHER THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY,
//  LLC MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY
//  FOR THE USE OF THIS SOFTWARE.  If software is modified to produce
//  derivative works, such modified software should be clearly marked,
//  so as not to confuse it with the version available from LANL.
//
//  Additionally, redistribution and use in source and binary forms,
//  with or without modification, are permitted provided that the
//  following conditions are met:
//
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above
//      copyright notice, this list of conditions and the following
//      disclaimer in the documentation and/or other materials provided
//      with the distribution.
//
//    * Neither the name of Los Alamos National Security, LLC, Los
//      Alamos National Laboratory, LANL, the U.S. Government, nor the
//      names of its contributors may be used to endorse or promote
//      products derived from this software without specific prior
//      written permission.
//
//  THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC AND
//  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL LOS ALAMOS NATIONAL SECURITY, LLC OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
//  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//  SUCH DAMAGE.
//
//===----------------------------------------------------------------------===//

#ifndef __KITRT_H__
#define __KITRT_H__

#include <stdint.h>
#include <stdlib.h>

#include "llvm/kitrt-llvm.h"

#ifdef KITRT_CUDA_ENABLED
#include "cuda/cuda.h"
#endif

#ifdef KITRT_HIP_ENABLED
#include "hip/hip.h"
#endif

#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif

  /// Initialize the shared portion of the runtime.  
  /// NOTE: The target-specific (non-JIT) transforms 
  /// currently make explicit calls into the associated 
  /// runtime for initialization; those calls in turn 
  /// will call this entry point.  This path is taken 
  /// to avoid overhead for compile-time targets.
  extern void __kitrt_CommonInit();

  /// Initialize the supported runtimes.
  extern bool __kitrt_runtimesInit();

  /// Enable/Disable the runtime's verbose operating mode.  This will
  /// provide runtime status reports to stderr during program
  /// execution.
  ///
  /// This mode may be *enabled* by setting the environment variable
  /// KITRT_VERBOSE.  When set on program startup is equivalent to
  /// calling __kitrtSetVerboseMode(true).
  extern void __kitrt_setVerboseMode(bool Enable);

  /// Enable the runtime's verbose operating mode.  This will provide
  /// runtime status reports to stderr during program execution.
  inline void __kitrt_enableVerboseMode() {
    __kitrt_setVerboseMode(true);
  }

  /// Disable the runtime's verbose operating mode.  This will provide
  /// runtime status reports to stderr during program execution.
  inline void __kitrt_disableVerboseMode() {
    __kitrt_setVerboseMode(false);
  }

  /// Return the internal status of the runtime's verbose operating
  /// mode.
  extern bool __kitrt_verboseMode();

  // Get info about supported runtime targets.
  extern bool __kitrt_isCudaSupported();
  extern bool __kitrt_isHipSupported();
  extern bool __kitrt_isCheetahSupported();
  extern bool __kitrt_isRealmSuported();

  extern void __kitrt_setDefaultThreadsPerBlock(unsigned threadsPerBlock);
  extern void __kitrt_getLaunchParameters(size_t numElements,
                                          int &threadsPerBlock,
                                          int &blocksPerGrid);
  extern void __kitrt_resetLaunchParameters();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // __KITRT_H__

