module right_m
  use base_m, only: base_value
contains
  integer function right_value()
    right_value = base_value() + 21
  end function right_value
end module right_m
