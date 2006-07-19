! $Id: shared_variables.f90,v 1.1 2006-07-19 15:22:19 mee Exp $ 
!
!  This module make an interface available to allow modules
!  to register pointers to their internal variables so that
!  other modules my then request them by name.
!
!  This uses a linked list of pointer and is neither efficient
!  nor easy to use.  THIS IS ON PURPOSE!
!
!  Shared variable should always be avoided for portability 
!  and generality reasons.  This module simply trys to protect 
!  against accidental screw ups.
!
!  When used modules should call the get and put routines
!  at initialize_ time for optimal performance.
!
!  Variables to be added to the list must have the target property
!  And a pointer mut be provided when getting a variable from
!  the list. 
!
!
module SharedVariables 
!
  implicit none
!
!
  private
!
  public :: initialize_shared_variables
  public :: put_shared_variable
  public :: get_shared_variable
!
  interface get_shared_variable
    module procedure get_variable_real0d
    module procedure get_variable_real1d
    module procedure get_variable_int0d
    module procedure get_variable_int1d
    module procedure get_variable_char
  endinterface get_shared_variable
!
  interface put_shared_variable
    module procedure put_variable_real0d
    module procedure put_variable_real1d
    module procedure put_variable_int0d
    module procedure put_variable_int1d
    module procedure put_variable_char
  endinterface put_shared_variable
!
! Used internally to keep track ot the type of data
! stored in the shared variables list.
!
  integer, parameter :: iSHVAR_TYPE_REAL0D=1
  integer, parameter :: iSHVAR_TYPE_REAL1D=2
  integer, parameter :: iSHVAR_TYPE_REAL2D=3
  integer, parameter :: iSHVAR_TYPE_INT0D=10
  integer, parameter :: iSHVAR_TYPE_INT1D=11
  integer, parameter :: iSHVAR_TYPE_INT2D=12
  integer, parameter :: iSHVAR_TYPE_CHAR0D=20
!
! Some possible error codes when getting a variable
! (if the user doesn't even ask for the error code
!  they get a fatal_error)
!
  integer, public, parameter :: iSHVAR_ERR_NOSUCHVAR=1
  integer, public, parameter :: iSHVAR_ERR_WRONGTYPE=2
!
! Store pointers to variables in a general linked
! list structure.  Shame we can't have (void *) pointers.
!
  type shared_variable_list
    character (len=30) :: varname
    integer :: vartype
    real, pointer :: real0d
    real, pointer :: real1d
    real, pointer :: int0d
    real, pointer :: int1d
    character (len=*), pointer :: char0D
    type (shared_variable_list) :: next
  endtype
!
! The head of the list (initially empty)
!
  type (shared_variable_list) :: thelist
 
  contains

!***********************************************************************
    subroutine initialize_shared_variables()
!
      if (lreloading) then
        call free_list(thelist)
      else
        NULLIFY(thelist)
      endif
!
    endsubroutine initialize_shared_variables
!***********************************************************************
    subroutine get_variable_real0d(varname,variable,err) 
      character (len=*) :: varname
      real, pointer :: variable
      type (shared_variable_list), pointer :: item
      integer, optional :: err
!
      item=>thelist
      do while (associated(item))
        if (item%varname==varname) then
          if (item%vartype==iSHVAR_TYPE_REAL0D) then
            variable=>item%real0D
            return
          else
            print*,"Getting shared variable: ",varname
            nullify(variable)
            if (present(err)) then
              err=iSHVAR_ERROR_NOSUCHVAR
              return
            endif
            call fatal_error("get_variable","Shared variable has the wrong type!")
          endif
        endif
        item=>item%next
      enddo
      print*,"Getting shared variable: ",varname
      nullify(variable)
      if (present(err)) then
        err=iSHVAR_ERROR_WRONGTYPE
        return
      endif
      call fatal_error("get_variable","Shared variable does not exist!")
!    
    endsubroutine get_variable_real0d
!***********************************************************************
    subroutine get_variable_real1d(varname,variable,err) 
      character (len=*) :: varname
      real, dimension(:), pointer :: variable
      type (shared_variable_list), pointer :: item
      integer, optional :: err
