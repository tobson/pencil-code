! ! $Id: cdata.f90,v 1.293 2006-03-17 23:08:44 wlyra Exp $

module Cdata

!!! Global variables

  use Cparam
  public 

  integer :: itorder=3
  real, dimension (mx) :: x,dx_1,dx_tilde
  real, dimension (my) :: y,dy_1,dy_tilde
  real, dimension (mz) :: z,dz_1,dz_tilde
  real, dimension (nx) :: dxyz_2, dxyz_4, dxyz_6
  real, dimension (nrcyl) :: rcyl  ! used for phi-averages
  real, dimension (nx) :: x_mn,y_mn,z_mn,r_mn,rcyl_mn,phi_mn
  real, dimension (nx,3) :: evr    ! spherical unit radius vector
  real, dimension (nx) :: maxdss,maxdlnrho

!  coordinate system (alternatives: spherical, cylindric)
  character (len=9) :: coord_system='cartesian'
  logical :: lspherical=.false.,lcylindric=.false.
  real, dimension (nx) :: r1_mn

!  timestep related:
  real, dimension (nx) :: advec_uu,advec_shear,advec_hall
  real, dimension (nx) :: advec_cs2,advec_va2,advec_uud
  real, dimension (nx) :: diffus_pscalar
  real, dimension (nx) :: diffus_chiral,diffus_diffrho,diffus_cr,diffus_nud
  real, dimension (nx) :: diffus_eta,diffus_nu,diffus_chi,diffus_diffnd
  real, dimension (nx) :: dt1_advec,dt1_diffus,dt1_max

  real, parameter :: pi=3.14159265358979324D0
  real, parameter :: epsi=5*epsilon(1.0),tini=5*tiny(1.0),huge1=0.2*huge(1.0)
  real, dimension(3) :: Lxyz,xyz0,xyz1=impossible,xyz_star=(/0.0,0.0,0.0/)
  real, dimension(3) :: Lxyz_loc,xyz0_loc,xyz1_loc
  real :: t,dt=0.
  real :: dt1_last=0.
  real, dimension (3) :: alpha=0.0,beta=0.0,dt_beta=1.0

  real :: cdt=0.4,cdtv=0.25,cdts=1.0,cdtr=1.0
  real :: cdtvDim
  real :: ddt=0.


  real :: dx,dy,dz,dxmin,dxmax,drcyl,dsurfxy,dsurfyz,dsurfzx,dvol
  real :: dsnap=100.,d2davg=100.,dvid=0.,dtmin=1.e-6,dtmax=1E37,dspec=impossible
  real :: r_int=0.,r_ext=impossible   ! for spherical shell problems
  real :: r_ref=0.
  
!  parameter for freezing
  real :: rfreeze_int=-impossible,rfreeze_ext=-impossible
  real :: wfreeze_int=0.,wfreeze_ext=0.
  real :: fshift_int=-1.,fshift_ext=1.

  real :: ttransient=0.,C_smag=0.17
  real, dimension (2) :: fran1,fran2

  real, dimension(3) :: border_frac=0.0
  real, dimension(2) :: border_frac_x=0.0,border_frac_y=0.0,border_frac_z=0.0

  !  units (need to be in double precision)
  character (len=3) :: unit_system='cgs'
  double precision :: unit_length=1.,unit_velocity=1.,unit_density=1.,unit_temperature=1.
  ! Derived units
  double precision :: unit_mass,unit_energy,unit_time,unit_flux
  
  double precision :: k_B,m_p,m_e,m_H,m_He,eV,hbar, &
                      chiH,chiH_,sigmaH_,sigmaSB,kappa_es

  ! magnetic permeability
  real :: mu0=1., mu01=0.

!ajwm nu moved to viscosity module
!ajwm replaced nu, causes error in forcing to resolve
  real :: nu=0.,cmu,cnu2
!ajwm moved here from hydro to remove dependence of entropy on Hydro
  real :: nu_turb=0.
  real :: tdiagnos,t2davgfirst

