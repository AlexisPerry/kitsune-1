// RUN: mlir-translate -mlir-to-llvmir -split-input-file %s | FileCheck %s

// CHECK: @tapir_ops()
// CHECK: %[[SYNCREG:[0-9]+]] = call token @llvm.syncregion.start()
// CHECK: detach within %[[SYNCREG]], label %[[bb1:[0-9]+]], label %[[bb2:[0-9]+]]
// CHECK: [[bb1]]:
// CHECK: reattach within %[[SYNCREG]], label %[[bb2]]
// CHECK: [[bb2]]:
// CHECK: sync within %[[SYNCREG]], label {{.*}}

llvm.func @tapir_ops() {
  %sr = llvm_tapir.tapir_syncregion_start : !llvm.token
  llvm_tapir.detach %sr, ^bb1, ^bb2
^bb1:
  llvm_tapir.reattach %sr, ^bb2
^bb2:
  llvm_tapir.sync %sr, ^bb3
^bb3:
  llvm.return
}