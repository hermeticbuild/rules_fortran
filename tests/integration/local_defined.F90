#if FORT_PRIVATE != 1
#error local definition missing
#endif
module local_m
  integer, parameter :: local_value = 42
end module local_m
