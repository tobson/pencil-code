! $Id: poisson.f90,v 1.11 2006-07-28 11:49:12 ajohan Exp $

!
!  This module solves the Poisson equation
!    (d^2/dx^2 + d^2/dy^2 + d^2/dz^2)f = rhs(x,y,z)
!  for the function f(x,y,z).
!

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lpoisson=.true.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
!***************************************************************

module Poisson

  use Cdata
  use Cparam
  use General_FFT
  use Messages

  implicit none

  include 'poisson.h'

  contains

!***********************************************************************
    subroutine poisson_solver_fft(a1,lklimit,kmax)
!
!  Solve the Poisson equation by Fourier transforming on a periodic grid.
!  This method works both with and without shear.
!
!  15-may-2006/anders+jeff: coded
!
      real, dimension (nx,ny,nz) :: a1
!
      real, dimension (nx,ny,nz) :: b1
      real :: kmax
      logical :: lklimit
      integer :: i, ikx, iky, ikz
!
!  identify version
!
      if (lroot .and. ip<10) call cvs_id( &
        "$Id: poisson.f90,v 1.11 2006-07-28 11:49:12 ajohan Exp $")
!
!  The right-hand-side of the Poisson equation is purely real.
!
      b1 = 0.0
!  forward transform (to k-space)
      if (lshear) then
        call transform_fftpack_shear(a1,b1,1)
      else
        call transform_fftpack(a1,b1,1)
      endif
!
!  FT(phi) = -rhs_poisson_const*FT(rho)/k^2
!
      do ikz=1,nz; do iky=1,ny; do ikx=1,nx
        if ((kx_fft(ikx)==0.0) .and. &
            (ky_fft(iky)==0.0) .and. (kz_fft(ikz)==0.0) ) then
          a1(ikx,iky,ikz) = 0.
          b1(ikx,iky,ikz) = 0.
        else
          if (lshear) then
!
!  Take into account that the Fourier transform has been done in shearing
!  coordinates, and that the kx of each Fourier mode is different in the normal
!  frame. The connection between kx0 (in the shearing frame) and the actual kx
!  is
!    kx = kx0 + qshear*Omega*t*ky
!  Writing deltay/2 = qshear*Omega*Lx/2*t, one gets the expression
!    kx = kx0 + deltay/Lx*ky
!  The parallel Fourier transform returns the array in a tranposed state, so
!  must be able to identify the x-direction in order to take shear into account.
!  (see the subroutine transform_fftpack_shear in Mpicomm for details).
!
            if (nzgrid/=1) then ! Order (kz,ky',kx)
              a1(ikx,iky,ikz) = -a1(ikx,iky,ikz) / &
                  ( (kx_fft(ikz+ipz*nz)+deltay/Lx*ky_fft(iky+ipy*ny))**2 + &
                     ky_fft(iky+ipy*ny)**2 + kz_fft(ikx)**2 )
              b1(ikx,iky,ikz) = -b1(ikx,iky,ikz) / &
                  ( (kx_fft(ikz+ipz*nz)+deltay/Lx*ky_fft(iky+ipy*ny))**2 + &
                      ky_fft(iky+ipy*ny)**2 + kz_fft(ikx)**2)
            else                            ! Order (kx,ky',kz)
              a1(ikx,iky,ikz) = -a1(ikx,iky,ikz) / &
                  ( (kx_fft(ikx)+deltay/Lx*ky_fft(iky+ipy*ny))**2 + &
                     ky_fft(iky+ipy*ny)**2 + kz_fft(ikz+ipz*nz)**2 )
              b1(ikx,iky,ikz) = -b1(ikx,iky,ikz) / &
                  ( (kx_fft(ikx)+deltay/Lx*ky_fft(iky+ipy*ny))**2 + &
                     ky_fft(iky+ipy*ny)**2 + kz_fft(ikz+ipz*nz)**2 )
            endif
!
!  Limit |k| < kmax
            if (lklimit) then
              if (sqrt(kx_fft(ikx)**2  + ky_fft(iky)**2 + kz_fft(ikz)**2) >= kmax) then
                a1(ikx,iky,ikz) = 0.
                b1(ikx,iky,ikz) = 0.
              endif
            endif

          else ! The order of the array is not important here, because no shear!
            a1(ikx,iky,ikz) = -a1(ikx,iky,ikz) / &
                (kx_fft(ikx)**2 + ky_fft(iky+ipy*ny)**2 + kz_fft(ikz+ipz*nz)**2)
            b1(ikx,iky,ikz) = -b1(ikx,iky,ikz) / &
                (kx_fft(ikx)**2 + ky_fft(iky+ipy*ny)**2 + kz_fft(ikz+ipz*nz)**2)
          endif
        endif
      enddo; enddo; enddo
!  inverse transform (to real space)
      if (lshear) then
        call transform_fftpack_shear(a1,b1,-1)
      else
        call transform_fftpack(a1,b1,-1)
      endif
!
    endsubroutine poisson_solver_fft
!***********************************************************************

endmodule Poisson

