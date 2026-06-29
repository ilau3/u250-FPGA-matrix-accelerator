#include <cstdio>
#include <cstdlib>
#include <vector>

extern "C" void matmul(const int* a, const int* b, int* c, int p, int q, int sigma);

int main() {
    const int P = 64, Q = 64, SIGMA = 64;

    std::vector<int> a(P*Q), b(Q*SIGMA), c(P*SIGMA, 0), ref(P*SIGMA, 0);

    for (int i = 0; i < P*Q;     i++) a[i] = rand() % 10;
    for (int i = 0; i < Q*SIGMA; i++) b[i] = rand() % 10;

    matmul(a.data(), b.data(), c.data(), P, Q, SIGMA);

    for (int i = 0; i < P; i++)
        for (int j = 0; j < SIGMA; j++) {
            int sum = 0;
            for (int k = 0; k < Q; k++)
                sum += a[i*Q+k] * b[k*SIGMA+j];
            ref[i*SIGMA+j] = sum;
        }

    int errors = 0;
    for (int i = 0; i < P*SIGMA; i++) {
        if (c[i] != ref[i]) {
            if (errors < 8)
                printf("  mismatch at %d: got %d expected %d\n", i, c[i], ref[i]);
            errors++;
        }
    }

    if (errors == 0) {
        printf("RESULT: PASS  (%dx%d x %dx%d)\n", P, Q, Q, SIGMA);
        return 0;
    }
    printf("RESULT: FAIL  (%d mismatches)\n", errors);
    return 1;
}
