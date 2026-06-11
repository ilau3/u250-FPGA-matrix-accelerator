// host.cpp -- runs the HLS hls::stream FIFO kernel on the U250 (native XRT).
//
//     fifo_stream(int* in, int* out, int inc, int size)
//     out[i] = in[i] + inc
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
    const int INC = 7;
    const size_t bytes = sizeof(int) * N;

    auto device = xrt::device(0);
    std::cout << "Loading xclbin: " << xclbin_path << "\n";
    auto uuid = device.load_xclbin(xclbin_path);
    auto krnl = xrt::kernel(device, uuid, "fifo_stream");

    auto bo_in  = xrt::bo(device, bytes, krnl.group_id(0));
    auto bo_out = xrt::bo(device, bytes, krnl.group_id(1));

    auto in  = bo_in.map<int*>();
    auto out = bo_out.map<int*>();
    for (int i = 0; i < N; ++i) {
        in[i]  = i * 3 - 5;
        out[i] = 0;
    }
    bo_in.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    std::cout << "Launching kernel (N = " << N << ", inc = " << INC << ") ...\n";
    auto run = krnl(bo_in, bo_out, INC, N);
    run.wait();

    bo_out.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    int errors = 0;
    for (int i = 0; i < N; ++i) {
        if (out[i] != in[i] + INC) {
            if (errors < 8)
                std::cout << "  mismatch at " << i << ": got " << out[i]
                          << " expected " << (in[i] + INC) << "\n";
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