!! not used?  real :: rmean,rrms,rmax,u2m,um2,u2max,divurms,divumax,divu2max
  real :: o2m,om2,oum,epsK_hyper
  real :: UUmax=0.
  real :: x0,y0,z0,Lx,Ly,Lz
  real :: grads0=0.   ! (1/c_p)ds/dz
  real :: Omega=0.,qshear=0.,Sshear=impossible
  real :: deltay=0. !(for shear; also used in forcing and output)
  real, dimension(3,1) :: coeff_grid=1.0
  real, dimension(3,2) :: xyz_step,xi_step_frac,xi_step_width=1.5
  real :: zeta_grid0=0.

  integer, dimension(mseed) :: seed=0

  integer :: nseed=0
  integer :: nvar,naux,naux_com
  integer :: iuu=0,iux=0,iuy=0,iuz=0,ilnrho=0,iss=0
  integer :: igg=0,igx=0,igy=0,igz=0
  integer :: iaa=0,iax=0,iay=0,iaz=0
  integer :: ifcr=0,ifcrx=0,ifcry=0,ifcrz=0
  integer :: iaatest=0,iaxtest=0,iaytest=0,iaztest=0
  integer :: ie=0,iff=0,ifx=0,ify=0,ifz=0,idd=0,ishock=0,iyH=0,ihyper=0
  integer :: iecr=0,ismagorinsky
  integer :: iQrad=0,iSrad=0,ikappa=0,ilnTT=0
  integer :: nt=1000000,it1=10
  integer :: it=1,itsub,ix=-1,iy=-1,iz=-1,iz2=-1
  integer :: ilncc=0,ialpm=0
  integer :: iXX_chiral=0,iYY_chiral=0
  integer :: iproc,ipx,ipy,ipz,root=0
  integer :: mvar_io=0,dimensionality
  integer :: iinit
  integer, dimension(ndustspec) :: iuud=0,iudx=0,iudy=0,iudz=0,ind=0,imd=0,imi=0
  logical, dimension(3) :: lperi,lshift_origin
  logical, dimension(3) :: lequidist=(/.true.,.true.,.true. /)
  character (len=labellen), dimension(3) :: grid_func='linear'
  character (len=labellen) ::fft_switch='fftpack'
  character (len=1) :: slice_position='p'
  character (len=40) :: kinflow=''
!
! Variables to count the occurance of derivative calls per timestep
! for optimisation purposes.  To use uncomment the array and
! set optimise_ders=.true.
!
!debug  integer, dimension(mvar+maux,8,3,3) :: der_call_count=0 !DERCOUNT
!debug  logical, parameter :: loptimise_ders=.true.             !DERCOUNT
!
!  coordinates of the point where some quantities can be printed
!  for now, these points only apply to the root processor.
!
  integer :: lpoint=(l1+l2)/2,mpoint=(m1+m2)/2,npoint=(n1+n2)/2
!
!  pencil-related stuff (also MPI-related stuff)
!
  integer :: imn,m,n
  integer, dimension (ny*nz) :: mm,nn
  logical, dimension (ny*nz) :: necessary=.false.
  logical :: lprocz_slowest=.true.
!
!  in this section are all the things related to printing
!
  integer :: nname=0,nnamev=0,nnamexy=0,nnamexz=0,nnamerz=0
  integer :: nnamez=0,nnamey=0,nnamex=0
  integer :: nr_directions=1
  integer, parameter :: mname=100,mnamev=100,mnamerz=20
  integer, parameter :: mnamez=30,mnamey=30,mnamex=30
  integer, parameter :: mnamexy=6,mnamexz=40
  integer, dimension (mname) :: itype_name
  real, dimension (mname) :: fname
  real, dimension (nz,nprocz,mnamez) :: fnamez
  real, dimension (ny,nprocy,mnamey) :: fnamey
  real, dimension (nx,mnamex) :: fnamex
  real, dimension (nx,ny,nprocy,mnamexy) :: fnamexy
  real, dimension (nx,nz,nprocz,mnamexz) :: fnamexz
  real, dimension (nrcyl,0:nz,nprocz,mnamerz) :: fnamerz
  real, dimension (nrcyl,nx) :: phiavg_profile
  real, dimension (nx) :: pomx,pomy,phix,phiy
  character (LEN=30) :: cname(mname),cform(mname)
  character (LEN=30) :: cnamev(mname)
  character (LEN=30) :: cnamexy(mnamexy),cformxy(mnamexy)
  character (LEN=30) :: cnamexz(mnamexz),cformxz(mnamexz)
  character (LEN=30) :: cnamez(mnamez),cformz(mnamez)
  character (LEN=30) :: cnamey(mnamey),cformy(mnamey)
  character (LEN=30) :: cnamex(mnamex),cformx(mnamex)
  character (LEN=30) :: cnamerz(mnamerz),cformrz(mnamerz)

  ! other variables (needs to be consistent with reset list in register.90)
  integer :: idiag_t=0,idiag_it=0,idiag_dt=0
  integer :: idiag_walltime=0,idiag_timeperstep=0
  integer :: idiag_rcylmphi=0,idiag_phimphi=0,idiag_zmphi=0,idiag_rmphi=0
  integer :: idiag_nu_LES=0

  !  initialization of various switches; actual settings depends on the
  !  modules that are linked in (see Makefile.local) and can, in some cases,
  !  be reset also via appropriate namelist entries.

  logical :: lstart=.false., lrun=.false.
