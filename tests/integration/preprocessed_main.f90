#if FORT_VALUE != 42
#error propagated Fortran definition missing from consumer
#endif
program preprocessed_main
  use configured_m, only: configured_value
  if (configured_value /= 42) stop 1
end program preprocessed_main
