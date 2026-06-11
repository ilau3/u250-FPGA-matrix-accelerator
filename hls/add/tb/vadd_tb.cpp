// vadd_tb.cpp -- C-simulation testbench for the HLS vadd kernel.
//
// Because an HLS kernel is just C++, you can compile it with an ordinary host
// compiler and check its behavior in milliseconds -- no FPGA, no synthesis.
// This is the fast inner loop when developing an HLS kernel: get the C model
// right here first, then synthesize.
//
// Run with:  make csim   (from hls/add/)
#include <cstdio>
#include <cstdlib>
#include <vector>

extern "C" void vadd(const int* a, const int* b, int* c, int size);

int main() {
    const int N = 1024;
    std::vector<int> a(N), b(N), c(N, 0);
    for (int i = 0; i < N; ++i) {
        a[i] = i;
        b[i] = 2 * i + 1;
    }

    vadd(a.data(), b.data(), c.data(), N);

    int errors = 0;
    for (int i = 0; i < N; ++i) {
        int expected = a[i] + b[i];
        if (c[i] != expected) {
            if (errors < 8)
                printf("  mismatch at %d: got %d expected %d\n", i, c[i], expected);
            ++errors;
        }
    }

    if (errors == 0) {
        printf("RESULT: PASS  (%d elements)\n", N);
        return 0;
    }
    printf("RESULT: FAIL  (%d mismatches)\n", errors);
    return 1;
}
