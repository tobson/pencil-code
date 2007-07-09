;;
;;  $Id: pc_is_vectorfield.pro,v 1.3 2007-07-09 06:16:53 ajohan Exp $
;;
function pc_is_vectorfield, variable, $
    subscripts=subscripts, dim=dim, $
    TRIM=TRIM, NOVECTORS=NOVECTORS, _EXTRA=e
COMPILE_OPT IDL2,HIDDEN
;
  varsize=size(variable)
;
  if (n_elements(dim) ne 1) then pc_read_dim, obj=dim, _EXTRA=e
;
;  The real number of dimensions for trimmed arrays is read from dim.dat.
;
  if (trim) then begin
    ndim = (dim.nx ne 1) + (dim.ny ne 1) + (dim.nz ne 1)
  endif else begin
    ndim=3
  endelse
;
;  Find out if array is a vector field.
;
  result=0
  if ( (varsize[0] eq 1) and (varsize[1] eq 1) ) then begin
;  Special: 0-D runs are represented in a 1-D array with one element.
    result=0
  endif else begin
    if ( varsize[0] gt ndim ) then result=1
  endelse
;
;  Find proper subscripts in case of trimmed/non-trimmed variables.
;
  if ( (result eq 1) and (arg_present(subscripts)) ) then begin
    if (trim) then begin
      subscripts=make_array(varsize[0],/STRING,value='*')
    endif else begin
      subscripts=make_array(varsize[0],/STRING,value='*')
      subscripts[0]=string(dim.l1)+':'+string(dim.l2) 
      subscripts[1]=string(dim.m1)+':'+string(dim.m2) 
      subscripts[2]=string(dim.n1)+':'+string(dim.n2) 
    endelse
  endif

  if ( (result eq 0) and (n_elements(subscripts) ne 0) ) then $
      undefine, subscripts
  
  return, result

end
