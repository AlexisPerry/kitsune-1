// RUN: %clang_cc1 -fcxx-exceptions -fexceptions -fopencilk -ftapir=none -triple x86_64-unknown-linux-gnu -std=c++11 -emit-llvm %s -o - | FileCheck %s --check-prefixes CHECK,CHECK-O0
// RUN: %clang_cc1 -fcxx-exceptions -fexceptions -fopencilk -ftapir=none -triple x86_64-unknown-linux-gnu -std=c++11 -O1 -mllvm -simplify-taskframes=false -emit-llvm %s -o - | FileCheck %s --check-prefixes CHECK,CHECK-O1
// expected-no-diagnostics

class Baz {
public:
  Baz();
  ~Baz();
  Baz(const Baz &that);
  Baz(Baz &&that);
  Baz &operator=(Baz that);
  friend void swap(Baz &left, Baz &right);
};

class Bar {
  int val[4] = {0,0,0,0};
public:
  Bar();
  ~Bar();
  Bar(const Bar &that);
  Bar(Bar &&that);
  Bar &operator=(Bar that);
  friend void swap(Bar &left, Bar &right);

  Bar(const Baz &that);

  const int &getVal(int i) const { return val[i]; }
  void incVal(int i) { val[i]++; }
};

class DBar : public Bar {
public:
  DBar();
  ~DBar();
  DBar(const DBar &that);
  DBar(DBar &&that);
  DBar &operator=(DBar that);
  friend void swap(DBar &left, DBar &right);
};

int foo(const Bar &b);

Bar makeBar();
void useBar(Bar b);

DBar makeDBar();
DBar makeDBarFromBar(Bar b);

Baz makeBaz();
Baz makeBazFromBar(Bar b);

void rule_of_four() {
  // CHECK-LABEL: define {{.*}}void @_Z12rule_of_fourv()
  Bar b0;
  Bar b5(_Cilk_spawn makeBar());
  // CHECK: %[[TASKFRAME:.+]] = call token @llvm.taskframe.create()
  // CHECK: detach within %[[SYNCREG:.+]], label %[[DETACHED:.+]], label %[[CONTINUE:.+]] unwind label %[[TFLPAD:.+]]
  // CHECK: [[DETACHED]]:
  // CHECK: invoke void @_Z7makeBarv(ptr {{.*}}sret(%class.Bar) {{.*}}%[[b5:.+]])
  // CHECK-NEXT: to label %[[REATTACH:.+]] unwind label %[[DETLPAD:.+]]
  // CHECK: [[REATTACH]]:
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE]]
  // CHECK: [[CONTINUE]]:
  Bar b4 = _Cilk_spawn makeBar();
  // CHECK: %[[TASKFRAME2:.+]] = call token @llvm.taskframe.create()
  // CHECK: detach within %[[SYNCREG]], label %[[DETACHED2:.+]], label %[[CONTINUE2:.+]] unwind label %[[TFLPAD2:.+]]
  // CHECK: [[DETACHED2]]:
  // CHECK: invoke void @_Z7makeBarv(ptr {{.*}}sret(%class.Bar) {{.*}}%[[b4:.+]])
  // CHECK-NEXT: to label %[[REATTACH2:.+]] unwind label %[[DETLPAD2:.+]]
  // CHECK: [[REATTACH2]]:
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE2]]
  // CHECK: [[CONTINUE2]]:
  b0 = _Cilk_spawn makeBar();
  // CHECK: %[[TASKFRAME3:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[AGGTMP:.+]] = alloca %class.Bar
  // CHECK: detach within %[[SYNCREG]], label %[[DETACHED3:.+]], label %[[CONTINUE3:.+]] unwind label %[[TFLPAD3:.+]]
  // CHECK: [[DETACHED3]]:
  // CHECK: invoke void @_Z7makeBarv(ptr {{.*}}sret(%class.Bar) {{.*}}%[[AGGTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT:.+]] unwind label %[[DETLPAD3:.+]]
  // CHECK: [[INVOKECONT]]:
  // CHECK-NEXT: %[[CALL:.+]] = invoke {{.*}}dereferenceable(16) ptr @_ZN3BaraSES_(ptr {{.*}}dereferenceable(16) %[[b0:.+]], ptr {{.*}}%[[AGGTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT2:.+]] unwind label %[[DETLPAD3_2:.+]]
  // CHECK: [[INVOKECONT2]]:
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE3]]
  // CHECK: [[CONTINUE3]]:
  _Cilk_spawn useBar(b0);
  // CHECK-O0: %[[TASKFRAME4:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[AGGTMP2:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1ERKS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]], ptr {{.*}}dereferenceable(16) %[[b0:.+]])
  // CHECK-NEXT: to label %[[INVOKECONT3:.+]] unwind label %[[TFLPAD4:.+]]
  // CHECK: [[INVOKECONT3]]:
  // CHECK-O0: detach within %[[SYNCREG]], label %[[DETACHED4:.+]], label %[[CONTINUE4:.+]] unwind label %[[TFLPAD4:.+]]
  // CHECK-O0: [[DETACHED4]]:
  // CHECK: invoke void @_Z6useBar3Bar(ptr {{.*}}%[[AGGTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT4:.+]] unwind label %[[DETLPAD4:.+]]
  // CHECK: [[INVOKECONT4]]:
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]])
  // CHECK-O0-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE4]]
  // CHECK-O0: [[CONTINUE4]]:

  // CHECK: [[DETLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE:.+]] unwind label %[[TFLPAD]]

  // CHECK: [[TFLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD2]]

  // CHECK: [[TFLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: [[DETLPAD3_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD3]]

  // CHECK: [[TFLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME3]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD4]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK-O0: br label %[[EHCLEANUP:.+]]

  // CHECK-O0: [[DETLPAD4]]:
  // CHECK-O0-NEXT: landingpad
  // CHECK-O0-NEXT: cleanup
  // CHECK-O0: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD4]]

  // CHECK-O0: [[EHCLEANUP]]:
  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME4]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind
}

