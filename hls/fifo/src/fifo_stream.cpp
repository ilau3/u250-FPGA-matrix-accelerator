// fifo_stream.cpp -- the HLS counterpart to the RTL FIFO.
//
// In HLS you rarely instantiate a FIFO by hand; instead you use hls::stream,
// which the compiler implements as a hardware FIFO. Its natural home is
// between DATAFLOW stages: independent stages run concurrently and pass data
// through the stream, like a producer/consumer pipeline.
//
// Here:
//   stage 1 (producer) streams 'in' from DDR into the FIFO
//   stage 2 (consumer) pops the FIFO, adds 'inc', writes 'out' to DDR
//
//     out[i] = in[i] + inc
//
// The #pragma HLS STREAM depth sets the FIFO depth; #pragma HLS DATAFLOW lets
// the two loops overlap so stage 2 starts consuming while stage 1 is still
// producing -- the whole reason FIFOs exist in dataflow designs.
#include <hls_stream.h>

extern "C" {

static void produce(const int* in, hls::stream<int>& fifo, int size) {
read_loop:
    for (int i = 0; i < size; i++) {
#pragma HLS PIPELINE II = 1
        fifo.write(in[i]);
    }
}

static void consume(hls::stream<int>& fifo, int* out, int inc, int size) {
write_loop:
    for (int i = 0; i < size; i++) {
#pragma HLS PIPELINE II = 1
        out[i] = fifo.read() + inc;
    }
}

void fifo_stream(const int* in, int* out, int inc, int size) {
#pragma HLS INTERFACE m_axi     port = in   bundle = gmem0
#pragma HLS INTERFACE m_axi     port = out  bundle = gmem1
#pragma HLS INTERFACE s_axilite port = in
#pragma HLS INTERFACE s_axilite port = out
#pragma HLS INTERFACE s_axilite port = inc
#pragma HLS INTERFACE s_axilite port = size
#pragma HLS INTERFACE s_axilite port = return

    hls::stream<int> fifo("fifo");
#pragma HLS STREAM variable = fifo depth = 64
#pragma HLS DATAFLOW
    produce(in, fifo, size);
    consume(fifo, out, inc, size);
}

}  // extern "C"
