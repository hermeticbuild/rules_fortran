subroutine answer(x) bind(C, name="answer")
  use iso_c_binding, only: c_int
  integer(c_int), intent(out) :: x
  print *, 'Fortran runtime from a C main'
  x = 42
end subroutine answer
