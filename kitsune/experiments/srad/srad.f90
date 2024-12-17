program main
  implicit none

  integer :: rows, cols, size_i, size_r, niter
  real, allocatable :: i(:), j(:)
  real :: q0sqr, tmp, mean_roi, var_roi
  real :: jc, g2, l, num, den, qsqr
  integer, allocatable :: in(:), is(:), je(:), jw(:)
  integer :: r1, r2, c1, c2
  real :: cn, cs, cw, ce
  real, allocatable :: c(:)
  real :: d, lambda
  real, allocatable :: dn(:), ds(:), dw(:), de(:)
  integer :: argc
  integer :: start_time, stop_time, elapsed_time
  integer :: loop1_total_time, loop2_total_time
  integer :: loop1_max_time, loop1_min_time, loop1_time, loop1_start_time, loop1_end_time
  integer :: loop2_max_time, loop2_min_time, loop2_time, loop2_start_time, loop2_end_time
  integer :: ii, jj, kk, iter
  real :: sum, sum2
  real :: rate

  argc = command_argument_count()
  if (argc == 8) then
     rows   = command_argument_to_i(1) ! number of rows in the domain
     cols   = command_argument_to_i(2) ! number of cols in the domain
     r1     = command_argument_to_i(3) ! y1 position of the speckle
     r2     = command_argument_to_i(4) ! y2 position of the speckle
     c1     = command_argument_to_i(5) ! x1 position of the speckle
     c2     = command_argument_to_i(6) ! x2 position of the speckle
     lambda = command_argument_to_f(7) ! Lambda value
     niter  = command_argument_to_i(8) ! number of iterations
  else if (argc == 0) then
     rows   = 6400
     cols   = 6400
     r1     = 0
     r2     = 127
     c1     = 0
     c2     = 127
     lambda = 0.5
     niter  = 2000
  else
     call usage
     stop 1
  end if

  if (mod(rows, 16) /= 0 .and. mod(cols, 16) /= 0) then
     write(*,*) "Rows and cols must be multiples of 16"
     stop 1
  end if

  write(*,"(A,I0)") "  Rows:       ", rows
  write(*,"(A,I0)") "  Cols:       ", cols
  write(*,"(A,I0)") "  Iterations: ", niter

  loop1_max_time = 0
  loop1_min_time = huge(loop1_min_time)
  loop1_total_time = 0
  loop2_max_time = 0
  loop2_min_time = huge(loop2_min_time)
  loop2_total_time = 0

  size_i = cols * rows
  size_r = (r2 - r1 + 1) * (c2 - c1 + 1)

  allocate(i(size_i))
  allocate(j(size_i))
  allocate(c(size_i))
  allocate(in(rows))
  allocate(is(rows))
  allocate(jw(cols))
  allocate(je(cols))
  allocate(dn(size_i))
  allocate(ds(size_i))
  allocate(dw(size_i))
  allocate(de(size_i))

  call random_number(i)
  call system_clock(COUNT_RATE=rate)

  write(*,"(A)") "  Starting benchmark ... "

  call system_clock(start_time)

  do concurrent (ii = 0 : rows - 1)
     in(ii + 1) = ii - 1
     is(ii + 1) = ii + 1
  end do

  do concurrent (jj = 0 : cols - 1)
     jw(jj + 1) = jj - 1
     je(jj + 1) = jj + 1
  end do

  in(1) = 0
  is(rows) = rows - 1
  jw(1) = 0
  je(cols) = cols - 1

  do concurrent(kk = 1 : size_i)
     j(kk) = exp(i(kk))
  end do

  do iter = 1, niter
     sum = 0
     sum2 = 0

     do ii = r1, r2
        do jj = c1, c2
           tmp = j(ii * cols + jj + 1)
           sum = sum + tmp
           sum2 = sum2 + tmp * tmp
        end do
     end do

     mean_roi = sum / size_r
     var_roi = (sum2 / size_r) - mean_roi * mean_roi
     q0sqr = var_roi / (mean_roi * mean_roi)

     call system_clock(loop1_start_time)
     do concurrent (ii = 0 : rows - 1)
        do jj = 0, cols - 1
           kk = ii * cols + jj + 1
           jc = j(kk)

           ! directional derivatives
           dn(kk) = j(in(ii + 1) * cols + jj + 1) - jc
           ds(kk) = j(is(ii + 1) * cols + jj + 1) - jc
           de(kk) = j(ii * cols + je(jj + 1) + 1) - jc
           dw(kk) = j(ii * cols + jw(jj + 1) + 1) - jc

           g2 = (dn(kk)**2 + ds(kk)**2 + dw(kk)**2 + de(kk)**2) / (jc * jc)
           l = (dn(kk) + ds(kk) + dw(kk) + de(kk)) / jc
           num = (0.5 * g2) - (1.0 / 16.0) * (l * l)
           den = 1 + (0.25 * l)
           qsqr = num / (den * den)

           ! diffusion coefficient (equ 33)
           den = (qsqr - q0sqr) / (q0sqr * (1 + q0sqr))
           c(kk) = 1.0 / (1.0 + den)

           ! saturate diffusion coefficient
           if (c(kk) < 0) then
              c(kk) = 0.0
           else if (c(kk) > 1) then
              c(kk) = 1.0
           end if
        end do
     end do
     call system_clock(loop1_end_time)

     loop1_time = dble(loop1_end_time - loop1_start_time) / rate
     loop1_total_time = loop1_total_time + loop1_time
     if (loop1_time < loop1_min_time) then
        loop1_min_time = loop1_time
     end if
     if (loop1_time > loop1_max_time) then
        loop1_max_time = loop1_time
     end if

     call system_clock(loop2_start_time)
     do concurrent (ii = 0 : rows - 1)
        do jj = 0, cols - 1
           ! current index
           kk = ii * cols + jj + 1
           cn = c(kk)
           cs = c(is(ii + 1) * cols + jj + 1)
           cw = c(kk)
           ce = c(ii * cols + je(jj + 1) + 1)
           ! divergence (equ 58)
           d = cn * dn(kk) + cs * ds(kk) + cw * dw(kk) + ce * de(kk)
           ! image update (equ 61)
           j(kk) = j(kk) + 0.25 * lambda * d
        end do
     end do
     call system_clock(loop2_end_time)

     loop2_time = dble(loop2_end_time - loop2_start_time) / rate
     loop2_total_time = loop2_total_time + loop2_time
     if (loop2_time < loop2_min_time) then
        loop2_min_time = loop2_time
     end if
     if (loop2_time > loop2_max_time) then
        loop2_max_time = loop2_time
     end if
  end do

  call system_clock(stop_time)
  elapsed_time = dble(stop_time - start_time) / rate

  write(*,"(A,I0)") "  Loop 1 total: ", loop1_total_time
  write(*,"(A,F10.3)") "  Loop 1 mean:  ", dble(loop1_total_time) / dble(niter)
  write(*,"(A,I0)") "  Loop 1 min:   ", loop1_min_time
  write(*,"(A,I0)") "  Loop 1 max:   ", loop1_max_time
  write(*,"(A,I0)") "  Loop 2 total: ", loop2_total_time
  write(*,"(A,F10.3)") "  Loop 2 mean:  ", dble(loop2_total_time) / dble(niter)
  write(*,"(A,I0)") "  Loop 2 min:   ", loop2_min_time
  write(*,"(A,I0)") "  Loop 2 max:   ", loop2_max_time
  write(*,"(A,I0,A)") "  Total:        ", elapsed_time, " seconds"

  ! This is written in text while the C++ srad writes out a binary file.
  open (unit=10, file="srad-forall-output-fort.dat", action="write")
  do ii = 1, size_i
     write(10, "(F10.8,A)", advance="no") J(ii), " "
  end do
  close (10)

contains

  subroutine usage()
    implicit none

    character(32) :: exe

    call get_command_argument(0, exe)
    write(*,"(A,A,A)") "Usage: ", trim(exe), &
         " <rows> <cols> <y1> <y2> <x1> <x2> <lambda> <no. of iter>"
    write(*,*) "    <rows>        - number of rows"
    write(*,*) "    <cols>        - number of cols"
    write(*,*) "    <y1>          - y1 value of the speckle"
    write(*,*) "    <y2>          - y2 value of the speckle"
    write(*,*) "    <x1>          - x1 value of the speckle"
    write(*,*) "    <x2>          - x2 value of the speckle"
    write(*,*) "    <lambda>      - lambda (0,1)"
    write(*,*) "    <no. of iter> - number of iterations"
  end subroutine usage

  integer function command_argument_to_i(n)
    implicit none

    integer, intent(in) :: n
    character(32) :: buf

    call get_command_argument(n, buf)
    read (buf,*) command_argument_to_i
  end function command_argument_to_i

  real function command_argument_to_f(n)
    implicit none

    integer, intent(in) :: n
    character(32) :: buf

    call get_command_argument(n, buf)
    read (buf,*) command_argument_to_f
  end function command_argument_to_f

end program main
