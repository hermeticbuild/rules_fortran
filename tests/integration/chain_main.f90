program chain_main
  use left_m, only: left_value
  use right_m, only: right_value
  if (left_value() + right_value() /= 62) stop 1
end program chain_main
