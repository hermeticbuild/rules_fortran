module base_m
  integer, save :: state = 20
contains
  integer function base_value()
    base_value = state
  end function base_value
end module base_m
