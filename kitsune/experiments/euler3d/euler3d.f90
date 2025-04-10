program euler3d
  implicit none

  type Float3
     real :: x, y, z
  end type Float3

  integer :: block_length = 1
!
!  Options
!
  real :: GAMMA = 1.4
  integer :: NDIM = 3
  integer :: NNB =4
  integer :: RK = 3	! 3rd order RK
  real :: ff_mach = 1.2
  real :: deg_angle_of_attack = 0.0
!
! not options
!
  integer :: VAR_DENSITY = 1
  integer :: VAR_MOMENTUM = 2
  integer :: VAR_DENSITY_ENERGY ! must equal VAR_MOMENTUM + NDIM
  integer :: NVAR ! must equal VAR_DENSITY_ENERGY + 1

  !Command line parsing
  integer :: num_args, ix
  character(len=12), dimension(:), allocatable :: args
  character(len=256) :: line

  !Timer vars
  real(8) :: total_start_time, start_time, end_time, elapsed_time, total_time,time
  real(8) :: copy_total, copy_start, copy_end
  real(8) :: sf_total, sf_start, sf_end
  real(8) :: rk_total, rk_start, rk_end
  real(8), dimension(:), allocatable :: rk_times
  real(8) :: rk_mean, sum, dist, rk_std_dev
  
  !Program variables
  integer :: iterations
  character (len=128) :: data_file_name

  !far field conditions
  real, dimension(:), allocatable :: ff_variable 
  type(Float3) :: ff_flux_contribution_momentum_x, ff_flux_contribution_momentum_y
  type(Float3) :: ff_flux_contribution_momentum_z
  type(Float3) :: ff_flux_contribution_density_energy
  real :: angle_of_attack
  real :: ff_pressure, ff_speed_of_sound, ff_speed
  type(Float3) :: ff_velocity, ff_momentum

  !domain geometry and file data
  integer :: nel, nelr, io, last
  real, dimension(:), allocatable :: areas
  integer, dimension(:, :), allocatable :: elements_surrounding_elements
  real, dimension(:, :, :), allocatable :: normals

  ! generic DO loop iterator vars
  integer :: i, j, k

  ! initial conditions
  real, dimension(:,:), allocatable :: variables, old_variables, fluxes
  real, dimension(:), allocatable :: step_factors
  
  ! setting parameters that would be #defined in c-style
  VAR_DENSITY_ENERGY = VAR_MOMENTUM + NDIM
  NVAR = VAR_DENSITY_ENERGY + 1

  num_args = command_argument_count()
  if (num_args < 1) then
     print *, "specify data file name"
     STOP
  end if
  
  allocate(args(num_args))  
  do ix = 1, num_args
     call get_command_argument(ix,args(ix))
  end do

  call getarg(1, data_file_name)

  iterations = 4000
  if (num_args > 1) then
     read(args(2), *) iterations
  end if

  !NOTE: I believe the c++ code is set such that all numbers print out having
  ! 5 significant digits.  I may need to replicate this here to ensure outputs
  ! match appropriately, but I do not yet know how to do this.
  print *, "---- euler3d benchmark (Fortran) ----"
  print *, ""
  print *, "  Input file : ", data_file_name
  print *, "  Iterations : ", iterations, "." 
  print *, "  Reading input data, allocating arrays, initializing data, etc..."

  call cpu_time(total_start_time) 

  ! set far field conditions
  angle_of_attack = real(3.1415926535897931 / 180.0) * real(deg_angle_of_attack)
  allocate(ff_variable(NVAR))
  ff_variable(VAR_DENSITY) = 1.4
  ff_pressure = 1.0
  ff_speed_of_sound = sqrt(GAMMA * ff_pressure / ff_variable(VAR_DENSITY))
  ff_speed = real(ff_mach) * ff_speed_of_sound

  ff_velocity%x = ff_speed * cos(angle_of_attack)
  ff_velocity%y = ff_speed * sin(angle_of_attack)
  ff_velocity%z = 0.0

  ff_variable(VAR_MOMENTUM+0) = ff_variable(VAR_DENSITY) * ff_velocity%x
  ff_variable(VAR_MOMENTUM+1) = ff_variable(VAR_DENSITY) * ff_velocity%y
  ff_variable(VAR_MOMENTUM+2) = ff_variable(VAR_DENSITY) * ff_velocity%z

  ff_variable(VAR_DENSITY_ENERGY) = (ff_variable(VAR_DENSITY) &
       * (0.5 * (ff_speed*ff_speed))) + (ff_pressure / real(GAMMA-1.0))

  !NOTE: this next bit just looks weird to me... how is it different from
  ! ff_momentum%x = ff_variable(VAR_MOMENTUM+0)
  ! Also, is it legal to do this in Fortran this way?
  ff_momentum%x = ff_variable(VAR_MOMENTUM+0)
  ff_momentum%y = ff_variable(VAR_MOMENTUM+1)
  ff_momentum%z = ff_variable(VAR_MOMENTUM+2)

  call compute_flux_contribution(ff_variable(VAR_DENSITY), ff_momentum, &
       ff_variable(VAR_DENSITY_ENERGY), ff_pressure, ff_velocity, &
       ff_flux_contribution_momentum_x, ff_flux_contribution_momentum_y, &
       ff_flux_contribution_momentum_z, ff_flux_contribution_density_energy)

  ! read in domain geometry
  open(newunit=io, file=data_file_name, status="old", action="read")
  read(io, *) nel
  nelr = block_length*((nel / block_length )+ min(1, modulo(nel, block_length)))
  allocate(areas(nelr))
  allocate(elements_surrounding_elements(nelr,NNB))
  allocate(normals(nelr, NNB, NDIM))

  ! read in data
  DO i = 1, nel
     read(io,'(A)') line
     call readline(line, areas(i), &
          elements_surrounding_elements(i,:), normals(i,:,:), i)
  end DO

  ! fill in remaining data
  last = nel - 1
  areas(nel:nelr) = areas(last)
  DO i = nel, nelr
     elements_surrounding_elements(i,1:NNB) = &
          elements_surrounding_elements(last, 1:NNB)
     normals(i, 1:NNB, 1:NDIM) = normals(last, 1:NNB, 1:NDIM)
  end DO

  ! Create arrays and set initial conditions
  allocate(variables(nelr, NVAR))
  print *, "  done."

  print *, "  Starting benchmark..."
  call cpu_time(start_time)
  call initialize_variables(nelr, variables, ff_variable)
  allocate(old_variables(nelr,NVAR))
  allocate(fluxes(nelr,NVAR))
  allocate(step_factors(nelr))
  allocate(rk_times(iterations)) 

  ! Begin iterations
  copy_total = 0.0
  sf_total = 0.0
  rk_total = 0.0

  DO i = 1, iterations
     call cpu_time(copy_start)
     !cpy(old_variables, variables, nelr, NVAR)
     old_variables = variables
     call cpu_time(copy_end)
     time = copy_end - copy_start
     call increment_real8(copy_total, time)

     ! for the first iteration we compute the time step
     call cpu_time(sf_start)
     call compute_step_factor(nelr, variables, areas, step_factors)
     call cpu_time(sf_end)
     time = sf_end - sf_start
     call increment_real8(sf_total, time)

     call cpu_time(rk_start)
     DO j = 1, RK 
        call compute_flux ( nelr, elements_surrounding_elements, normals, &
             variables, fluxes, ff_variable, ff_flux_contribution_momentum_x, &
             ff_flux_contribution_momentum_y, ff_flux_contribution_momentum_z, &
             ff_flux_contribution_density_energy )
        call time_step (j, nelr, old_variables, variables, step_factors, fluxes)
     end DO
     call cpu_time(rk_end)
     time = rk_end - rk_start
     if (i > 1) then
        rk_times(i) = time
        call increment_real8(rk_total, time)
     end if
  end DO
  
  call dump(variables, nel, nelr)

  call cpu_time(end_time)
  elapsed_time = end_time - start_time
  total_time = end_time - total_start_time
  rk_mean = rk_total / (iterations -1)
  sum = 0.0
  DO i = 2, iterations
     dist = rk_times(i) - rk_mean
     call increment_real8(sum, dist * dist)
  end DO
  rk_std_dev = sqrt(sum / iterations)

  print *, ""
  print *, "      Total time : ", total_time, " seconds."
  print *, "    Compute time : " , elapsed_time, " seconds."
  print *, "            copy : " ,  copy_total, " seconds"
  print *, "                   (average: ", copy_total / iterations, " seconds)."
  print *, "              sf : " , sf_total, " seconds"
  print *, "                   (average: ", sf_total / iterations, " seconds)."
  print *, "              rk : " , rk_total, " seconds"
  print *, "                   (average: ", rk_mean, " seconds / "
  print *, "                    std dev: " , rk_std_dev, ")."
  print *, "*** " , elapsed_time, ", ", elapsed_time
  print *, "----"

  deallocate(rk_times)
  deallocate(step_factors)
  deallocate(fluxes)
  deallocate(old_variables)
  deallocate(variables)  
  deallocate(normals)
  deallocate(elements_surrounding_elements)
  deallocate(areas)
  deallocate(ff_variable)
  deallocate(args)
  !NOTE: check that everythign that was allocated has been deallocated