!
      item=>thelist
      do while (associated(item))
        if (item%varname==varname) then
          if (item%vartype==iSHVAR_TYPE_REAL1D) then
            variable=>item%real1D
          else
            print*,"Getting shared variable: ",varname
            nullify(variable)
            call fatal_error("get_variable","Shared variable has the wrong type!")
          endif
        endif
        item=>item%next
      enddo
      print*,"Getting shared variable: ",varname
      nullify(variable)
      call fatal_error("get_variable","Shared variable does not exist!")
!    
    endsubroutine get_variable_real1d
!***********************************************************************
    subroutine get_variable_int0d(varname,variable,err) 
      character (len=*) :: varname
      integer, pointer :: variable
      type (shared_variable_list), pointer :: item
      integer, optional :: err
!
      item=>thelist
      do while (associated(item))
        if (item%varname==varname) then
          if (item%vartype==iSHVAR_TYPE_INT0D) then
            variable=>item%int0D
            return
          else
            print*,"Getting shared variable: ",varname
            nullify(variable)
            if (present(err)) then
              err=iSHVAR_ERROR_NOSUCHVAR
              return
            endif
            call fatal_error("get_variable","Shared variable has the wrong type!")
          endif
        endif
        item=>item%next
      enddo
      print*,"Getting shared variable: ",varname
      nullify(variable)
      if (present(err)) then
        err=iSHVAR_ERROR_WRONGTYPE
        return
      endif
      call fatal_error("get_variable","Shared variable does not exist!")
!    
    endsubroutine get_variable_int0d
!***********************************************************************
    subroutine get_variable_int1d(varname,variable,err) 
      character (len=*) :: varname
      integer, dimension(:), pointer :: variable
      type (shared_variable_list), pointer :: item
      integer, optional :: err
!
      item=>thelist
      do while (associated(item))
        if (item%varname==varname) then
          if (item%vartype==iSHVAR_TYPE_INT1D) then
            variable=>item%int1D
          else
            print*,"Getting shared variable: ",varname
            nullify(variable)
            call fatal_error("get_variable","Shared variable has the wrong type!")
          endif
        endif
        item=>item%next
      enddo
      print*,"Getting shared variable: ",varname
      nullify(variable)
      call fatal_error("get_variable","Shared variable does not exist!")
!    
    endsubroutine get_variable_int1d
!***********************************************************************
    subroutine put_variable_int0d(varname,variable) 
      character (len=*) :: varname
      integer, target :: variable
      type (shared_variable_list), pointer :: new
!
      call new_item_atstart(thelist,new=new)
      new%varname=varname
      new%vartype=iSHVAR_TYPE_INT0D
      new%int0D=>variable
!    
    endsubroutine put_variable_int0d
!***********************************************************************
    subroutine put_variable_int1d(varname,variable) 
      character (len=*) :: varname
      integer, dimension(:), target :: variable
      type (shared_variable_list), pointer :: new
!
      call new_item_atstart(thelist,new=new)
      new%varname=varname
      new%vartype=iSHVAR_TYPE_INT1D
      new%int1D=>variable
!    
    endsubroutine put_variable_int1d
!***********************************************************************
    subroutine put_variable_real0d(varname,variable) 
      character (len=*) :: varname
      real, target :: variable
      type (shared_variable_list), pointer :: new
!
      call new_item_atstart(thelist,new=new)
      new%varname=varname
      new%vartype=iSHVAR_TYPE_REAL0D
      new%real0D=>variable
!    
    endsubroutine put_variable_real0d
!***********************************************************************
    subroutine put_variable_real1d(varname,variable) 
      character (len=*) :: varname
      real, dimension(:), target :: variable
      type (shared_variable_list), pointer :: new
!
      call new_item_atstart(thelist,new=new)
      new%varname=varname
      new%vartype=iSHVAR_TYPE_REAL1D
      new%real1D=>variable
!    
    endsubroutine put_variable_real1d
!***********************************************************************
    subroutine free_list(list) 
      type (shared_variable_list), pointer :: list
      type (shared_variable_list), pointer :: next
 
      do while (associated(start))
        next=>list%next
        deallocate(list)
        list=>next
      enddo
      nullify(list)
    endsubroutine free_list
!***********************************************************************
    subroutine new_item_atstart(list,new) 
      type (shared_variable_list), pointer :: list
      type (shared_variable_list), optional, pointer :: new
      type (shared_variable_list), pointer :: new_

      allocate(new_)
      new_%next=>list 
      list=>new_
      if (present(new)) new=>new_ 
    endsubroutine new_item_atstart
!***********************************************************************
endmodule SharedVariables
