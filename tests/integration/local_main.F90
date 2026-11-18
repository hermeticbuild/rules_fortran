#ifdef FORT_PRIVATE
#error local definition leaked to dependent
#endif
program local_main
  use local_m, only: local_value
  if (local_value /= 42) stop 1
end program local_main
