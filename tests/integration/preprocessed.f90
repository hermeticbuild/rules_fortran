#if FORT_VALUE != 42
#error propagated Fortran definition missing
#endif
module configured_m
  integer, parameter :: configured_value = FORT_VALUE
end module configured_m
