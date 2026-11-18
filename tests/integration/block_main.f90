program block_main
  integer :: state
  common /saved_state/ state
  if (state /= 42) stop 1
end program block_main
