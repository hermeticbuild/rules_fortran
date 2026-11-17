program hello
  use iso_fortran_env, only: int32
  integer(int32) :: answer
  answer = 42
  if (answer /= 42) stop 1
end program hello
