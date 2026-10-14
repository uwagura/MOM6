! This file is part of MOM6, the Modular Ocean Model version 6.
! See the LICENSE file for licensing information.
! SPDX-License-Identifier: Apache-2.0

!> Describes a sparse set of horizontal grid points, such as the points along an open boundary
!! segment, so that fields at those points can be stored compactly in files.
module MOM_point_set

use MOM_coms,          only : sum_across_PEs
use MOM_error_handler, only : MOM_error, FATAL
use MOM_io,            only : axis_info, set_axis_info

implicit none ; private

public point_set_init, point_set_end, point_set_gather, point_set_scatter
public point_set_axis, point_set_size, point_set_axis_name

! A note on unit descriptions in comments: MOM6 uses units that can be rescaled for dimensional
! consistency testing. These are noted in comments with units like Z, H, L, and T, along with
! their mks counterparts with notation like "a velocity [Z T-1 ~> m s-1]".  If the units
! vary with the Boussinesq approximation, the Boussinesq variant is given first.
! The functions in this module work with variables with arbitrary units, in which case the
! arbitrary rescaled units are indicated with [A ~> a], while the unscaled units are just [a].

!> A set of horizontal points that is stored in files as a list of npts_global entries.  Each PE
!! holds the subset of the points that is in its memory domain, as indices into a local array,
!! and the position of each of these points in the list.  Every point in the list is owned by at
!! most one PE, which supplies its values when the list is gathered.
type, public :: point_set_type ; private
  character(len=32)  :: axis_name = ""    !< The name of the axis of this list of points in files
  character(len=240) :: longname = ""     !< A description of this list of points
  integer :: npts_global = 0              !< The number of points in the list
  integer :: n_local = 0                  !< The number of points of the list in this PE's memory
  integer, allocatable :: i_loc(:)        !< The first index of each local point in the local array
  integer, allocatable :: j_loc(:)        !< The second index of each local point in the local array
  integer, allocatable :: p_list(:)       !< The position of each local point in the list
  logical, allocatable :: owned(:)        !< True if this PE supplies the value of each local point
end type point_set_type

contains