void derived_class() {
  // CHECK-LABEL: define {{.*}}void @_Z13derived_classv()
  Bar b0, b6, b7;
  Bar b8 = _Cilk_spawn makeDBar(), b2 = _Cilk_spawn makeDBarFromBar(b0);
  // CHECK: %[[TASKFRAME:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[REFTMP:.+]] = alloca %class.DBar
  // CHECK: detach within %[[SYNCREG:.+]], label %[[DETACHED:.+]], label %[[CONTINUE:.+]] unwind label %[[TFLPAD:.+]]
  // CHECK: [[DETACHED]]:
  // CHECK: call void @llvm.taskframe.use(token %[[TASKFRAME]])
   // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %[[REFTMP]])
  // CHECK: invoke void @_Z8makeDBarv(ptr {{.*}}sret(%class.DBar) {{.*}}%[[REFTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT:.+]] unwind label %[[DETLPAD:.+]]
  // CHECK: [[INVOKECONT]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1EOS_(ptr {{.*}}dereferenceable(16) %[[b8:.+]], ptr {{.*}}dereferenceable(16) %[[REFTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT2:.+]] unwind label %[[DETLPAD_2:.+]]
  // CHECK: [[INVOKECONT2]]:
  // CHECK-NEXT: call void @_ZN4DBarD1Ev(ptr {{.*}}dereferenceable(16) %[[REFTMP]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %[[REFTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE]]
  // CHECK: [[CONTINUE]]:
  // CHECK: %[[TASKFRAME2:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[REFTMP2:.+]] = alloca %class.DBar
  // CHECK: %[[AGGTMP:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1ERKS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP]], ptr {{.*}}dereferenceable(16) %[[b0:.+]])
  // CHECK-NEXT: to label %[[INVOKECONT3:.+]] unwind label %[[TFLPAD2:.+]]
  // CHECK: [[INVOKECONT3]]:
  // CHECK: detach within %[[SYNCREG]], label %[[DETACHED2:.+]], label %[[CONTINUE2:.+]] unwind label %[[TFLPAD2]]
  // CHECK: [[DETACHED2]]:
  // CHECK: call void @llvm.taskframe.use(token %[[TASKFRAME2]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %[[REFTMP2]])
  // CHECK: invoke void @_Z15makeDBarFromBar3Bar(ptr {{.*}}sret(%class.DBar) {{.*}}%[[REFTMP2]], ptr {{.*}}%[[AGGTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT4:.+]] unwind label %[[DETLPAD2:.+]]
  // CHECK: [[INVOKECONT4]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1EOS_(ptr {{.*}}dereferenceable(16) %[[b2:.+]], ptr {{.*}}dereferenceable(16) %[[REFTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT5:.+]] unwind label %[[DETLPAD2_2:.+]]
  // CHECK: [[INVOKECONT5]]:
  // CHECK-NEXT: call void @_ZN4DBarD1Ev(ptr {{.*}}dereferenceable(16) %[[REFTMP2]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %[[REFTMP2]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE2]]
  // CHECK: [[CONTINUE2]]:
  b6 = _Cilk_spawn makeDBarFromBar(b7);
  // CHECK-O0: %[[TASKFRAME3:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[AGGTMP3:.+]] = alloca %class.Bar
  // CHECK: %[[REFTMP3:.+]] = alloca %class.DBar
  // CHECK: %[[AGGTMP2:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1ERKS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]], ptr {{.*}}dereferenceable(16) %[[b7:.+]])
  // CHECK-NEXT: to label %[[INVOKECONT6:.+]] unwind label %[[TFLPAD3:.+]]
  // CHECK: [[INVOKECONT6]]:
  // CHECK-O0: detach within %[[SYNCREG]], label %[[DETACHED3:.+]], label %[[CONTINUE3:.+]] unwind label %[[TFLPAD3]]
  // CHECK-O0: [[DETACHED3]]:
  // CHECK-O0: call void @llvm.taskframe.use(token %[[TASKFRAME3]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %[[REFTMP3]])
  // CHECK: invoke void @_Z15makeDBarFromBar3Bar(ptr {{.*}}sret(%class.DBar) {{.*}}%[[REFTMP3]], ptr {{.*}}%[[AGGTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT7:.+]] unwind label %[[DETLPAD3:.+]]
  // CHECK: [[INVOKECONT7]]:
  // CHECK-NEXT: invoke {{.*}}void @_ZN3BarC1EOS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]], ptr {{.*}}dereferenceable(16) %[[REFTMP3]])
  // CHECK-NEXT: to label %[[INVOKECONT8:.+]] unwind label %[[DETLPAD3_2:.+]]
  // CHECK: [[INVOKECONT8]]:
  // CHECK-NEXT: %[[CALL:.+]] = invoke {{.*}}dereferenceable(16) ptr @_ZN3BaraSES_(ptr {{.*}}dereferenceable(16) %[[b6:.+]], ptr {{.*}}%[[AGGTMP3]])
  // CHECK-NEXT: to label %[[INVOKECONT9:.+]] unwind label %[[DETLPAD3_3:.+]]
  // CHECK: [[INVOKECONT9]]:
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]])
  // CHECK-NEXT: call void @_ZN4DBarD1Ev(ptr {{.*}}dereferenceable(16) %[[REFTMP3]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %[[REFTMP3]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]])
  // CHECK-O0-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE3]]
  // CHECK-O0: [[CONTINUE3]]:

  // CHECK: [[DETLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE:.+]] unwind label %[[TFLPAD]]

  // CHECK: [[TFLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK-O1: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-O1-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD2_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD2]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3_3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK-O0: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD3]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME3]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind
}

