module left_m
  use base_m, only: base_value
contains
  integer function left_value()
    left_value = base_value() + 1
  end function left_value
end module left_m