!> Set up a point set.  This must be called on all PEs, including those with no local points.
subroutine point_set_init(ps, axis_name, npts_global, i_loc, j_loc, p_list, owned, longname)
  type(point_set_type),  intent(inout) :: ps          !< The point set being set up
  character(len=*),      intent(in)    :: axis_name   !< The name of the axis of this list of points
                                                      !! in files, at most 32 characters
  integer,               intent(in)    :: npts_global !< The number of points in the list
  integer, dimension(:), intent(in)    :: i_loc       !< The first index of each local point in the
                                                      !! local arrays that will be gathered or scattered
  integer, dimension(:), intent(in)    :: j_loc       !< The second index of each local point in the
                                                      !! local arrays that will be gathered or scattered
  integer, dimension(:), intent(in)    :: p_list      !< The position of each local point in the list,
                                                      !! between 1 and npts_global
  logical, dimension(:), intent(in)    :: owned       !< True if this PE supplies the value of a point
                                                      !! when the list is gathered
  character(len=*), optional, intent(in) :: longname  !< A description of this list of points

  ! Local variables
  integer, allocatable :: n_owners(:)  ! The number of PEs that own each point in the list
  character(len=256) :: mesg
  integer :: n

  if (len_trim(axis_name) > len(ps%axis_name)) call MOM_error(FATAL, &
      "point_set_init: The axis name "//trim(axis_name)//" is too long.")
  if (npts_global < 1) call MOM_error(FATAL, &
      "point_set_init: The point set "//trim(axis_name)//" must have at least one point.")
  if ((size(j_loc) /= size(i_loc)) .or. (size(p_list) /= size(i_loc)) .or. (size(owned) /= size(i_loc))) &
    call MOM_error(FATAL, "point_set_init: Inconsistent sizes of the index arrays for "//trim(axis_name))

  call point_set_end(ps)
  ps%axis_name = trim(axis_name)
  ps%longname = "" ; if (present(longname)) ps%longname = trim(longname)
  ps%npts_global = npts_global
  ps%n_local = size(i_loc)
  allocate(ps%i_loc(ps%n_local), ps%j_loc(ps%n_local), ps%p_list(ps%n_local), ps%owned(ps%n_local))
  do n=1,ps%n_local
    if ((p_list(n) < 1) .or. (p_list(n) > npts_global)) then
      write(mesg, '("point_set_init: List position ",I0," is outside of the range 1 to ",I0," for ")') &
            p_list(n), npts_global
      call MOM_error(FATAL, trim(mesg)//trim(axis_name))
    endif
    if ((i_loc(n) < 1) .or. (j_loc(n) < 1)) call MOM_error(FATAL, &
        "point_set_init: Local indices must be positive for "//trim(axis_name))
    ps%i_loc(n) = i_loc(n) ; ps%j_loc(n) = j_loc(n)
    ps%p_list(n) = p_list(n) ; ps%owned(n) = owned(n)
  enddo

  ! Check that no point in the list is owned by more than one PE.  Points that no PE owns, for
  ! example under PEs that are eliminated by a mask table, are allowed and are gathered as zeros.
  allocate(n_owners(npts_global), source=0)
  do n=1,ps%n_local ; if (ps%owned(n)) n_owners(ps%p_list(n)) = n_owners(ps%p_list(n)) + 1 ; enddo
  call sum_across_PEs(n_owners, npts_global)
  do n=1,npts_global ; if (n_owners(n) > 1) then
    write(mesg, '("point_set_init: Point ",I0," of ",A," is owned by ",I0," PEs.")') &
          n, trim(axis_name), n_owners(n)
    call MOM_error(FATAL, mesg)
  endif ; enddo
  deallocate(n_owners)

end subroutine point_set_init

!> Deallocate the memory associated with a point set.
subroutine point_set_end(ps)
  type(point_set_type), intent(inout) :: ps  !< The point set being deallocated

  if (allocated(ps%i_loc)) deallocate(ps%i_loc)
  if (allocated(ps%j_loc)) deallocate(ps%j_loc)
  if (allocated(ps%p_list)) deallocate(ps%p_list)
  if (allocated(ps%owned)) deallocate(ps%owned)
  ps%n_local = 0 ; ps%npts_global = 0
end subroutine point_set_end

!> Gather the values of a local 3-d array at the points in a point set into a list that is
!! complete and identical on every PE.  This must be called on all PEs.  It is exact, because
!! each entry in the list has at most one nonzero contribution, but negative zeros become zeros.
subroutine point_set_gather(ps, field, list, unscale)
  type(point_set_type),   intent(in)  :: ps      !< The point set to gather
  real, dimension(:,:,:), intent(in)  :: field   !< The local array, indexed as described in ps,
                                                 !! in arbitrary rescaled units [A ~> a]
  real, dimension(:,:),   intent(out) :: list    !< The values in the list, with size npts_global
                                                 !! by the third dimension of field [a]
  real,         optional, intent(in)  :: unscale !< A factor by which field is multiplied to give
                                                 !! the values in the list [a A-1 ~> 1]

  ! Local variables
  real :: scale_fac  ! The factor by which to multiply field [a A-1 ~> 1]
  integer :: n, k

  call check_list_size(ps, size(list,1), size(list,2), size(field,3), "point_set_gather")
  scale_fac = 1.0 ; if (present(unscale)) scale_fac = unscale

  list(:,:) = 0.0
  do k=1,size(list,2) ; do n=1,ps%n_local ; if (ps%owned(n)) then
    list(ps%p_list(n),k) = scale_fac * field(ps%i_loc(n),ps%j_loc(n),k)
  endif ; enddo ; enddo
  call sum_across_PEs(list, size(list))

end subroutine point_set_gather

!> Copy the values from a complete list into all of the points of a point set that are in a
!! local 3-d array, including points in halos that this PE does not own.
subroutine point_set_scatter(ps, list, field, scale)
  type(point_set_type),   intent(in)    :: ps     !< The point set to scatter
  real, dimension(:,:),   intent(in)    :: list   !< The values in the list, with size npts_global
                                                  !! by the third dimension of field [a]
  real, dimension(:,:,:), intent(inout) :: field  !< The local array, indexed as described in ps,
                                                  !! in arbitrary rescaled units [A ~> a]
  real,         optional, intent(in)    :: scale  !< A factor by which the values in the list are
                                                  !! multiplied to give field [A a-1 ~> 1]

  ! Local variables
  real :: scale_fac  ! The factor by which to multiply the list [A a-1 ~> 1]
  integer :: n, k

  call check_list_size(ps, size(list,1), size(list,2), size(field,3), "point_set_scatter")
  scale_fac = 1.0 ; if (present(scale)) scale_fac = scale

  do k=1,size(list,2) ; do n=1,ps%n_local
    field(ps%i_loc(n),ps%j_loc(n),k) = scale_fac * list(ps%p_list(n),k)
  enddo ; enddo

end subroutine point_set_scatter

!> Return a description of the axis of a point set for use in files.
function point_set_axis(ps) result(axis)
  type(point_set_type), intent(in) :: ps   !< The point set being described
  type(axis_info)                  :: axis !< A description of the axis of the point set

  call set_axis_info(axis, ps%axis_name, units="nondim", longname=ps%longname, &
                     ax_size=ps%npts_global, cartesian="N")
end function point_set_axis

!> Return the number of points in the list of a point set.
integer function point_set_size(ps)
  type(point_set_type), intent(in) :: ps   !< The point set being queried

  point_set_size = ps%npts_global
end function point_set_size

!> Return the name of the axis of a point set in files.
function point_set_axis_name(ps) result(name)
  type(point_set_type), intent(in) :: ps   !< The point set being queried
  character(len=32)                :: name !< The name of the axis of the point set

  name = ps%axis_name
end function point_set_axis_name

!> Stop with an error if a list does not have the shape needed for a point set and field.
subroutine check_list_size(ps, n1, n2, nz, caller)
  type(point_set_type), intent(in) :: ps     !< The point set being used
  integer,              intent(in) :: n1     !< The first dimension of the list
  integer,              intent(in) :: n2     !< The second dimension of the list
  integer,              intent(in) :: nz     !< The third dimension of the local field
  character(len=*),     intent(in) :: caller !< The name of the calling routine

  character(len=256) :: mesg

  if ((n1 /= ps%npts_global) .or. (n2 /= nz)) then
    write(mesg, '(": The list for ",A," has shape ",I0," by ",I0,", but ",I0," by ",I0," is needed.")') &
          trim(ps%axis_name), n1, n2, ps%npts_global, nz
    call MOM_error(FATAL, trim(caller)//mesg)
  endif
end subroutine check_list_size

!> \namespace mom_point_set
!!
!! A point set describes a sparse set of horizontal grid points that are stored in files as a
!! single list, for example the velocity points along an open boundary segment.  This avoids
!! storing such values in domain-sized arrays that are almost entirely zero.  The module does not
!! know where the points come from: the caller supplies, for each point that is in this PE's
!! memory, its indices in the local arrays, its position in the list, and whether this PE owns
!! it.  The order of the list should not depend on the domain decomposition or grid rotation, so
!! that files are interchangeable between them.
!!
!! point_set_gather builds the complete list on every PE by summing the contributions of the
!! owning PEs across all PEs, and point_set_scatter fills every local copy of each point,
!! including those in halos, from a complete list.  Other uses, such as reading boundary-only
!! sponge data, can reuse the same descriptor.
end module MOM_point_set