void two_classes() {
  // CHECK-LABEL: define {{.*}}void @_Z11two_classesv()
  Bar b9, b11;
  Bar b12 = _Cilk_spawn makeBaz();
  // CHECK: %[[TASKFRAME:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[REFTMP:.+]] = alloca %class.Baz
  // CHECK: detach within %[[SYNCREG:.+]], label %[[DETACHED:.+]], label %[[CONTINUE:.+]] unwind label %[[TFLPAD:.+]]
  // CHECK: [[DETACHED]]:
  // CHECK: call void @llvm.taskframe.use(token %[[TASKFRAME]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %[[REFTMP]])
  // CHECK: invoke void @_Z7makeBazv(ptr {{.*}}sret(%class.Baz) {{.*}}%[[REFTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT:.+]] unwind label %[[DETLPAD:.+]]
  // CHECK: [[INVOKECONT]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1ERK3Baz(ptr {{.*}}dereferenceable(16) %[[b12:.+]], ptr {{.*}}dereferenceable(1) %[[REFTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT2:.+]] unwind label %[[DETLPAD_2:.+]]
  // CHECK: [[INVOKECONT2]]:
  // CHECK-NEXT: call void @_ZN3BazD1Ev(ptr {{.*}}dereferenceable(1) %[[REFTMP]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %[[REFTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE]]
  // CHECK: [[CONTINUE]]:
  Bar b13 = _Cilk_spawn makeBazFromBar(b9);
  // CHECK: %[[TASKFRAME2:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[REFTMP2:.+]] = alloca %class.Baz
  // CHECK: %[[AGGTMP:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1ERKS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP]], ptr {{.*}}dereferenceable(16) %[[b9:.+]])
  // CHECK-NEXT: to label %[[INVOKECONT3:.+]] unwind label %[[TFLPAD2:.+]]
  // CHECK: [[INVOKECONT3]]:
  // CHECK-NEXT: detach within %[[SYNCREG]], label %[[DETACHED2:.+]], label %[[CONTINUE2:.+]] unwind label %[[TFLPAD2]]
  // CHECK: [[DETACHED2]]:
  // CHECK: call void @llvm.taskframe.use(token %[[TASKFRAME2]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %[[REFTMP2]])
  // CHECK: invoke void @_Z14makeBazFromBar3Bar(ptr {{.*}}sret(%class.Baz) {{.*}}%[[REFTMP2]], ptr {{.*}}%[[AGGTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT4:.+]] unwind label %[[DETLPAD2:.+]]
  // CHECK: [[INVOKECONT4]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1ERK3Baz(ptr {{.*}}dereferenceable(16) %[[b13:.+]], ptr {{.*}}dereferenceable(1) %[[REFTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT5:.+]] unwind label %[[DETLPAD2_2:.+]]
  // CHECK: [[INVOKECONT5]]:
  // CHECK-NEXT: call void @_ZN3BazD1Ev(ptr {{.*}}dereferenceable(1) %[[REFTMP2]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %[[REFTMP2]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE2]]
  // CHECK: [[CONTINUE2]]:
  b9 = _Cilk_spawn makeBazFromBar(b11);
  // CHECK-O0: %[[TASKFRAME3:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[AGGTMP3:.+]] = alloca %class.Bar
  // CHECK: %[[REFTMP3:.+]] = alloca %class.Baz
  // CHECK: %[[AGGTMP2:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1ERKS_(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]], ptr {{.*}}dereferenceable(16) %[[b11:.+]])
  // CHECK-NEXT: to label %[[INVOKECONT6:.+]] unwind label %[[TFLPAD3:.+]]
  // CHECK: [[INVOKECONT6]]:
  // CHECK-O0-NEXT: detach within %[[SYNCREG]], label %[[DETACHED3:.+]], label %[[CONTINUE3:.+]] unwind label %[[TFLPAD3]]
  // CHECK-O0: [[DETACHED3]]:
  // CHECK-O0: call void @llvm.taskframe.use(token %[[TASKFRAME3]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %[[REFTMP3]])
  // CHECK: invoke void @_Z14makeBazFromBar3Bar(ptr {{.*}}sret(%class.Baz) {{.*}}%[[REFTMP3]], ptr {{.*}}%[[AGGTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT7:.+]] unwind label %[[DETLPAD3:.+]]
  // CHECK: [[INVOKECONT7]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1ERK3Baz(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]], ptr {{.*}}dereferenceable(1) %[[REFTMP3]])
  // CHECK-NEXT: to label %[[INVOKECONT8:.+]] unwind label %[[DETLPAD3_2:.+]]
  // CHECK: [[INVOKECONT8]]:
  // CHECK-NEXT: %[[CALL:.+]] = invoke {{.*}}dereferenceable(16) ptr @_ZN3BaraSES_(ptr {{.*}}dereferenceable(16) %[[b9:.+]], ptr {{.*}}%[[AGGTMP3]])
  // CHECK-NEXT: to label %[[INVOKECONT9:.+]] unwind label %[[DETLPAD3_3:.+]]
  // CHECK: [[INVOKECONT9]]:
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]])
  // CHECK-NEXT: call void @_ZN3BazD1Ev(ptr {{.*}}dereferenceable(1) %[[REFTMP3]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %[[REFTMP3]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]])
  // CHECK-O0-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE3]]
  // CHECK-O0: [[CONTINUE3]]:

  // CHECK: [[DETLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE:.+]] unwind label %[[TFLPAD]]

  // CHECK: [[TFLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK-O1-NEXT: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-O1-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD2_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD2]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD3_3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK-O0: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD3]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME3]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind
}