contains

  subroutine readline (line, area, e_s_e, norms, i)
    character(len=256), intent(in) :: line
    real, intent(inout) :: area
    integer, dimension(:), intent(inout) :: e_s_e
    real, dimension(:,:), intent(inout) :: norms
    integer, intent(in) :: i
    integer :: j,k, begin, end
    character(len=55) :: substr
    character(len=15) :: subsubstr

    read(line, *) area
    !if (i < 5) then
    !   print *, "line = ", line, "***"
    !   print *, "area = ", area
    !endif

    DO j = 1, NNB
       begin = 16 + (55 * (j-1))
       end = 16 + (55 * j)
       substr = line(begin:end)
       read(substr, *) e_s_e(j)
       !if (i < 5) then
       !   print *, "substr = ", substr
       !   print *, "e_s_e(",j,") = ", e_s_e(j)
       !endif
       if (e_s_e(j) < 0) then
          e_s_e(j) = -1
       endif
       DO k = 1, NDIM
          begin = 11 + (15 * (k-1))
          end = 11 + (15 * k)
          subsubstr = substr(begin:end)
          read(subsubstr, *) norms(j, k)
          !if (i < 5) then
          !   print *, "subsubstr = ", subsubstr
          !   print *, "norms(",j,",",k,") = ", norms(j,k)
          !endif
          norms(j, k) = -norms(j, k)
       end DO
    end DO
  end subroutine readline

  !NOTE: might be able to get rid of this in favor of simply assigning src to dst
  pure subroutine cpy (dst, src, N, M)
    real, dimension(:,:), intent(inout) :: dst
    real, dimension(:,:), intent(in) :: src
    integer, intent(in) :: N, M
    integer :: i, j

    DO CONCURRENT (i = 1:N, j = 1:M)
       dst(i,j) = src(i,j)
    end DO
    ! or dst = src
  end subroutine cpy

  subroutine dump (variables, nel, nelr)
    real, dimension(:,:), intent(in) :: variables
    integer, intent(in) :: nel, nelr
    integer :: io, i, j
    
    open(newunit=io, file="density-Fortran.dat")
    write(io, *) nel, " ", nelr
    DO i = 1, nel
       write(io, *) variables(i, VAR_DENSITY)
    end DO
    close(io)

    open(newunit=io, file="momentum-Fortran.dat")
    write(io, *) nel, " ", nelr
    DO i = 1, nel
       DO j = 1, NDIM
          !This is hardcoded for NDIM=3
          write(io, "(3G0.6)", advance="no") variables(i, VAR_MOMENTUM +j-1), " "
       end DO
       write(io, *) ""
    end DO
    close(io)
 
    open(newunit=io, file="density_energy-Fortran.dat")
    write(io, *) nel, " ", nelr
    DO i = 1, nel
       write(io, *) variables(i, VAR_DENSITY_ENERGY)
    end DO
    close(io)
    
  end subroutine dump

  pure subroutine initialize_variables (nelr, variables, ff_variable)
    integer, intent(in) :: nelr
    real, dimension (:,:), intent(inout) :: variables
    real, dimension (:), intent(in) ::ff_variable
    integer :: i, j
    
    DO CONCURRENT (i = 1:nelr, j = 1:NVAR)
       variables(i,j) = ff_variable(j)
    end DO
  end subroutine initialize_variables

  pure subroutine compute_flux_contribution (density, momentum, density_energy, &
       pressure, velocity, fc_momentum_x, fc_momentum_y, fc_momentum_z, &
       fc_density_energy)
    real, intent(in) :: density, density_energy, pressure
    type(Float3), intent(in) :: momentum, velocity
    type(Float3), intent(inout) :: fc_momentum_x, fc_momentum_y, fc_momentum_z
    type(Float3), intent(inout) :: fc_density_energy
    real de_p

    fc_momentum_x%x = (velocity%x * momentum%x) + pressure
    fc_momentum_x%y = velocity%x * momentum%y
    fc_momentum_x%z = velocity%x * momentum%z
    
    fc_momentum_y%x = fc_momentum_x%y
    fc_momentum_y%y = (velocity%y * momentum%y) + pressure
    fc_momentum_y%z = velocity%y * momentum%z
    
    fc_momentum_z%x = fc_momentum_x%z
    fc_momentum_z%y = fc_momentum_y%z
    fc_momentum_z%z = (velocity%z * momentum%z) + pressure
    
    de_p = density_energy + pressure
    fc_density_energy%x = velocity%x * de_p
    fc_density_energy%y = velocity%y * de_p
    fc_density_energy%z = velocity%z * de_p

  end subroutine compute_flux_contribution

  pure subroutine compute_velocity (density, momentum, velocity)
    real, intent(in) :: density
    type(Float3), intent(in) :: momentum
    type(Float3), intent(inout) :: velocity

    velocity%x = momentum%x / density
    velocity%y = momentum%y / density
    velocity%z = momentum%z / density

  end subroutine compute_velocity

  pure function compute_speed_sqd (velocity) result (v2)
    type(Float3), intent(in) :: velocity
    real :: v2

    v2 = (velocity%x * velocity%x) + &
         (velocity%y * velocity%y) + &
         (velocity%z * velocity%z)
  end function compute_speed_sqd

  pure function compute_pressure(density, density_energy, speed_sqd) result (p)
    real, intent(in) :: density, density_energy, speed_sqd
    real :: p

    p = (GAMMA - 1.0) * (density_energy - (0.5 * density * speed_sqd))
  end function compute_pressure

  pure function compute_speed_of_sound(density, pressure) result(c)
    real, intent(in) :: density, pressure
    real :: c

    c = SQRT(GAMMA * pressure / density)
  end function compute_speed_of_sound

  !NOTE: need to check all my procedures to see if stuff is really inout and not simly out
  pure subroutine compute_step_factor(nelr, variables, areas, step_factors)
    integer, intent(in) :: nelr
    real, dimension(:,:), intent(in) :: variables
    real, dimension(:), intent(in) :: areas
    real, dimension(:), intent(inout) :: step_factors
    integer :: blk, b_start, b_end, i
    real :: density, density_energy, speed_sqd, pressure, speed_of_sound
    type(Float3) :: momentum, velocity
    
    DO CONCURRENT (blk = 1:nelr/block_length)
       b_start = blk * block_length
       if (((blk+1) * block_length) > nelr) then
          b_end = nelr
       else
          b_end = (blk+1) * block_length
       end if

       !NOTE: fix this to work with 2D array properly?
       DO i = b_start, b_end
          density = variables(i, VAR_DENSITY)

          momentum%x = variables(i, VAR_MOMENTUM)
          momentum%y = variables(i, VAR_MOMENTUM+1)
          momentum%z = variables(i, VAR_MOMENTUM+2)

          density_energy = variables(i, VAR_DENSITY_ENERGY)
          call compute_velocity(density, momentum, velocity)
          speed_sqd = compute_speed_sqd(velocity)
          pressure = compute_pressure(density, density_energy, speed_sqd)
          speed_of_sound = compute_speed_of_sound(density, pressure)

          ! dt = 0.5 * sqrt(areas(i() / (||v|| + c).... but
          ! when we do time stepping, this later would need to be divided
          ! by the area, so we just do it all at once
          step_factors(i) = 0.5 / &
               ((sqrt(areas(i)) * (sqrt(speed_sqd)) + speed_of_sound))
       end DO
    end DO !concurrent
  end subroutine compute_step_factor

  pure subroutine increment(a, b)
    real, intent(inout) :: a
    real, intent(in) :: b
    a = a + b
  end subroutine increment

  pure subroutine increment_real8(a, b)
    real(8), intent(inout) :: a
    real(8), intent(in) :: b
    a = a + b
  end subroutine increment_real8

  pure subroutine compute_flux(nelr, elements_surrounding_elements, normals, &
       variables, fluxes, ff_variable, ff_flux_contribution_momentum_x, &
       ff_flux_contribution_momentum_y, ff_flux_contribution_momentum_z, &
       ff_flux_contribution_density_energy)
    integer, intent(in) :: nelr
    integer, dimension(:,:), intent(in) :: elements_surrounding_elements
    real, dimension(:,:,:), intent(in) :: normals
    real, dimension(:,:), intent(in) :: variables
    real, dimension(:), intent(in) :: ff_variable
    real, dimension(:,:), intent(inout) :: fluxes
    type(Float3), intent(in) :: ff_flux_contribution_momentum_x
    type(Float3), intent(in) :: ff_flux_contribution_momentum_y
    type(Float3), intent(in) :: ff_flux_contribution_momentum_z
    type(Float3), intent(in) :: ff_flux_contribution_density_energy

    real :: smoothing_coefficient
    real :: density_i, density_energy_i, speed_sqd_i, speed_i
    real :: pressure_i, speed_of_sound_i
    real :: flux_i_density, flux_i_density_energy
    real :: density_nb, density_energy_nb, speed_sqd_nb
    real :: speed_of_sound_nb, pressure_nb
    real :: normal_len, factor
    
    integer :: blk, b_start, b_end
    integer :: i, j, nb

    type(Float3) :: momentum_i, velocity_i
    type(Float3) :: flux_contribution_i_momentum_x
    type(Float3) :: flux_contribution_i_momentum_y
    type(Float3) :: flux_contribution_i_momentum_z
    type(Float3) :: flux_contribution_i_density_energy
    type(Float3) :: flux_i_momentum
    type(Float3) :: velocity_nb, momentum_nb
    type(Float3) :: flux_contribution_nb_momentum_x
    type(Float3) :: flux_contribution_nb_momentum_y
    type(Float3) :: flux_contribution_nb_momentum_z
    type(Float3) :: flux_contribution_nb_density_energy
    type(Float3) :: normal

    smoothing_coefficient = 0.2
    DO CONCURRENT (blk = 1:nelr/block_length)
       b_start = blk * block_length
       if (((blk+1) * block_length) > nelr) then
          b_end = nelr
       else
          b_end = (blk+1) * block_length
       end if

       DO i = b_start, b_end
          density_i = variables(i, VAR_DENSITY)
          momentum_i%x = variables(i, VAR_MOMENTUM)
          momentum_i%y = variables(i, VAR_MOMENTUM+1)
          momentum_i%z = variables(i, VAR_MOMENTUM+2)

          density_energy_i = variables(i, VAR_DENSITY_ENERGY)

          call compute_velocity(density_i, momentum_i, velocity_i)
          speed_sqd_i = compute_speed_sqd(velocity_i)
          speed_i = sqrt(speed_sqd_i)
          pressure_i = compute_pressure(density_i, density_energy_i, speed_sqd_i)
          speed_of_sound_i = compute_speed_of_sound(density_i, pressure_i)

          call compute_flux_contribution(density_i, momentum_i, &
               density_energy_i, pressure_i, velocity_i, &
               flux_contribution_i_momentum_x, &
               flux_contribution_i_momentum_y, &
               flux_contribution_i_momentum_z, &
               flux_contribution_i_density_energy)

          flux_i_density = 0.0
          flux_i_momentum%x = 0.0
          flux_i_momentum%y = 0.0
          flux_i_momentum%z = 0.0
          flux_i_density_energy = 0.0

          DO j = 1, NNB
             nb = elements_surrounding_elements(i, j)
             normal%x = normals(i, j, 1)
             normal%y = normals(i, j, 2)
             normal%z = normals(i, j, 3)
             normal_len = sqrt( &
                  (normal%x * normal%x) + &
                  (normal%y * normal%y) + &
                  (normal%z * normal%z))
             
             if (nb >= 0) then ! a legitimate neighbor
                density_nb = variables(nb, VAR_DENSITY)
                momentum_nb%x = variables(nb, VAR_MOMENTUM)
                momentum_nb%y = variables(nb, VAR_MOMENTUM+1)
                momentum_nb%z = variables(nb, VAR_MOMENTUM+2)
                density_energy_nb = variables(nb, VAR_DENSITY_ENERGY)
                call compute_velocity(density_nb, momentum_nb, velocity_nb)
                speed_sqd_nb = compute_speed_sqd(velocity_nb)
                pressure_nb = compute_pressure(density_nb, density_energy_nb, &
                     speed_sqd_nb)
                speed_of_sound_nb = compute_speed_of_sound(density_nb, &
                     pressure_nb)
                call compute_flux_contribution(density_nb, momentum_nb, &
                     density_energy_nb, pressure_nb, velocity_nb, &
                     flux_contribution_nb_momentum_x, &
                     flux_contribution_nb_momentum_y, &
                     flux_contribution_nb_momentum_z, &
                     flux_contribution_nb_density_energy)

                ! artificial viscosity
                factor = -normal_len * smoothing_coefficient * 0.5 &
                     * (speed_i + sqrt(speed_sqd_nb) + speed_of_sound_i + &
                     speed_of_sound_nb)
                call increment(flux_i_density, factor*(density_i-density_nb))
                call increment(flux_i_density_energy, &
                     factor*(density_energy_i-density_energy_nb))
                call increment(flux_i_momentum%x, &
                     factor*(momentum_i%x-momentum_nb%x))
                call increment(flux_i_momentum%y, &
                     factor*(momentum_i%y-momentum_nb%y))
                call increment(flux_i_momentum%z, &
                     factor*(momentum_i%z-momentum_nb%z))

                ! accumulate cell-centered fluxes
                factor = 0.5 * normal%x
                call increment(flux_i_density, &
                     factor*(momentum_nb%x+momentum_i%x))
                call increment(flux_i_density_energy, &
                     factor*(flux_contribution_nb_density_energy%x + &
                     flux_contribution_i_density_energy%x))
                call increment(flux_i_momentum%x, &
                     factor*(flux_contribution_nb_momentum_x%x + &
                     flux_contribution_i_momentum_x%x))
                call increment(flux_i_momentum%y, &
                     factor*(flux_contribution_nb_momentum_y%x + &
                     flux_contribution_i_momentum_y%x))
                call increment(flux_i_momentum%z, &
                     factor*(flux_contribution_nb_momentum_z%x + &
                     flux_contribution_i_momentum_z%x))

                factor = 0.5 * normal%y
                call increment(flux_i_density, &
                     factor*(momentum_nb%y+momentum_i%y))
                call increment(flux_i_density_energy, &
                     factor*(flux_contribution_nb_density_energy%y + &
                     flux_contribution_i_density_energy%y))
                call increment(flux_i_momentum%x, &
                     factor*(flux_contribution_nb_momentum_x%y + &
                     flux_contribution_i_momentum_x%y))
                call increment(flux_i_momentum%y, &
                     factor*(flux_contribution_nb_momentum_y%y + &
                     flux_contribution_i_momentum_y%y))
                call increment(flux_i_momentum%z, &
                     factor*(flux_contribution_nb_momentum_z%y + &
                     flux_contribution_i_momentum_z%y))

                factor = 0.5 * normal%z
                call increment(flux_i_density, &
                     factor*(momentum_nb%z+momentum_i%z))
                call increment(flux_i_density_energy, &
                     factor*(flux_contribution_nb_density_energy%z + &
                     flux_contribution_i_density_energy%z))
                call increment(flux_i_momentum%x, &
                     factor*(flux_contribution_nb_momentum_x%z + &
                     flux_contribution_i_momentum_x%z))
                call increment(flux_i_momentum%y, &
                     factor*(flux_contribution_nb_momentum_y%z + &
                     flux_contribution_i_momentum_y%z))
                call increment(flux_i_momentum%z, &
                     factor*(flux_contribution_nb_momentum_z%z + &
                     flux_contribution_i_momentum_z%z))
                
             elseif(nb == -1) then ! a wing boundary
                call increment(flux_i_momentum%x, normal%x * pressure_i)
                call increment(flux_i_momentum%y, normal%y * pressure_i)
                call increment(flux_i_momentum%z, normal%z * pressure_i)
                
             elseif(nb == -2) then ! a far field boundary
                factor = 0.5 * normal%x
                call increment(flux_i_density, &
                     factor * (ff_variable(VAR_MOMENTUM) + momentum_i%x))
                call increment(flux_i_density_energy, &
                     factor*(ff_flux_contribution_density_energy%x + &
                     flux_contribution_i_density_energy%x))
                call increment(flux_i_momentum%x, &
                     factor*(ff_flux_contribution_momentum_x%x + &
                     flux_contribution_i_momentum_x%x))
                call increment(flux_i_momentum%y, &
                     factor*(ff_flux_contribution_momentum_y%x + &
                     flux_contribution_i_momentum_y%x))
                call increment(flux_i_momentum%z, &
                     factor*(ff_flux_contribution_momentum_z%x + &
                     flux_contribution_i_momentum_z%x))
                
                factor = 0.5 * normal%y
                call increment(flux_i_density, &
                     factor*(ff_variable(VAR_MOMENTUM + 1) + momentum_i%y))
                call increment(flux_i_density_energy, &
                     factor*(ff_flux_contribution_density_energy%y + &
                     flux_contribution_i_density_energy%y))
                call increment(flux_i_momentum%x, &
                     factor*(ff_flux_contribution_momentum_x%y + &
                     flux_contribution_i_momentum_x%y))
                call increment(flux_i_momentum%y, &
                     factor*(ff_flux_contribution_momentum_y%y + &
                     flux_contribution_i_momentum_y%y))
                call increment(flux_i_momentum%z, &
                     factor*(ff_flux_contribution_momentum_z%y + &
                     flux_contribution_i_momentum_z%y))

                factor = 0.5 * normal%z
                call increment(flux_i_density, &
                     factor*(ff_variable(VAR_MOMENTUM+2)+momentum_i%z))
                call increment(flux_i_density_energy, &
                     factor*(ff_flux_contribution_density_energy%z + &
                     flux_contribution_i_density_energy%z))
                call increment(flux_i_momentum%x, &
                     factor*(ff_flux_contribution_momentum_x%z + &
                     flux_contribution_i_momentum_x%z))
                call increment(flux_i_momentum%y, &
                     factor*(ff_flux_contribution_momentum_y%z + &
                     flux_contribution_i_momentum_y%z))
                call increment(flux_i_momentum%z, &
                     factor*(ff_flux_contribution_momentum_z%z + &
                     flux_contribution_i_momentum_z%z))
             end if
          end DO
          
          fluxes(i, VAR_DENSITY) = flux_i_density
          fluxes(i, VAR_MOMENTUM) = flux_i_momentum%x
          fluxes(i, VAR_MOMENTUM+1) = flux_i_momentum%y
          fluxes(i, VAR_MOMENTUM+2) = flux_i_momentum%z
          fluxes(i, VAR_DENSITY_ENERGY) = flux_i_density_energy
          
       end DO
    end DO
  end subroutine compute_flux

  pure subroutine time_step(j, nelr, old_variables, variables, &
       step_factors, fluxes)
    integer, intent(in) :: j, nelr
    real, dimension(:), intent(in) :: step_factors
    real, dimension(:,:), intent(in) :: old_variables, fluxes
    real, dimension(:,:), intent(inout) :: variables
    integer :: blk, b_start, b_end, i, denom
    real :: factor

    DO CONCURRENT (blk = 1:nelr/block_length)
       b_start = blk * block_length
       if (((blk+1) * block_length) > nelr) then
          b_end = nelr
       else
          b_end = (blk+1) * block_length
       end if

       DO i = b_start, b_end
          denom = RK +1 -j
          factor = step_factors(i) / real (denom)
          variables(i, VAR_DENSITY) = old_variables(i, VAR_DENSITY) + &
               factor*fluxes(i, VAR_DENSITY)
          variables(i, VAR_MOMENTUM) = old_variables(i, VAR_MOMENTUM) + &
               factor*fluxes(i, VAR_MOMENTUM)
          variables(i, VAR_MOMENTUM+1) = old_variables(i, VAR_MOMENTUM+1) + &
               factor*fluxes(i, VAR_MOMENTUM+1)
          variables(i, VAR_MOMENTUM+2) = old_variables(i, VAR_MOMENTUM+2) + &
               factor*fluxes(i, VAR_MOMENTUM+2)
          variables(i, VAR_DENSITY_ENERGY) = &
               old_variables(i, VAR_DENSITY_ENERGY) + &
               factor*fluxes(i, VAR_DENSITY_ENERGY)
       end DO
    end DO !concurrent
  end subroutine time_step
  
end program euler3d
