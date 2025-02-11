! RUN: %flang_fc1 -emit-llvm -ftapir=serial %s -o - | FileCheck %s -check-prefix=TAPIR
! RUN: %flang_fc1 -emit-llvm %s -o - | FileCheck %s -check-prefix=NO_TAPIR
  
! TAPIR: br i1 %{{[0-9]+}}, label %{{[0-9]+}}, label %{{[0-9]+}}, !llvm.loop ![[META:[0-9]+]]
! TAPIR: ![[META]] = distinct !{![[META]], ![[TAPIRTARGET:[0-9]+]]}
! TAPIR: ![[TAPIRTARGET]] = !{!"tapir.loop.target", i32 {{[0-9]+}}}

! NO_TAPIR-NOT: !{{[0-9]+}} = !{!"tapir.loop.target", i32 {{[0-9]+}}}

program this
  implicit none
  integer :: j
  
  DO CONCURRENT (j=1:10)
  END DO
end program this