!
!
! Module flags
!
  logical :: ldensity_nolog=.false.
  logical :: ltestfield=.false.
  logical :: lmpicomm=.false., lforcing=.false., lpostproc=.false.
  logical :: lmaxadvec_sum=.false.,old_cdtv=.false.
  logical :: lwrite_slices=.false., lwrite_2daverages=.false.
  logical :: lwrite_slice_xy2,lwrite_slice_xy,lwrite_slice_xz,lwrite_slice_yz
  ! backwards compatible (not needed with gravity_simple.f90):
  logical :: lgravx=.false.,lgravy=.false.,lgravz=.false.
  !
  logical :: lgrav=.false.,lgravx_gas=.true.,lgravy_gas=.true.,lgravz_gas=.true.
  logical :: lgravx_dust=.true.,lgravy_dust=.true.,lgravz_dust=.true.
  logical :: lgravr=.false.,lgravr_gas=.false.,lgravr_dust=.false.
  logical :: lout=.false.,headt=.false.,headtt=.true.,ldt,lfirst=.false.
  logical :: ldiagnos=.false.,lvid=.false.,lwrite_prof=.true.
  logical :: l2davg=.false.,l2davgfirst=.false.
  logical :: lwrite_yaverages=.true.,lwrite_zaverages=.true.,lwrite_phiaverages=.true.
  logical :: lwrite_ic=.false.,lnowrite=.false.,lserial_io=.false.
  logical :: lroot=.true.,ldebug=.false.,lfft=.true.
  logical :: lshear=.false.,lpscalar=.false.,lpscalar_nolog=.false.
  logical :: lalpm=.false.
  logical :: lchiral=.false.
  logical :: lradiation=.false.,lradiation_ray=.false.,lradiation_fld=.false.
  logical :: ldustdensity=.false.,ldustdensity_log=.false.
  logical :: ldustvelocity=.false.
  logical :: lglobal=.false., lglobal_nolog_density=.false.
  logical :: lvisc_hyper=.false.,lvisc_LES=.false.
  logical :: lvisc_smagorinsky=.false.
  logical :: lselfgravity=.false.
  logical :: lmonolithic_io=.false.
  logical :: lrescaling=.false.
  logical :: leos=.false., leos_idealgas=.false.
  logical :: leos_ionization=.false.,leos_fixed_ionization=.false.
  logical :: pretend_lnTT=.false.
  logical :: save_lastsnap=.true.
  logical :: lcopysnapshots_exp=.false.
  logical :: lcylindrical=.false.

!!
!! The following have been replaces with CPARAM header definitions making them
!! parameters (ajwm)
!!
!!  logical :: lhydro=.false.,ldensity=.false.,lentropy=.false.
!!  logical :: lcosmicrayflux=.false.
!!  logical :: lcosmicray=.false.
!!  logical :: lmagnetic=.false.
!!  logical :: linterstellar=.false.
!!
!!

