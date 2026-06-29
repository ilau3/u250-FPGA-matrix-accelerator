extern "C" {

void matmul(
    const int* a,
    const int* b,
    int*       c,
    int        p,
    int        q,
    int        sigma
) {
#pragma HLS INTERFACE m_axi port=a  bundle=gmem0  offset=slave
#pragma HLS INTERFACE m_axi port=b  bundle=gmem1  offset=slave
#pragma HLS INTERFACE m_axi port=c  bundle=gmem2  offset=slave
#pragma HLS INTERFACE s_axilite port=a      bundle=control
#pragma HLS INTERFACE s_axilite port=b      bundle=control
#pragma HLS INTERFACE s_axilite port=c      bundle=control
#pragma HLS INTERFACE s_axilite port=p      bundle=control
#pragma HLS INTERFACE s_axilite port=q      bundle=control
#pragma HLS INTERFACE s_axilite port=sigma  bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control

    int acc[512];
#pragma HLS ARRAY_PARTITION variable=acc cyclic factor=4

    for (int i = 0; i < p; i++) {
        for (int j = 0; j < sigma; j++) {
#pragma HLS PIPELINE II=1
            acc[j] = 0;
        }

        for (int k = 0; k < q; k++) {
#pragma HLS PIPELINE II=1
            int a_ik = a[i * q + k];
            for (int j = 0; j < sigma; j++) {
#pragma HLS UNROLL factor=4
                acc[j] += a_ik * b[k * sigma + j];
            }
        }

        for (int j = 0; j < sigma; j++) {
#pragma HLS PIPELINE II=1
            c[i * sigma + j] = acc[j];
        }
    }
}

}