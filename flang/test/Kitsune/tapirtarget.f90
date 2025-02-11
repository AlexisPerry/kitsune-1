! RUN: %flang_fc1 -emit-fir -ftapir=serial %s -o - | FileCheck %s -check-prefix=TAPIR
! RUN: %flang_fc1 -emit-fir %s -o - | FileCheck %s -check-prefix=NO_TAPIR

! RUN: %flang_fc1 -emit-fir -ftapir=serial -O1 %s -o - | FileCheck %s -check-prefix=TAPIRO1
! RUN: %flang_fc1 -emit-fir -ftapir=serial -O2 %s -o - | FileCheck %s -check-prefix=TAPIRO2
! RUN: %flang_fc1 -emit-fir -ftapir=serial -O3 %s -o - | FileCheck %s -check-prefix=TAPIRO3


! This test checks that the tapir.loop.target module attribute is present
! only when it should be

!TAPIR:      module attributes {
!TAPIR-SAME: tapir.loop.target = [[SERIAL:[0-9]+]] : i32

!NO_TAPIR:      module attributes {
!NO_TAPIR-NOT: tapir.loop.target

!TAPIRO1:      module attributes {
!TAPIRO1-SAME: tapir.loop.target = [[SERIAL:[0-9]+]] : i32

!TAPIRO2:      module attributes {
!TAPIRO2-SAME: tapir.loop.target = [[SERIAL:[0-9]+]] : i32

!TAPIRO3:      module attributes {
!TAPIRO3-SAME: tapir.loop.target = [[SERIAL:[0-9]+]] : i32

program tapirTarget
  implicit none
  integer :: j

!TAPIR: fir.do_loop {{.*}} unordered
!TAPIR-SAME: attributes
!TAPIR-SAME: tapir.loop.target = [[SERIAL]] : i32

!NO_TAPIR: fir.do_loop {{.*}} unordered
!NO_TAPIR-NOT: tapir.loop.target

!TAPIRO1: fir.do_loop {{.*}} unordered
!TAPIRO1-SAME: attributes
!TAPIRO1-SAME: tapir.loop.target = [[SERIAL]] : i32

!TAPIRO2: fir.do_loop {{.*}} unordered
!TAPIRO2-SAME: attributes
!TAPIRO2-SAME: tapir.loop.target = [[SERIAL]] : i32

!TAPIRO3: fir.do_loop {{.*}} unordered
!TAPIRO3-SAME: attributes
!TAPIRO3-SAME: tapir.loop.target = [[SERIAL]] : i32

  DO CONCURRENT (j=1:10)
  END DO
  
!TAPIR: fir.do_loop {{.*}} 
!TAPIR-NOT: unordered
!TAPIR-NOT: tapir.loop.target

!NO_TAPIR: fir.do_loop {{.*}}
!NO_TAPIR-NOT: unordered
!NO_TAPIR-NOT: tapir.loop.target

!TAPIRO1: fir.do_loop {{.*}} 
!TAPIRO1-NOT: unordered
!TAPIRO1-NOT: tapir.loop.target

!TAPIRO2: fir.do_loop {{.*}} 
!TAPIRO2-NOT: unordered
!TAPIRO2-NOT: tapir.loop.target

!TAPIRO3: fir.do_loop {{.*}} 
!TAPIRO3-NOT: unordered
!TAPIRO3-NOT: tapir.loop.target

  DO j=1,10
  END DO

end program tapirTarget
