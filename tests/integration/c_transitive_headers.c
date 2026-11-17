#include "cc_dependency.h"

extern void answer(int *x);

int main(void) {
  int x = 0;
  answer(&x);
  return x == FROM_CC_DEP ? 0 : 1;
}
