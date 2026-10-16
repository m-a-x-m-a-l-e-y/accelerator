module accelerator#(
    parameter MTRXA_COL = 4,
    parameter MTRXA_ROW = 4,
    parameter MTRXB_COL = 4,
    parameter MTRXB_ROW = 4,
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH= 32
)(
    
    input [(MTRXA_ROW * MTRXA_COL * DATA_WIDTH) - 1 : 0] Matrix_A,
    input [(MTRXB_ROW * MTRXB_COL * DATA_WIDTH) - 1 : 0] Matrix_B,
    input clk,
    output [(MTRXA_ROW * MTRXB_COL)*SUM_WIDTH - 1: 0] result // Certain matrix sizes will break under this, right now only works with 4x4 x 4x4 => 4x4 result
);

wire reset;

reg [7:0] row_index = 0; // arbitrary length for now but 128x128 should be a good matrix maximum size to start with.
reg [7:0] column_index = 0;

// Loop that updates inputs & weights =================
// Looping over the columns in matrix A and the rows in matrix B 
// Right now this only is built to work for matrices the same size or smaller compared to PE array
always @ (posedge clk) begin
    if(reset) begin 
        row_index <= 0;
        column_index <= 0;
    end
    else begin 
        row_index <= row_index + 1;
        column_index <= column_index + 1;
    end
end
// ===================================================


// Build Matrix A Input Column =======================
// have to use generate to make an array of all of the 'column index' items from each row
wire [8*MTRXA_ROW - 1:0] Matrix_A_Column;
genvar i;
generate
    for(i = 0; i < MTRXA_ROW; i++) begin 
        //DATA_WIDTH*((i + 1)*MTRXA_COL - 1): DATA_WIDTH*(i*MTRXA_COL)
        assign Matrix_A_Column[DATA_WIDTH*i +: DATA_WIDTH] = Matrix_A[DATA_WIDTH*(MTRXA_COL*i + column_index) +: DATA_WIDTH]; // +: Data width so only need to determine starting index
    end
endgenerate
// ===================================================

// Build Matrix B Input Row ==========================
 // Learn why +: works but [:] doesn't ; [:] causes non-constant ? 
wire [8*MTRXB_COL - 1:0] Matrix_B_Row;
assign Matrix_B_Row = Matrix_B[row_index*DATA_WIDTH +: DATA_WIDTH*MTRXB_COL];
// ===================================================

// Build Array of Processing Elements ================
processing_array pe_arr(.Matrix_A_Column(Matrix_A_Column), .Matrix_B_Row(Matrix_B_Row), .clk(clk), .set_to_zero(reset), .Matrix_C_flat(result));
// ===================================================

endmodule