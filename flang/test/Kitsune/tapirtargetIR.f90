! RUN: %flang_fc1 -emit-llvm -ftapir=serial %s -o - | FileCheck %s -check-prefix=TAPIR
! RUN: %flang_fc1 -emit-llvm %s -o - | FileCheck %s -check-prefix=NO_TAPIR
  
! TAPIR: %[[SYNCREG:[0-9]+]] = call token @llvm.syncregion.start()
! TAPIR: br label %[[HEADER:[0-9]+]]
! TAPIR: [[HEADER]]:
! TAPIR: br i1 %{{[0-9]+}}, label %[[FIRSTBLOCK:[0-9]+]], label %[[ENDBLOCK:[0-9]+]], !llvm.loop ![[META:[0-9]+]]
! TAPIR: [[FIRSTBLOCK]]:
! TAPIR: detach within %[[SYNCREG]], label %[[DETACHEDBLOCK:[0-9]+]], label %[[REATTACHBLOCK:[0-9]+]]
! TAPIR: [[DETACHEDBLOCK]]:
! TAPIR: reattach within %[[SYNCREG]], label %[[REATTACHBLOCK]]
! TAPIR: [[REATTACHBLOCK]]:
! TAPIR: br label %[[HEADER]]
! TAPIR: [[ENDBLOCK]]:
! TAPIR: sync within %[[SYNCREG]], label {{.*}}
! TAPIR: ![[META]] = distinct !{![[META]], ![[TAPIRTARGET:[0-9]+]]}
! TAPIR: ![[TAPIRTARGET]] = !{!"tapir.loop.target", i32 {{[0-9]+}}}

! NO_TAPIR-NOT: llvm.syncregion.start
! NO_TAPIR-NOT: detach
! NO_TAPIR-NOT: reattach
! NO_TAPIR-NOT: sync within
! NO_TAPIR-NOT: !{{[0-9]+}} = !{!"tapir.loop.target", i32 {{[0-9]+}}}

program this
  implicit none
  integer :: j
  
  DO CONCURRENT (j=1:10)
  END DO
end program this
