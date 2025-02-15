// RUN: %clang_cc1 %s -x c -triple aarch64-freebsd -fopencilk -verify -S -emit-llvm -disable-llvm-passes -o - | FileCheck %s
// RUN: %clang_cc1 %s -x c++ -fopencilk -verify -S -emit-llvm -disable-llvm-passes -o - | FileCheck %s
extern void identity_long(void *);
extern void reduce_long(void *, void *);

typedef long _Hyperobject(identity_long, reduce_long) rlong __attribute__((aligned(8)));

// CHECK-LABEL: local_array_of_hyper
long local_array_of_hyper(unsigned int x)
{
  // CHECK: %x.addr = alloca
  // CHECK: %[[ARRAY:.+]] = alloca [10 x i64]
  // The outermost variable is not a hyperobject, and registration of
  // hyperobject array elements is not implemented.
  // CHECK-NOT: call void @llvm.reducer.register
  rlong array[10]; // expected-warning{{array of reducer not implemented}}
  // CHECK: getelementptr inbounds [[JUNK:.+]] %[[ARRAY]]
  // CHECK: %[[VIEW:.+]] = call ptr @llvm.hyper.lookup
  // CHECK-NOT: %[[VIEW:.+]] = call ptr @llvm.hyper.lookup
  // CHECK: %[[VAL:.+]] = load i64, ptr %[[VIEW]]
  return array[x];
  // CHECK-NOT: call void @llvm.reducer.unregister
  // CHECK ret i64 [[VAL]]
}

// CHECK-LABEL: local_hyper_of_array
long local_hyper_of_array(unsigned int x)
{
  // CHECK: %x.addr = alloca
  // CHECK: %[[ARRAY:.+]] = alloca [10 x i64]
  // A hyperobject without reducer attribute should not be registered.
  // CHECK-NOT: call void @llvm.reducer.register
  typedef long Array[10];
  Array _Hyperobject array;
  // CHECK: %[[VIEW:.+]] = call ptr @llvm.hyper.lookup
  // CHECK-NOT: %[[VIEW:.+]] = call ptr @llvm.hyper.lookup
  // CHECK: %[[ELEMENT:.+]] = getelementptr inbounds [[JUNK:.+]] %[[VIEW]]
  // CHECK: %[[VAL:.+]] = load i64, ptr %[[ELEMENT]]
  return array[x];
  // CHECK-NOT: call void @llvm.reducer.unregister
  // CHECK ret i64 [[VAL]]
}
