// fifo_tb.cpp -- C-simulation testbench for the HLS hls::stream FIFO kernel.
//
// In C-simulation the DATAFLOW/STREAM pragmas are ignored: the producer loop
// simply fills the stream and the consumer drains it. That is enough to check
// the functional result (out[i] == in[i] + inc) before committing to synthesis.
//
// Run with:  make csim   (from hls/fifo/)
#include <cstdio>
#include <vector>

extern "C" void fifo_stream(const int* in, int* out, int inc, int size);

int main() {
    const int N = 1024;
    const int INC = 7;
    std::vector<int> in(N), out(N, 0);
    for (int i = 0; i < N; ++i) in[i] = i * 3 - 5;

    fifo_stream(in.data(), out.data(), INC, N);

    int errors = 0;
    for (int i = 0; i < N; ++i) {
        int expected = in[i] + INC;
        if (out[i] != expected) {
            if (errors < 8)
                printf("  mismatch at %d: got %d expected %d\n", i, out[i], expected);
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
