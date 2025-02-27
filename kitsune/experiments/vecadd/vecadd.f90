program main
  implicit none

  integer(8) :: sz, iters
  integer(8) :: i
  integer :: tick, tock, rate, errors
  real(8) :: elapsed, lo, hi, total
  real(4), allocatable :: a(:), b(:), c(:)

  sz = get_command_argument_or(1, 1024 * 1024 * 256_8)
  iters = get_command_argument_or(2, 10_8)

  write (*,"(A,I0,A/)") "  Vector size: ", sz, " elements"
  write (*,"(A)", advance="no") "  Allocating arrays and filling with random values ... "

  allocate(a(sz))
  allocate(b(sz))
  allocate(c(sz))

  ! vecadd-forall.cpp uses a forall to initialize the arrays. This is not
  ! allowed in Fortran because the compiler (rightly) complains that the call
  ! to RANDOM_NUMBER inside a DO CONCURRENT loop is not pure. We don't really
  ! need that to be a DO CONCURRENT anyway, so just do it in the "Fortran way".
  call random_number(a)
  call random_number(b)

  write (*,"(A/)") "done"

  lo = huge(lo)
  hi = 0
  total = 0.0
  do i = 1, iters
     call system_clock(tick, rate)
     do concurrent (i = 1 : sz)
        c(i) = a(i) + b(i)
     end do
     call system_clock(tock, rate)
     elapsed = dble(tock - tick) / dble(rate)

     ! The first iteration is nearly always significantly slower than the
     ! others, probably because the cache needs to be warmed up.
     if (i > 1) then
        if (elapsed < lo) then
           lo = elapsed
        end if
        if (elapsed > hi) then
           hi = elapsed
        end if
        total = total + elapsed
     end if
     write(*, "(A,F10.3)") "  Iteration time: ", elapsed
  end do
  write(*, "(/A)", advance="no") "  Checking final result ... "

  errors = check(a, b, c)
  if (errors /= 0) then
     write (*, "(A/)") "FAIL!"
  else
     write(*, "(A/)") "pass"
     write(*, "(A14,F10.3,A)") "  Total time: ", total, " seconds"
     write(*, "(A14,F10.3,A)") "    Min: ", lo, " seconds"
     write(*, "(A14,F10.3,A)") "    Max: ", hi, " seconds"
     write(*, "(A14,F10.3,A)") "    Mean: ", total / dble(iters - 1), " seconds"
  end if

  deallocate(c)
  deallocate(b)
  deallocate(a)

  if (errors /= 0) then
     stop errors
  end if

contains

  integer(8) function check(a, b, c)
    real, allocatable, intent(in) :: a(:), b(:), c(:)
    real(4), parameter :: epsilon = 1E-14

    check = 0
    do i = 1, size(a, 1)
       if (abs(a(i) + b(i) - c(i)) > epsilon) then
          check = check + 1
       end if
    end do
  end function check

  integer(8) function get_command_argument_or(n, default)
    implicit none

    integer, intent(in) :: n
    integer(8), intent(in) :: default
    character(32) :: buf

    if (command_argument_count() >= n) then
       call get_command_argument(n, buf)
       read (buf, *) get_command_argument_or
    else
       get_command_argument_or = default
    end if
  end function get_command_argument_or
end program main