! Constant 'parameters' cannot occur in namelists, so inorder to get the now constant module
! logicals into the lphysics name list... We have some proxies that are used to initialise
! private local variables called lhydro etc, in the lphysics namelist!
  logical, parameter :: lhydro_var=lhydro
  logical, parameter :: ldensity_var=ldensity
  logical, parameter :: lentropy_var=lentropy
  logical, parameter :: lshock_var=lshock
  logical, parameter :: lmagnetic_var=lmagnetic
  logical, parameter :: linterstellar_var=linterstellar
  logical, parameter :: lcosmicray_var=lcosmicray
  logical, parameter :: lcosmicrayflux_var=lcosmicrayflux
  logical, parameter :: lplanet_var=lplanet

  logical :: lfirstpoint=.false.,llastpoint=.false.
  logical :: vel_spec=.false.,mag_spec=.false.,uxj_spec=.false.,vec_spec=.false.
  logical :: ro_spec=.false.,ss_spec=.false.,cc_spec=.false.,cr_spec=.false.
  logical :: ab_spec=.false.,ou_spec=.false.,oned=.false.,twod=.false.
  logical :: rhocc_pdf=.false.,cc_pdf=.false.,lncc_pdf=.false.
  logical :: gcc_pdf=.false.,lngcc_pdf=.false.
  logical :: test_nonblocking=.false.,onedall=.false.
  logical :: lsfu=.false.,lsfb=.false.,lsfz1=.false.,lsfz2=.false.
  logical :: lsfflux=.false.
  logical :: lpdfu=.false.,lpdfb=.false.,lpdfz1=.false.,lpdfz2=.false.
!  logical, dimension(mvar + maux) :: lsnap ! flag which variables should be written
                                             ! to the snapshots
  logical :: lfrozen_bcs_z=.false.
  logical, dimension(mcom) :: lfrozen_bot_var_z=.false.,lfrozen_top_var_z=.false.
  logical, dimension(mcom) :: lfreeze_varint=.false.,lfreeze_varext=.false.

  ! possibility to set boundary values
  real, dimension(mcom) :: fbcx1=0.,fbcy1=0.,fbcz1=0., fbcz1_1=0., fbcz1_2=0.
  real, dimension(mcom) :: fbcx2=0.,fbcy2=0.,fbcz2=0., fbcz2_1=0., fbcz2_2=0.

  character (len=2*bclen+1), dimension(mcom) :: bcx='p',bcy='p',bcz='p'
  character (len=bclen), dimension(mcom) :: bcx1,bcx2,bcy1,bcy2,bcz1,bcz2
  character (len=10), dimension(mvar+maux) :: varname
  character (len=labellen) :: force_lower_bound='',force_upper_bound=''
  character (len=120) :: datadir='data' ! default; may be overwritten in
                                        ! Register.initialize()
  character (len=120) :: directory='',datadir_snap='',directory_snap=''
  character (len=120) :: cvsid='[No CVS Id given]'

! Natalia (NS)
 
  real :: H_disk=0.
  real :: L_disk=0.
  real :: R_star=0.
  real :: M_star=0. 
  real :: accretion_flux=0.
  logical :: lextrapolate_bot_density=.false.
  logical :: ltop_velocity_kep=.false.
  logical :: laccelerat_zone=.false.

! A buffer in which to construct an error message
  character (len=255) :: errormsg

  character (len=10), dimension(maux) :: aux_var
  integer :: aux_count=1

  ! run parameters
  real :: tmax=1e33,awig=1.
  real :: max_walltime=0.0  ! in seconds
  integer :: isave=100,iwig=0,ialive=0,nfilter=0,isaveglobal=0
  logical :: lrmwig_rho=.false.,lrmwig_full=.false.,lrmwig_xyaverage=.false.
  logical :: lread_oldsnap=.false., lread_oldsnap_nomag=.false., lread_oldsnap_nopscalar=.false.
  logical :: lwrite_aux=.false., lsgifix=.false.

  integer :: init_loops=1, ipencil_swap=0
  logical :: lpencil_requested_swap=.true., lpencil_diagnos_swap=.false.
  logical :: lreinit=.false.
  logical :: lpencil_check=.false., lpencil_init=.false.
  logical :: lpencil_check_diagnos_opti=.false.
  integer :: nreinit=0
  character (len=5), dimension(10) :: reinit_vars=''
  real :: b_ell=1., rbound=1.

endmodule Cdata
