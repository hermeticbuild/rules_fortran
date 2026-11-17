program fixed_main
  integer :: x
  call fixed_answer(x)
  if (x /= 42) stop 1
end program fixed_main
