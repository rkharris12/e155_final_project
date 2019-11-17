`ifndef nn_defines_vh
// NOTE: for Verilog 1995 `ifndef is not supported use `ifdef macros_vh `else
`define nn_defines_vh
/**************
* your macros *
* `define ... *
***************/

`define INT_16 16 // in bits

`define INPUT_LAYER_WID 1*INT_16
`define INPUT_LAYER_LEN 257

`define HIDDEN_LAYER_WID 15*INT_16
`define HIDDEN_LAYER_LEN 16

`define OUTPUT_LAYER_WID 15*INT_16
`define OUTPUT_LAYER_LEN 16

`define RESULT_WID 1*INT_16
`define RESULT_LEN 16

`endif