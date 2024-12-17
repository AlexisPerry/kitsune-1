/**
 ***************************************************************************
 * TODO: Need to update LANL/Triad Copyright notice...
 *
 * Copyright (c) 2017, Los Alamos National Security, LLC.
 * All rights reserved.
 *
 *  Copyright 2010. Los Alamos National Security, LLC. This software was
 *  produced under U.S. Government contract DE-AC52-06NA25396 for Los
 *  Alamos National Laboratory (LANL), which is operated by Los Alamos
 *  National Security, LLC for the U.S. Department of Energy. The
 *  U.S. Government has rights to use, reproduce, and distribute this
 *  software.  NEITHER THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY,
 *  LLC MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY
 *  FOR THE USE OF THIS SOFTWARE.  If software is modified to produce
 *  derivative works, such modified software should be clearly marked,
 *  so as not to confuse it with the version available from LANL.
 *
 *  Additionally, redistribution and use in source and binary forms,
 *  with or without modification, are permitted provided that the
 *  following conditions are met:
 *
 *    * Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *    * Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following
 *      disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 *    * Neither the name of Los Alamos National Security, LLC, Los
 *      Alamos National Laboratory, LANL, the U.S. Government, nor the
 *      names of its contributors may be used to endorse or promote
 *      products derived from this software without specific prior
 *      written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC AND
 *  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL LOS ALAMOS NATIONAL SECURITY, LLC OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 *  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 *  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 *  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 *  SUCH DAMAGE.
 *
 ***************************************************************************/

#ifndef LLVM_CLANG_BASIC_KITSUNE_OPTIONS_H
#define LLVM_CLANG_BASIC_KITSUNE_OPTIONS_H

#include <llvm/Transforms/Tapir/TapirTargetIDs.h>

namespace clang {

/// Options that are Kitsune-specific. These affect both the Kitsune "language"
/// i.e. forall, spawn, sync etc. and the backend code-generation via Tapir.
class KitsuneOptions {
private:
  /// The TapirTarget to enable for code generation.
  ///
  /// For now, this is optional because we do not have a default tapir target
  /// and even when using the Kitsune frontends (kitcc, kit++ etc.), a flag with
  /// a Tapir target must be provided to enable the use of the Tapir IR
  /// constructs. If this field is set to some "non-empty" value, it implies
  /// that the Kitsune "language" mode has been enabled.
  ///
  /// This may have to be changed in order to handle the "inline" Tapir
  /// attributes including those needed for multi-target support.
  ////
  std::optional<llvm::TapirTargetID> TapirTarget = std::nullopt;

  // Path to OpenCilk runtime bitcode file.
  std::string OpenCilkABIBitcodeFile;

  /// Is "Kokkos mode" enabled.
  bool Kokkos = false;

  /// If "Kokkos mode" is enabled, should the initialization of libkokkoscore
  /// be overrident.
  bool KokkosNoInit = false;

public:
  void setTapirTarget(llvm::TapirTargetID TapirTarget) {
    this->TapirTarget = TapirTarget;
  }

  void setKokkos(bool Kokkos = true) { this->Kokkos = Kokkos; }

  void setKokkosNoInit(bool KokkosNoInit = true) {
    this->KokkosNoInit = KokkosNoInit;
  }

  bool isKitsuneEnabled() const { return TapirTarget.has_value(); }

  bool getKokkos() const { return Kokkos; }

  bool getKokkosNoInit() const { return KokkosNoInit; }

  /// This should only be called when a TapirTarget is known to exist.
  std::optional<llvm::TapirTargetID> getTapirTarget() const {
    return TapirTarget;
  }

  llvm::TapirTargetID getTapirTargetOrInvalid() const {
    if (TapirTarget)
      return *TapirTarget;
    else
      return llvm::TapirTargetID::Last_TapirTargetID;
  }
  
  std::unique_ptr<llvm::OpenCilkABIOptions> getOpenCilkABIOptions() const {
    return std::make_unique<llvm::OpenCilkABIOptions>(OpenCilkABIBitcodeFile);
  }
};

} // namespace clang

#endif // LLVM_CLANG_BASIC_KITSUNE_OPTIONS_H
