program main
  implicit none

  integer(8) :: sz, iters
  integer(8) :: i
  integer :: tick, tock, rate, errors
  real(8) :: elapsed, lo, hi, total
  real(4), allocatable :: x(:), y(:)
  real(4) :: default_x, default_y, default_a

  sz = get_command_argument_or(1, lshift(1_8, 28_8))
  iters = get_command_argument_or(2, 10_8)

  write (*,"(A,I0,A/)") "  Problem size: ", sz, " elements"
  write (*,"(A)", advance="no") "  Allocating arrays and filling with random values ... "

  allocate(x(sz))
  allocate(y(sz))

  write (*,"(A/)") "done"

  call random_number(default_a)
  call random_number(default_x)
  call random_number(default_y)

  lo = huge(lo)
  hi = 0
  total = 0.0
  do i = 1, iters
     call system_clock(tick, rate)
     do concurrent (i = 1 : sz)
        x(i) = default_x
        y(i) = default_y
     end do
     do concurrent (i = 1 : sz)
        y(i) = default_a * x(i) + y(i)
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

  errors = check(y, default_x, default_y, default_a)
  if (errors /= 0) then
     write(*, "(A/)") "FAIL!"
  else
     write(*, "(A/)") "pass"
     write(*, "(A14,F10.3,A)") "  Total time: ", total, " seconds"
     write(*, "(A14,F10.3,A)") "    Min: ", lo, " seconds"
     write(*, "(A14,F10.3,A)") "    Max: ", hi, " seconds"
     write(*, "(A14,F10.3,A)") "    Mean: ", total / dble(iters - 1), " seconds"
  end if

  deallocate(y)
  deallocate(x)

  if (errors /= 0) then
     stop errors
  end if

contains

  integer(8) function check(y, default_x, default_y, default_a)
    implicit none

    real(4), allocatable, intent(in) :: y(:)
    real(4), intent(in) :: default_x, default_y, default_a
    real(4), parameter :: epsilon = 1E-14
    real(4) :: err
    integer(8) :: i

    err = 0.0
    do i = 1, size(y, 1)
       err = err + abs(y(i) - (default_a * default_x + default_y))
    end do

    if (err > epsilon) then
       check = 1
    else
       check = 0
    end if
  end function check

  integer(8) function get_command_argument_or(n, default)
    implicit none

    integer :: n
    integer(8) :: default
    character(32) :: buf

    if (command_argument_count() >= n) then
       call get_command_argument(n, buf)
       read (buf, *) get_command_argument_or
    else
       get_command_argument_or = default
    end if
  end function get_command_argument_or
end program main
