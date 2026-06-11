// vadd.cpp -- the same vector add as the RTL example, but described in C++ and
// turned into hardware by the Vitis HLS compiler instead of by hand.
//
//     c[i] = a[i] + b[i]   for i in [0, size)
//
// The INTERFACE pragmas tell HLS how the function arguments map onto AXI ports:
//   - the pointers a/b/c become an AXI master (m_axi) that reads/writes the
//     card's DDR ("gmem")
//   - the scalar 'size' and the control handshake travel over the AXI4-Lite
//     slave (s_axilite), exactly like the RTL kernel's control block
//
// Compare this file with rtl/add/src/hdl/*.sv: HLS generates all of that AXI
// machinery for you from this loop.
extern "C" {

void vadd(const int* a, const int* b, int* c, int size) {
#pragma HLS INTERFACE m_axi     port = a    bundle = gmem0
#pragma HLS INTERFACE m_axi     port = b    bundle = gmem1
#pragma HLS INTERFACE m_axi     port = c    bundle = gmem0
#pragma HLS INTERFACE s_axilite port = a
#pragma HLS INTERFACE s_axilite port = b
#pragma HLS INTERFACE s_axilite port = c
#pragma HLS INTERFACE s_axilite port = size
#pragma HLS INTERFACE s_axilite port = return

    for (int i = 0; i < size; i++) {
#pragma HLS PIPELINE II = 1
        c[i] = a[i] + b[i];
    }
}

}  // extern "C"
