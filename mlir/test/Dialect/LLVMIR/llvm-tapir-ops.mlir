// RUN: mlir-opt %s | FileCheck %s
// verify that terminators survive the canonicalizer

// CHECK-LABEL: @tapir_ops
// CHECK: %[[SYNCREG:.*]] = llvm_tapir.tapir_syncregion_start
// CHECK: llvm_tapir.detach %[[SYNCREG]], ^bb1, ^bb2
// CHECK: ^bb1: 
// CHECK: llvm_tapir.reattach %[[SYNCREG]], ^bb2
// CHECK: ^bb2:
// CHECK: llvm_tapir.sync %[[SYNCREG]], ^bb3
llvm.func @tapir_ops() {
  %sr = "llvm_tapir.tapir_syncregion_start"() : () -> !llvm.token
  llvm_tapir.detach %sr, ^bb1, ^bb2
^bb1:
  llvm_tapir.reattach %sr, ^bb2
^bb2:
  llvm_tapir.sync %sr, ^bb3
^bb3:
  llvm.return
}