#include "interop.h"

int main(void) {
  int x = 0;
  answer(&x);
  return x == 42 ? 0 : 1;
}
