;
; $Id$
;
;  Reads and displays data in a plane (currently with tvscl) and plots a
;  curve as well (cross-section through iy).
;
;  If the keyword /mpeg is given, the file movie.mpg is written.
;
;  tmin is the time after which data are written.
;
;  nrepeat is the number of repeated images (to slow down movie)
;
;  An alternative is to set the /png_truecolor flag and postprocess the
;  PNG images with ${PENCIL_HOME}/utils/makemovie (requires imagemagick
;  and mencoder to be installed).
;
;  The /polar option is for sphere/cylinder-in-a-box simulations only.
;
;  Typical calling sequence:
;    rvid_plane,'uz',min=-1e-1,max=1e-1,/proc
;
;  ... and for spherical slices
;    rvid_plane,'bb1',min=-.5,max=.5,/sph
;
pro rvid_plane,field,mpeg=mpeg,png=png,truepng=png_truecolor,tmin=tmin, $
    tmax=tmax,max=amax,swap_endian=swap_endian,quiet=quiet, $
    min=amin,extension=extension,nrepeat=nrepeat,wait=wait, $
    stride=stride,datadir=datadir,oldfile=oldfile,debug=debug, $
    proc=proc,ix=ix,iy=iy,ps=ps,iplane=iplane,imgdir=imgdir, $
    global_scaling=global_scaling,automatic_scaling=automatic_scaling, $
    shell=shell,r_int=r_int, $
    r_ext=r_ext,zoom=zoom,colmpeg=colmpeg,exponential=exponential, $
    contourplot=contourplot,color=color,sqroot=sqroot,tunit=tunit, $
    nsmooth=nsmooth, cubic=cubic, textsize=textsize, _extra=_extra, $
    polar=polar, anglecoord=anglecoord, style_polar=style_polar, $
    spherical_surface=spherical_surface, nlevels=nlevels, $
    doublebuffer=doublebuffer,wsx=wsx,wsy=wsy,title=title,log=log, $
    interp=interp,savefile=savefile, rotate=rotate,phi_shift=phi_shift, $
    Beq=Beq,taud=taud
;
common pc_precision, zero, one, precision, data_type, data_bytes, type_idl
;
default,ix,-1
default,iy,-1
default,ps,0
default,quiet,0
;
;  default extension
;
if keyword_set(spherical_surface) then begin
  default,extension,'yz'
endif else begin
  default,extension,'xz'
endelse
;
default,amax,.05
default,amin,-amax
default,swap_endian,0
default,field,'lnrho'
if (not keyword_set(datadir)) then datadir=pc_get_datadir()
default,nrepeat,0
default,stride,0
default,tmin,0.
default,tmax,1e38
default,tunit,1
default,iplane,0
default,wait,.03
default,r_int,0.5
default,r_ext,1.0
default,zoom,1.0
default,dimfile,'dim.dat'
default,varfile,'var.dat'
default,imgdir,'.'
default,color,1
default,pixelsize,1
default,ximg,1
default,yimg,1
default,textsize,1.0
default,anglecoord,'z'
default,style_polar,'fill'
default,wsx,640
default,wsy,480
default,title,'rvid_plane'
default,nlevels,30
default,phi_shift,0.
default,Beq,1.
sample = ~keyword_set(interp)
;
tini=1e-30 ; a small number
;
;  Set up a window for double buffering.
;
if(keyword_set(doublebuffer)) then begin
  base=widget_base(title=title)
  draw=widget_draw(base,xsize=wsx,ysize=wsy)
  widget_control,/realize,base
  widget_control,draw,get_value=windex
endif else $
;
if (keyword_set(png_truecolor)) then png=1
;
;  Read the dimensions and precision (single or double) from dim.dat.
;
pc_set_precision, datadir=datadir
;
pc_read_dim, obj=dim, datadir=datadir, proc=proc, /quiet
nx=dim.nx & ny=dim.ny & nz=dim.nz
mx=dim.mx & my=dim.my & mz=dim.mz
nghostx=dim.nghostx & nghosty=dim.nghosty & nghostz=dim.nghostz
nprocx=dim.nprocx & nprocy=dim.nprocy & nprocz=dim.nprocz
ncpus=nprocx*nprocy*nprocz
;
;  Read grid data.
;
pc_read_grid, obj=grid, proc=proc, swap_endian=swap_endian, /quiet
x=grid.x(dim.l1:dim.l2) & y=grid.y(dim.m1:dim.m2) & z=grid.z(dim.n1:dim.n2)
;
;  Set reasonable extension for 2-D runs.
;
if ( (nx ne 1) and (ny ne 1) and (nz eq 1) ) then extension='xy'
if ( (nx ne 1) and (ny eq 1) and (nz ne 1) ) then extension='xz'
if ( (nx eq 1) and (ny ne 1) and (nz ne 1) ) then extension='yz'
;
;  Consider non-equidistant grid
;
pc_read_param, obj=par, dim=dim, datadir=datatodir, /quiet
if not all(par.lequidist) then begin
  massage = 1