void array_out() {
  // CHECK-LABEL: define {{.*}}void @_Z9array_outv()
  // int Arri[5];
  // Example that produces a BinAssign expr.
  // bool Assign0 = (Arri[0] = foo(makeBazFromBar((Bar()))));
  // Pretty sure the following just isn't legal Cilk.
  // bool Assign1 = (Arri[1] = _Cilk_spawn foo(makeBazFromBar((Bar()))));

  Bar ArrBar[5];
  // ArrBar[0] = makeBazFromBar((Bar()));
  ArrBar[1] = _Cilk_spawn makeBazFromBar((Bar()));
  // CHECK: %[[ListBar2:.+]] = alloca [3 x %class.Bar]
  // CHECK: %[[TASKFRAME:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[AGGTMP2:.+]] = alloca %class.Bar
  // CHECK: %[[REFTMP:.+]] = alloca %class.Baz
  // CHECK: %[[AGGTMP:.+]] = alloca %class.Bar
  // CHECK: %[[ARRIDX:.+]] = getelementptr inbounds [5 x %class.Bar], ptr %[[ArrBar:.+]], i64 0, i64 1
  // CHECK: invoke void @_ZN3BarC1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT:.+]] unwind label %[[TFLPAD:.+]]
  // CHECK: [[INVOKECONT]]:
  // CHECK-NEXT: detach within %[[SYNCREG:.+]], label %[[DETACHED:.+]], label %[[CONTINUE:.+]] unwind label %[[TFLPAD]]
  // CHECK: [[DETACHED]]:
  // CHECK: call void @llvm.taskframe.use(token %[[TASKFRAME]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %[[REFTMP]])
  // CHECK: invoke void @_Z14makeBazFromBar3Bar(ptr {{.*}}sret(%class.Baz) {{.*}}%[[REFTMP]], ptr {{.*}}%[[AGGTMP]])
  // CHECK: to label %[[INVOKECONT2:.+]] unwind label %[[DETLPAD:.+]]
  // CHECK: [[INVOKECONT2]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1ERK3Baz(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]], ptr {{.*}}dereferenceable(1) %[[REFTMP]])
  // CHECK-NEXT: to label %[[INVOKECONT3:.+]] unwind label %[[DETLPAD_2:.+]]
  // CHECK: [[INVOKECONT3]]:
  // CHECK-NEXT: %[[CALL:.+]] = invoke {{.*}}dereferenceable(16) ptr @_ZN3BaraSES_(ptr {{.*}}dereferenceable(16) %[[ARRIDX]], ptr {{.*}}%[[AGGTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT4:.+]] unwind label %[[DETLPAD_3:.+]]
  // CHECK: [[INVOKECONT4]]:
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP2]])
  // CHECK-NEXT: call void @_ZN3BazD1Ev(ptr {{.*}}dereferenceable(1) %[[REFTMP]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %[[REFTMP]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP]])
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE]]
  // CHECL: [[CONTINUE]]:

  // List initialization
  // Bar ListBar1[3] = { Bar(), makeBar(), makeBazFromBar((Bar())) };
  Bar ListBar2[3] = { _Cilk_spawn Bar(), _Cilk_spawn makeBar(), _Cilk_spawn makeBazFromBar((Bar())) };
  // CHECK-O0: %[[ARRIDX0:.+]] = getelementptr inbounds [3 x %class.Bar], ptr %ListBar2, i64 0, i64 0
  // CHECK: %[[TASKFRAME2:.+]] = call token @llvm.taskframe.create()
  // CHECK: detach within %[[SYNCREG]], label %[[DETACHED2:.+]], label %[[CONTINUE2:.+]] unwind label %[[TFLPAD2:.+]]
  // CHECK: [[DETACHED2]]:
  // CHECK-O0: invoke void @_ZN3BarC1Ev(ptr {{.*}}dereferenceable(16) %[[ARRIDX0]])
  // CHECK-O1: invoke void @_ZN3BarC1Ev(ptr {{.*}}dereferenceable(16) %[[ListBar2]])
  // CHECK-NEXT: to label %[[INVOKECONT5:.+]] unwind label %[[DETLPAD2:.+]]
  // CHECK: [[INVOKECONT5]]:
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE2]]
  // CHECK: [[CONTINUE2]]:

  // CHECK-O0: %[[ARRIDX3:.+]] = getelementptr inbounds %class.Bar, ptr %[[ARRIDX0]], i64 1
  // CHECK-O1: %[[ARRIDX3:.+]] = getelementptr inbounds %class.Bar, ptr %[[ListBar2]], i64 1
  // CHECK: %[[TASKFRAME3:.+]] = call token @llvm.taskframe.create()
  // CHECK: detach within %[[SYNCREG]], label %[[DETACHED3:.+]], label %[[CONTINUE3:.+]] unwind label %[[TFLPAD3:.+]]
  // CHECK: [[DETACHED3]]:
  // CHECK: invoke void @_Z7makeBarv(ptr {{.*}}sret(%class.Bar) {{.*}}%[[ARRIDX3]])
  // CHECK-NEXT: to label %[[INVOKECONT6:.+]] unwind label %[[DETLPAD3:.+]]
  // CHECK: [[INVOKECONT6]]:
  // CHECK-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE3]]

  // CHECK-O0: %[[ARRIDX4:.+]] = getelementptr inbounds %class.Bar, ptr %[[ARRIDX3]], i64 1
  // CHECK-O1: %[[ARRIDX4:.+]] = getelementptr inbounds %class.Bar, ptr %[[ListBar2]], i64 2
  // CHECK-O0: %[[TASKFRAME4:.+]] = call token @llvm.taskframe.create()
  // CHECK: %[[REFTMP2:.+]] = alloca %class.Baz
  // CHECK: %[[AGGTMP3:.+]] = alloca %class.Bar
  // CHECK: invoke void @_ZN3BarC1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]])
  // CHECK-NEXT: to label %[[INVOKECONT7:.+]] unwind label %[[TFLPAD4:.+]]
  // CHECK: [[INVOKECONT7]]:
  // CHECK-O0-NEXT: detach within %[[SYNCREG]], label %[[DETACHED4:.+]], label %[[CONTINUE4:.+]] unwind label %[[TFLPAD4]]
  // CHECK-O0: [[DETACHED4]]:
  // CHECK-O0: call void @llvm.taskframe.use(token %[[TASKFRAME4]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %[[REFTMP2]])
  // CHECK: invoke void @_Z14makeBazFromBar3Bar(ptr {{.*}}sret(%class.Baz) {{.*}}%[[REFTMP2]], ptr {{.*}}%[[AGGTMP3]])
  // CHECK: to label %[[INVOKECONT8:.+]] unwind label %[[DETLPAD4:.+]]
  // CHECK: [[INVOKECONT8]]:
  // CHECK-NEXT: invoke void @_ZN3BarC1ERK3Baz(ptr {{.*}}%[[ARRIDX4:.+]], ptr {{.*}}dereferenceable(1) %[[REFTMP2]])
  // CHECK-NEXT: to label %[[INVOKECONT9:.+]] unwind label %[[DETLPAD4_2:.+]]
  // CHECK: [[INVOKECONT9]]:
  // CHECK-NEXT: call void @_ZN3BazD1Ev(ptr {{.*}}dereferenceable(1) %[[REFTMP2]])
  // CHECK-O1-NEXT: call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %[[REFTMP2]])
  // CHECK-NEXT: call void @_ZN3BarD1Ev(ptr {{.*}}dereferenceable(16) %[[AGGTMP3]])
  // CHECK-O0-NEXT: reattach within %[[SYNCREG]], label %[[CONTINUE4]]
  // CHECK-O0: [[CONTINUE4]]:

  // CHECK: [[TFLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup
  // CHECK-O1-NEXT: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME]],
  // CHECK-O1-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD_3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE:.+]] unwind label %[[TFLPAD]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD2]]

  // CHECK: [[TFLPAD2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME2]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[DETLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD3]]

  // CHECK: [[TFLPAD3]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME3]],
  // CHECK-NEXT: to label %[[UNREACHABLE]] unwind

  // CHECK: [[TFLPAD4]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD4]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK: [[DETLPAD4_2]]:
  // CHECK-NEXT: landingpad
  // CHECK-NEXT: cleanup

  // CHECK-O0: invoke void @llvm.detached.rethrow.sl_p0i32s(token %[[SYNCREG]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind label %[[TFLPAD4]]

  // CHECK-O0: invoke void @llvm.taskframe.resume.sl_p0i32s(token %[[TASKFRAME4]],
  // CHECK-O0-NEXT: to label %[[UNREACHABLE]] unwind
}
