// RUN: fir-opt  %s | FileCheck %s -check-prefix=FIR
// RUN: fir-opt --cfg-conversion --fir-to-llvm-ir="target=x86_64-unknown-linux-gnu" %s | FileCheck %s -check-prefix=LLVM

// FIR: #loop_annotation = #llvm.loop_annotation<{{.*}}tapirLoopTarget =
// FIR: module attributes {
// FIR-SAME: tapir.loop.target =
// FIR: fir.do_loop {{.*}} unordered
// FIR-SAME: attributes
// FIR-SAME: loopAnnotation = #loop_annotation
// FIR-SAME: tapir.loop.target =

// LLVM: #loop_annotation = #llvm.loop_annotation<{{.*}}tapirLoopTarget =
// LLVM: module attributes {
// LLVM-SAME: tapir.loop.target =
// LLVM: llvm.cond_br {{.*}}loop_annotation = #loop_annotation

#loop_annotation = #llvm.loop_annotation<tapirLoopTarget = 1 : i32>
module attributes {tapir.loop.target = 1 : i32} {
  func.func @_QQmain() attributes {fir.bindc_name = "tapirtarget"} {
    %c1 = arith.constant 1 : index
    %c10_i32 = arith.constant 10 : i32
    %c1_i32 = arith.constant 1 : i32
    %0 = fir.convert %c1_i32 : (i32) -> index
    %1 = fir.convert %c10_i32 : (i32) -> index
    fir.do_loop %arg0 = %0 to %1 step %c1 unordered attributes {loopAnnotation = #loop_annotation, tapir.loop.target = 1 : i32} {
    }
    return
  }
}