;
  if nx gt 1 and not par.lequidist[0] then begin
    x0 = 0.5 * (grid.x[dim.l1-1] + grid.x[dim.l1])
    x1 = 0.5 * (grid.x[dim.l2] + grid.x[dim.l2+1])
    dx = (x1 - x0) / nx
    iix = spline(grid.x, findgen(mx) - nghostx, x0 + (findgen(nx) + 0.5) * dx)
  endif else $
    iix = findgen(nx)
;
  if ny gt 1 and not par.lequidist[1] then begin
    y0 = 0.5 * (grid.y[dim.m1-1] + grid.y[dim.m1])
    y1 = 0.5 * (grid.y[dim.m2] + grid.y[dim.m2+1])
    dy = (y1 - y0) / ny
    iiy = spline(grid.y, findgen(my) - nghosty, y0 + (findgen(ny) + 0.5) * dy)
  endif else $
    iiy = findgen(ny)
;
  if nz gt 1 and not par.lequidist[2] then begin
    z0 = 0.5 * (grid.z[dim.n1-1] + grid.z[dim.n1])
    z1 = 0.5 * (grid.z[dim.n2] + grid.z[dim.n2+1])
    dz = (z1 - z0) / nz
    iiz = spline(grid.z, findgen(mz) - nghostz, z0 + (findgen(nz) + 0.5) * dz)
  endif else $
    iiz = findgen(nz)
;
  if extension eq 'xy' then begin
    ii1 = iix
    ii2 = iiy
  endif else if extension eq 'xz' then begin
    ii1 = iix
    ii2 = iiz
  endif else begin
    ii1 = iiy
    ii2 = iiz
  endelse
endif else massage = 0
;
if (n_elements(proc) ne 0) then begin
  file_slice=datadir+'/proc'+str(proc)+'/slice_'+field+'.'+extension
endif else begin
  file_slice=datadir+'/slice_'+field+'.'+extension
  if (not quiet) then print,'file_slice=',file_slice
endelse
;
if (keyword_set(polar)) then begin
  if (anglecoord eq 'y') then begin
    theta = y
  end else if (anglecoord eq 'z') then begin
    theta = z
  endif
  xx = fltarr(nx,nz)
  yy = fltarr(nx,nz)
  for i=0,nx-1 do begin
    for j=0,nz-1 do begin
      xx(i,j) = x(i)*cos(theta(j))
      yy(i,j) = x(i)*sin(theta(j))
    endfor
  endfor
endif
;
if (keyword_set(shell)) then begin
;
;  To mask outside shell, need full grid; read from varfiles.
;
  datalocdir=datadir+'/proc0'
  mxloc=0L & myloc=0L & mzloc=0L
;
  close,1
  openr,1,datalocdir+'/'+dimfile
  readf,1,mxloc,myloc,mzloc
  close,1
;
  nxloc=mxloc-2*nghostx
  nyloc=myloc-2*nghosty
  nzloc=mzloc-2*nghostz
;
  x=fltarr(mx)*one & y=fltarr(my)*one & z=fltarr(mz)*one
  xloc=fltarr(mxloc)*one & yloc=fltarr(myloc)*one & zloc=fltarr(mzloc)*one
  readstring=''
;
  for i=0,ncpus-1 do begin        ; read data from individual files
    if n_elements(proc) ne 0 then begin
      datalocdir=datadir+'/proc'+str(proc)
    endif else begin
      datalocdir=datadir+'/proc'+strtrim(i,2)
    endelse
