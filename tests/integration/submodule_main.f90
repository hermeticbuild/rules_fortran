program submodule_main
  use parent_m, only: parent_answer
  integer :: x
  call parent_answer(x)
  if (x /= 42) stop 1
end program submodule_main
