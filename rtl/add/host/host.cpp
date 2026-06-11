// host.cpp -- runs the RTL vadd kernel on the U250 using the native XRT C++ API.
//
// Kernel signature (see scripts/package_kernel.tcl register map):
//     krnl_vadd_rtl(int* a, int* b, int* c, int length)
//     c[i] = a[i] + b[i]   for i in [0, length)
//
// Usage:  ./host <xclbin>
//
// The native XRT API (xrt::device / xrt::kernel / xrt::bo) is the modern,
// minimal way to drive a kernel -- no OpenCL boilerplate. The same pattern
// works for the HLS examples; only the kernel name and argument order change.
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
    const int LENGTH = 4096;                 // number of int elements
    const size_t bytes = sizeof(int) * LENGTH;

    // 1. Open the device (card 0) and load the bitstream.
    unsigned device_index = 0;
    std::cout << "Opening device " << device_index << " ...\n";
    auto device = xrt::device(device_index);
    std::cout << "Loading xclbin: " << xclbin_path << "\n";
    auto uuid = device.load_xclbin(xclbin_path);

    // 2. Get a handle to the kernel inside the xclbin.
    auto krnl = xrt::kernel(device, uuid, "krnl_vadd_rtl");

    // 3. Allocate device buffers bound to the kernel's memory arguments.
    auto bo_a = xrt::bo(device, bytes, krnl.group_id(0));
    auto bo_b = xrt::bo(device, bytes, krnl.group_id(1));
    auto bo_c = xrt::bo(device, bytes, krnl.group_id(2));

    // 4. Fill inputs (map device buffers into host address space).
    auto a_map = bo_a.map<int*>();
    auto b_map = bo_b.map<int*>();
    auto c_map = bo_c.map<int*>();
    for (int i = 0; i < LENGTH; ++i) {
        a_map[i] = i;
        b_map[i] = 2 * i + 1;
        c_map[i] = 0;
    }

    // 5. Push inputs to device memory.
    bo_a.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    bo_b.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    // 6. Launch:  krnl(a, b, c, length)  and wait for completion.
    std::cout << "Launching kernel (length = " << LENGTH << ") ...\n";
    auto run = krnl(bo_a, bo_b, bo_c, LENGTH);
    run.wait();

    // 7. Pull results back and verify against the CPU.
    bo_c.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    int errors = 0;
    for (int i = 0; i < LENGTH; ++i) {
        int expected = a_map[i] + b_map[i];
        if (c_map[i] != expected) {
            if (errors < 8)
                std::cout << "  mismatch at " << i << ": got " << c_map[i]
                          << " expected " << expected << "\n";
            ++errors;
        }
    }

    if (errors == 0) {
        std::cout << "TEST PASSED  (" << LENGTH << " elements)\n";
        return EXIT_SUCCESS;
    }
    std::cout << "TEST FAILED  (" << errors << " mismatches)\n";
    return EXIT_FAILURE;
}