;  Read processor position.
    dummy=''
    ipx=0L &ipy=0L &ipz=0L
    close,1
    openr,1,datalocdir+'/'+dimfile
    readf,1, dummy
    readf,1, dummy
    readf,1, dummy
    readf,1, ipx,ipy,ipz
    close,1
    openr,1, datalocdir+'/'+varfile, /F77, swap_endian=swap_endian
    if (execute('readu,1'+readstring) ne 1) then $
          message, 'Error reading: ' + 'readu,1'+readstring
    readu,1, t, xloc, yloc, zloc
    close,1
;
;  Don't overwrite ghost zones of processor to the left (and accordingly in
;  y and z direction makes a difference on the diagonals).
;
    if (ipx eq 0) then begin
      i0x=ipx*nxloc & i1x=i0x+mxloc-1
      i0xloc=0 & i1xloc=mxloc-1
    endif else begin
      i0x=ipx*nxloc+nghostx & i1x=i0x+mxloc-1-nghostx
      i0xloc=nghostx & i1xloc=mxloc-1
    endelse
;
    if (ipy eq 0) then begin
      i0y=ipy*nyloc & i1y=i0y+myloc-1
      i0yloc=0 & i1yloc=myloc-1
    endif else begin
      i0y=ipy*nyloc+nghosty & i1y=i0y+myloc-1-nghosty
      i0yloc=nghosty & i1yloc=myloc-1
    endelse
;
    if (ipz eq 0) then begin
      i0z=ipz*nzloc & i1z=i0z+mzloc-1
      i0zloc=0 & i1zloc=mzloc-1
    endif else begin
      i0z=ipz*nzloc+nghostz & i1z=i0z+mzloc-1-nghostz
      i0zloc=nghostz & i1zloc=mzloc-1
    endelse
;
    x[i0x:i1x] = xloc[i0xloc:i1xloc]
    y[i0y:i1y] = yloc[i0yloc:i1yloc]
    z[i0z:i1z] = zloc[i0zloc:i1zloc]
;
  endfor
;
  xx = spread(x, [1,2], [my,mz])
  yy = spread(y, [0,2], [mx,mz])
  zz = spread(z, [0,1], [mx,my])
  rr = sqrt(xx^2+yy^2+zz^2)
;
;  Assume slices are all central for now -- perhaps generalize later.
;  nb: need pass these into boxbotex_scl for use after scaling of image;
;      otherwise pixelisation can be severe...
;  nb: at present using the same z-value for both horizontal slices;
;      hardwired into boxbotex_scl, also.
;
  ix=mx/2 & iy=my/2 & iz=mz/2 & iz2=iz
  if (extension eq 'xy') then rrxy =rr(nghostx:mx-nghostx-1,nghosty:my-nghosty-1,iz)
  if (extension eq 'xy2') then rrxy2=rr(nghostx:mx-nghostx-1,nghosty:my-nghosty-1,iz2)
  if (extension eq 'xz') then rrxz =rr(nghostx:mx-nghostx-1,iy,nghostz:mz-nghostz-1)
  if (extension eq 'yz') then rryz =rr(ix,nghosty:my-nghosty-1,nghostz:mz-nghostz-1)
;
endif
;
t=zero & islice=0
;
if (extension eq 'xy') then plane=fltarr(nx,ny)*one
if (extension eq 'xy2') then plane=fltarr(nx,ny)*one
if (extension eq 'xz') then plane=fltarr(nx,nz)*one
if (extension eq 'yz') then plane=fltarr(ny,nz)*one
size_plane=size(plane)
if (not quiet) then print, 'Array size: ', size_plane[0:size_plane[0]]
;
slice_xpos=0.0*one
slice_ypos=0.0*one
slice_zpos=0.0*one
slice_z2pos=0.0*one
;
;  Open MPEG file, if keyword is set.
;
dev='x' ;(default)
if (keyword_set(png)) then begin
  Nwx=zoom*size_plane[1] & Nwy=zoom*size_plane[2]
  Nwy=Nwx*15/20
  help,Nwx,Nwy
  resolution=[Nwx,Nwy] ; set window size
  if (not quiet) then print, 'z-buffer resolution in pixels '+ $
      '(set with zoom=', strtrim(zoom,2), ') =', strtrim(resolution,2)
  set_plot, 'z'                   ; switch to Z buffer
  device, set_resolution=resolution ; set window size
  itpng=0 ;(image counter)
  dev='z'
