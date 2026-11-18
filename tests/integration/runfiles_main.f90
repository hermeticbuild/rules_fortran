program runfiles_main
  character(len=32) :: arg, env
  integer :: u, value
  call get_command_argument(1, arg)
  if (trim(arg) /= 'ready') stop 1
  call get_environment_variable('FORT_ENV', env)
  if (trim(env) /= 'ready') stop 2
  open(newunit=u, file='payload.txt', status='old')
  read(u, *) value
  close(u)
  if (value /= 42) stop 3
end program runfiles_main
