`ifndef nn_15_node_defines_vh
// NOTE: for Verilog 1995 `ifndef is not supported use `ifdef macros_vh `else
`define nn_15_node_defines_vh
/**************
* your macros *
* `define ... *
***************/

// bus sizes
`define UINT_8 8 // in bits
`define INT_16 16 // in bits
`define INT_32 32 // in bits

// network dimensions
`define NUM_LAYERS 4 // input + hidden + output

`define INPUT_LAYER_WID 1*16 // 1 INT_16
`define INPUT_LAYER_LEN 257

`define HIDDEN_LAYER_WID 15*16 // 15 INT_16
`define HIDDEN_LAYER_LEN 15 // changed to 15

`define OUTPUT_LAYER_WID 15*16 // 15 INT_16
`define OUTPUT_LAYER_LEN 16

`define RESULT_RD_WID 1*16 // read 1 INT_16
`define RESULT_WD_WID 15*16 // write the whole bus
`define RESULT_LEN 16

// controller
`define MULT_INPUT_CYCLES 256 // one cycle late for sum to update
`define MULT_HIDDEN_CYCLES 15

// misc.
`define NUM_MULTS 15
`define ADR_LEN 10

`endif