endif else if (keyword_set(mpeg)) then begin
  Nwx=zoom*size_plane[1] & Nwy=zoom*size_plane[2]
  resolution=[Nwx,Nwy] ; set window size
  if (not quiet) then print,'z-buffer resolution (in pixels)=',resolution
  set_plot, 'z'                   ; switch to Z buffer
  device, set_resolution=resolution ; set window size
  dev='z'
  if (!d.name eq 'X') then window,2,xs=Nwx,ys=Nwy
  mpeg_name = 'movie.mpg'
  if (not quiet) then print,'write mpeg movie: ',mpeg_name
  mpegID = mpeg_open([Nwx,Nwy],filename=mpeg_name)
  itmpeg=0 ;(image counter)
endif else if (not keyword_set(doublebuffer)) then begin
  Nwx = zoom * size_plane[1]
  Nwy = zoom * size_plane[2]
  window, xsize=Nwx, ysize=Nwy, title=title
endif
;
;  Allow for skipping "stride" time slices.
;
istride=stride ;(make sure the first one is written)
;
if (keyword_set(global_scaling)) then begin
  first=1L
  close,1 & openr,1,file_slice,/f77
  while (not eof(1)) do begin
    if (keyword_set(oldfile)) then begin ; For files without position
      readu,1,plane,t
    endif else begin
      readu,1,plane,t,slice_z2pos
    endelse
    if (keyword_set(exponential)) then begin
      if (first) then begin
        amax=exp(max(plane))
        amin=exp(min(plane))
        first=0L
      endif else begin
        amax=max([amax,exp(max(plane))])
        amin=min([amin,exp(min(plane))])
      endelse
    endif else if (keyword_set(log)) then begin
      if (first) then begin
        amax=alog10(max(plane))
        amin=alog10(min(plane)+tini)
        first=0L
      endif else begin
        amax=max([amax,alog10(max(plane))])
        amin=min([amin,alog10(min(plane)+tini)])
      endelse
    endif else if (keyword_set(nsmooth)) then begin
      if (first) then begin
        amax=max(smooth(plane,nsmooth))
        amin=min(smooth(plane,nsmooth))
        first=0L
      endif else begin
        amax=max([amax,max(smooth(plane,nsmooth))])
        amin=min([amin,min(smooth(plane,nsmooth))])
      endelse
    endif else if (keyword_set(sqroot)) then begin
      if (first) then begin
        amax=sqrt(max(plane))
        amin=sqrt(min(plane))
        first=0L
      endif else begin
        amax=max([amax,sqrt(max(plane))])
        amin=min([amin,sqrt(min(plane))])
      endelse
    endif else begin
      if (first) then begin
        amax=max(plane)
        amin=min(plane)
        first=0L
      endif else begin
        amax=max([amax,max(plane)])
        amin=min([amin,min(plane)])
      endelse
    endelse
  end
  close,1
  if (not quiet) then print,'Scale using global min, max: ', amin, amax
endif
;
close,1 & openr,1,file_slice,/f77,swap_endian=swap_endian
while (not eof(1)) do begin
  if (keyword_set(oldfile)) then begin ; For files without position
    readu,1,plane,t
  end else begin
    readu,1,plane,t,slice_z2pos
  end
;
  if massage then plane = interpolate(plane, ii1, ii2, /grid)
;
;  Rescale data with optional parameter zoom.
;  WARNING: the scaling can produce artifacts at shearing boundaries. Contour
;  plots give better results in that case (/contour).
;  In future, we might want to choose better names than x2 and y2,
;    especially if they are later theta (theta2) and phi.
;
  planesize=size(plane)
  nx_plane=planesize[1]
  ny_plane=planesize[2]
  if extension eq 'xy' then begin
    x2=rebin(x,zoom*nx_plane,sample=sample)
    y2=rebin(y,zoom*ny_plane,sample=sample)
  endif else if extension eq 'yz' then begin
    x2=rebin(y,zoom*nx_plane,sample=sample)
    y2=rebin(z,zoom*ny_plane,sample=sample)
  endif
