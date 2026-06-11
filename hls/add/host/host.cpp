// host.cpp -- runs the HLS vadd kernel on the U250 with the native XRT API.
//
// This is essentially identical to rtl/add/host/host.cpp: the host neither
// knows nor cares whether the kernel inside the xclbin was written in RTL or
// generated from C++ by HLS. Only the kernel name and argument order differ.
//
//     vadd(int* a, int* b, int* c, int size)
//
// Usage:  ./host <xclbin>
#include <cstdlib>
#include <iostream>
#include <vector>

#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <xclbin>\n";
        return EXIT_FAILURE;
    }
    const std::string xclbin_path = argv[1];
    const int N = 4096;
    const size_t bytes = sizeof(int) * N;

    auto device = xrt::device(0);
    std::cout << "Loading xclbin: " << xclbin_path << "\n";
    auto uuid = device.load_xclbin(xclbin_path);
    auto krnl = xrt::kernel(device, uuid, "vadd");

    auto bo_a = xrt::bo(device, bytes, krnl.group_id(0));
    auto bo_b = xrt::bo(device, bytes, krnl.group_id(1));
    auto bo_c = xrt::bo(device, bytes, krnl.group_id(2));

    auto a = bo_a.map<int*>();
    auto b = bo_b.map<int*>();
    auto c = bo_c.map<int*>();
    for (int i = 0; i < N; ++i) {
        a[i] = i;
        b[i] = 2 * i + 1;
        c[i] = 0;
    }
    bo_a.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    bo_b.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    std::cout << "Launching kernel (N = " << N << ") ...\n";
    auto run = krnl(bo_a, bo_b, bo_c, N);
    run.wait();

    bo_c.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    int errors = 0;
    for (int i = 0; i < N; ++i) {
        if (c[i] != a[i] + b[i]) {
            if (errors < 8)
                std::cout << "  mismatch at " << i << ": got " << c[i]
                          << " expected " << (a[i] + b[i]) << "\n";
            ++errors;
        }
    }

    if (errors == 0) {
        std::cout << "TEST PASSED  (" << N << " elements)\n";
        return EXIT_SUCCESS;
    }
    std::cout << "TEST FAILED  (" << errors << " mismatches)\n";
    return EXIT_FAILURE;
}
