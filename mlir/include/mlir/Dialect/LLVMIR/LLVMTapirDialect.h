//===- LLVMTapirDialect.h - MLIR Dialect for LLVMTapir --------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the Target dialect for LLVMTapir in MLIR.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LLVMIR_LLVMTAPIRDIALECT_H_
#define MLIR_DIALECT_LLVMIR_LLVMTAPIRDIALECT_H_

#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/ControlFlowInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LLVMIR/LLVMTapir.h.inc"

#include "mlir/Dialect/LLVMIR/LLVMTapirDialect.h.inc"

#endif // MLIR_DIALECT_LLVMIR_LLVMTAPIRDIALECT_H_