;
;  if extension eq 'xz', then our y2 wasn't right.
;
if extension eq 'xz' then y2=rebin(z,zoom*ny_plane,sample=sample)
;
;  other options
;
  if (keyword_set(exponential)) then begin
    plane2=rebin(exp(plane),zoom*nx_plane,zoom*ny_plane,sample=sample)
  endif else if (keyword_set(nsmooth)) then begin
    plane2=rebin(smooth(plane,nsmooth),zoom*nx_plane,zoom*ny_plane,sample=sample)
  endif else if (keyword_set(sqroot)) then begin
    plane2=rebin(sqrt(plane),zoom*nx_plane,zoom*ny_plane,sample=sample)
  endif else if (keyword_set(log)) then begin
     plane2=rebin(alog10(plane+tini),zoom*nx_plane,zoom*ny_plane,sample=sample)
  endif else if (keyword_set(cubic)) then begin
     if (cubic gt 0.0) then cubic = -0.5
     plane2=congrid(plane,zoom*nx_plane,zoom*ny_plane,/center,cubic=cubic,interp=interp)
  endif else begin
     plane2=congrid(plane,zoom*nx_plane,zoom*ny_plane,/center,interp=interp)
  endelse
;
;  Do masking, if shell set.
;
  if (keyword_set(shell)) then begin
    white=255
    if (extension eq 'xy') then begin
      zrr = rebinbox(reform(rrxy,nx,ny),zoom)
      indxy=where(zrr lt r_int or zrr gt r_ext)
      plane2(indxy)=white
    endif
    if (extension eq 'xy2') then begin
      zrr2 = rebinbox(reform(rrxy2,nx,ny),zoom)
      indxy2=where(zrr2 lt r_int or zrr2 gt r_ext)
      plane2(indxy2)=white
    endif
    if (extension eq 'xz') then begin
      yrr = rebinbox(reform(rrxz,nx,nz),zoom,/zdir)
      indxz=where(yrr lt r_int or yrr gt r_ext)
      plane2(indxz)=white
    endif
    if (extension eq 'yz') then begin
      xrr = rebinbox(reform(rryz,ny,nz),zoom,/zdir)
      indyz=where(xrr lt r_int or xrr gt r_ext)
      plane2(indyz)=white
    endif
  endif
;
  if (keyword_set(debug)) then begin
    print, t, min([plane2,xy,xz,yz]), max([plane2,xy,xz,yz])
  endif else begin
    if ( (t ge tmin) and (t le tmax) ) then begin
      if (istride eq stride) then begin
;
        if (keyword_set(automatic_scaling)) then begin
          amax = max(plane2)
          amin = min(plane2)
        endif
;
;  Show image scaled between amin and amax and filling whole screen.
;
        if(keyword_set(doublebuffer)) then begin
;
;  Paint into buffer.
;
          window,xsize=wsx,ysize=wsy,/pixmap,/free
          pixID=!D.Window
        endif
        if (keyword_set(contourplot)) then begin
          lev=grange(amin,amax,60)
         ;contourfill, plane2, x2, y2, levels=grange(amin,amax,60), $
          contourfill, plane2, x2, y2, lev=lev, $
          tit='!8t!6 ='+string(t/tunit,fo="(f7.1)"), _extra=_extra
          colorbar_co,range=[min(lev),max(lev)],pos=[0.95,0.12,0.98,0.92],/vert, $
            ytickformat='(f6.3)',yticks=2,ytickv=[min(lev),0.,max(lev)], $
            yaxis=0,char=1.5,col=255,ytit='!6',xtit='!8B!dz!n!6'
        end else if (keyword_set(polar)) then begin
          if (style_polar eq 'fill') then begin
            contourfill, plane2, x2, y2, levels=grange(amin,amax,60), $
                tit='!8t!6 ='+string(t/tunit,fo="(f7.1)"), _extra=_extra
          end else if (style_polar eq 'lines') then begin
            contour, plane2, x2, y2, nlevels=nlevels, $
                tit='!8t!6 ='+string(t/tunit,fo="(f7.1)"), _extra=_extra
          endif
