!  $Id: nofftpack.f,v 1.4 2003-08-15 12:04:54 brandenb Exp $
!
!  Dummy routine, to avoid never seeing the compiler warnings from fftpack.
!
!***********************************************************************
      SUBROUTINE CFFTF (N,C,WSAVE)
      DIMENSION C(*),WSAVE(*)
      save iprint
!
!  Dummy routine: put c=0 to prevent further damage
!
      if(iprint.eq.0) print*,'Use FFTPACK=fftpack; ',n,c(1),wsave(1)
      do i=1,n
        c(i)=0.
      enddo
      iprint=1
      END
!***********************************************************************
      SUBROUTINE CFFTI (N,WSAVE)
      DIMENSION WSAVE(*)
      save iprint
!
!  Dummy routine: put c=0 to prevent further damage
!
      do i=1,4*n+15
        wsave(i)=0.
      enddo
      if(iprint.eq.0) print*,'Use FFTPACK=fftpack; ',n
      iprint=1
      END
!***********************************************************************
      SUBROUTINE CFFTB (N,C,WSAVE)
      DIMENSION C(*), WSAVE(*)
      save iprint
!
!  Dummy routine: put c=0 to prevent further damage
!
      do i=1,4*n+15
        wsave(i)=0.
      enddo
      if(iprint.eq.0) print*,'Use FFTPACK=fftpack; ',n,c(1),wsave(1)
      iprint=1
      END
!***********************************************************************
      SUBROUTINE COSQB (N,X,WSAVE)
      DIMENSION X(*),WSAVE(*)
      END
!***********************************************************************
      SUBROUTINE COSQF (N,X,WSAVE)
      DIMENSION X(*),WSAVE(*)
      END
!***********************************************************************
      SUBROUTINE COSQI (N,WSAVE)
      DIMENSION WSAVE(*)
      END
!***********************************************************************
