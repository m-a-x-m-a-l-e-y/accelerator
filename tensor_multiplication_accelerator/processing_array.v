module processing_array#(
    parameter PE_ROW = 4,
    parameter PE_COL = 4,
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH = 32
)(
    input [PE_ROW* DATA_WIDTH - 1: 0] Matrix_A_Column, // passed through inputs
    input [PE_COL * DATA_WIDTH- 1: 0] Matrix_B_Row,    // passed through weights
    input clk,
    input clear_arr,
    output [PE_COL * PE_ROW]Matrix_C_flat
    
);






endmodule