;
;  spherical surface plot in a good projection
;  still need to check whether /rotate is correct (see below)
;  added phi_shift keyword
        end else if (keyword_set(spherical_surface)) then begin
          theta2=x2/!dtor
          phi=y2/!dtor
          if(keyword_set(phi_shift)) then phi=phi-phi_shift
           !p.background=255
          map_set,/orthographic,/grid,/noborder,/isotropic,latdel=15,londel=15,limit=[0,-30,89,160],xmargin=0.5,ymargin=0.5,15,60,color=0
          lev=grange(amin,amax,25)
          if(keyword_set(rotate)) then tmp=rotate(plane2,3) else tmp=transpose(plane2)
          if(keyword_set(Beq)) then  tmp=tmp/Beq
          if(keyword_set(taud)) then t=t/taud
            contour,clip(tmp,minmax(lev)),phi,90.-theta2,lev=lev,/fill,/overplot, $
           col=0, _extra=_extra
          ;colorbar_co,range=[min(lev),max(lev)],pos=[0.07,0.3,0.10,0.65],/vert, $
          colorbar_co,range=[min(lev),max(lev)],pos=[0.1,0.75,0.14,0.95],/vert, $
            ytickformat='(F5.2)',yticks=2,ytickv=[min(lev),0.,max(lev)], $
            yaxis=0,charsize=3,col=0 ;,xtit='!8U!dr!n!6/!8c!6!ds!n'
           xyouts,480,800,'!8t!6/!7s!6 = '+str(t,fo='(f5.2)')+'', $
           col=0,/device,charsize=4
           ;xyouts,480,800,'!8t!6 = '+str(t,fo='(f5.1)')+'',col=0,/device,charsize=4
        wait,wait
        endif else begin
;          plotimage, plane2, range=[amin,amax]
          tv, bytscl(plane2,min=amin,max=amax), iplane
        endelse
        if(keyword_set(doublebuffer)) then begin
          wset,windex
          device,copy=[0,0,!D.X_Size,!D.Y_Size,0,0,pixID]
          wdelete,pixID
        endif
        if(keyword_set(savefile)) then begin
          if (size (slices, /type) eq 0) then begin
            slices = plane
          endif else begin
            slices = [ [[slices]], [[plane]] ]
          endelse
        endif
        ;xyouts, 0.05, 0.9, /normal, $
        ;    '!8t!6='+string(t/tunit,fo="(f6.1)"), color=color, size=textsize
        if (keyword_set(png)) then begin
          istr2 = strtrim(string(itpng,'(I20.4)'),2) ;(only up to 9999 frames)
          image = tvrd()
;
;  Make background white, and write png file.
;
          ;bad=where(image eq 0) & image(bad)=255
          tvlct, red, green, blue, /get
          imgname = imgdir+'/img_'+istr2+'.png'
          write_png, imgname, image, red, green, blue
          if (keyword_set(png_truecolor)) then $
              spawn, 'mogrify -type TrueColor ' + imgname
          itpng=itpng+1 ;(counter)
          ;
        end else if (keyword_set(mpeg)) then begin
;
;  Write directly mpeg file.
;  For idl_5.5 and later this requires the mpeg license.
;
          image = tvrd(true=1)
          if (keyword_set(colmpeg)) then begin
;  ngrs seem to need to work explictly with 24-bit color to get
;  color mpegs to come out on my local machines...
            image24 = bytarr(3,Nwx,Nwy)
            tvlct, red, green, blue, /get
          endif
          for irepeat=0,nrepeat do begin
            if (keyword_set(colmpeg)) then begin
              image24[0,*,*]=red(image[0,*,*])
              image24[1,*,*]=green(image[0,*,*])
              image24[2,*,*]=blue(image[0,*,*])
              mpeg_put, mpegID, image=image24, frame=itmpeg, /order
            endif else begin
              mpeg_put, mpegID, window=2, frame=itmpeg, /order
            endelse
            itmpeg=itmpeg+1 ;(counter)
          end
          if (not quiet) then print,islice,itmpeg,t,min([plane2]),max([plane2])
        end else begin
;
;  Default: output on the screen.
;
          if ((islice eq 0) and not quiet) then $
              print, '----islice--------t----------min------------max--------'
          if (not quiet) then print,islice,t,min([plane2]),max([plane2])
        end
        istride=0
        wait,wait
;
;  Check whether file has been written.
;
        if (keyword_set(png)) then spawn,'ls -l '+imgname
;
      end else begin
        istride=istride+1
      end
    end
    islice=islice+1
  end
end
close,1
;
;  Write and close mpeg file.
;
if (keyword_set(mpeg)) then begin
  if (not quiet) then print,'Writing MPEG file..'
  mpeg_save, mpegID, filename=mpeg_name
  mpeg_close, mpegID
  set_plot,'X'
end
if (keyword_set(png))  then set_plot,'X'
if (keyword_set(savefile))  then begin
  num_slices = islice
  save, file=savefile, slices, num_slices
end
;
END
