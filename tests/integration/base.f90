module base_m
  use, intrinsic :: iso_c_binding, only: c_int
  integer(c_int), save :: state = 20
contains
  integer(c_int) function base_value()
    base_value = state
  end function base_value
end module base_m
