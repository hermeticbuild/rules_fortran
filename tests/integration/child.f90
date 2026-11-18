submodule (parent_m) child_m
contains
  module procedure parent_answer
    x = 42
  end procedure parent_answer
end submodule child_m
