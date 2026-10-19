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

reg reset = 1'b1;
reg [7:0] row_index = 0; // arbitrary length for now but 128x128 should be a good matrix maximum size to start with.
reg [7:0] column_index = 0;



// Loop that updates inputs & weights =================
// Looping over the columns in matrix A and the rows in matrix B 
// Right now this only is built to work for matrices the same size or smaller compared to PE array
always @ (posedge clk) begin
    if(reset) begin 
        row_index <= 0;
        column_index <= 0;
        reset <= 0; // Is this where reset should be set to 0 ??
    end
    else begin 
        row_index <= row_index + 1;
        column_index <= column_index + 1;
    end
end
// ===================================================

// IN-RANGE VARIABLE : [used to check A & B] =========
wire in_range;
assign in_range = column_index < MTRXA_COL; 
// ===================================================

// Build Matrix A Input Column =======================
// have to use generate to make an array of all of the 'column index' items from each row
wire [DATA_WIDTH*MTRXA_ROW - 1:0] Matrix_A_Column;
genvar i;
generate
    for(i = 0; i < MTRXA_ROW; i++) begin 
        // in_range checks if we are out of bounds or not, note that because column_index == row_index (just used for readability purposes at this point) we only need one variable that is column_index < MTRXA_COL
        assign Matrix_A_Column[DATA_WIDTH*i +: DATA_WIDTH] = in_range ? Matrix_A[DATA_WIDTH*(MTRXA_COL*i + column_index) +: DATA_WIDTH] : {DATA_WIDTH{1'b0}}; // +: Data width so only need to determine starting index
    end
endgenerate
// ===================================================

// Build Matrix B Input Row ==========================
 // Learn why +: works but [:] doesn't ; [:] causes non-constant ? 
wire [DATA_WIDTH*MTRXB_COL - 1:0] Matrix_B_Row;
assign Matrix_B_Row = in_range ? Matrix_B[row_index*MTRXB_COL*DATA_WIDTH +: DATA_WIDTH*MTRXB_COL] : {DATA_WIDTH*MTRXB_COL{1'b0}};
// ===================================================



// Offset Matrix_A_Column and Matrix_B_Row
// The rows and columns of these need to be staggered based on the current cycle
//
wire [DATA_WIDTH*MTRXB_COL - 1:0] Matrix_B_Row_Offset;
wire [DATA_WIDTH*MTRXA_ROW - 1:0] Matrix_A_Column_Offset;

genvar I;
generate
// MTRXA
// Generate offset arrays for inputs
for(I= 0; I < MTRXA_ROW; I++) begin
    if (I == 0) begin
        // first index doesn't need an offset for its array
        assign Matrix_A_Column_Offset[0 +: DATA_WIDTH] = Matrix_A_Column[0 +: DATA_WIDTH];
    end
    else begin : delay_handling_A
        // the way this part works is basically for each index (I), create an offset array of size I*DATA_WIDTH which serves as a delay gate into entering the Processing Element array.
        // on every clock cycle, every item in an offset array should be shifted towards zero, and  Matrix_A_Column_Offset['i'] = offset_array_i[0] (where offset_array_i is the array of size i (i is any I) )
        
        reg [I*DATA_WIDTH -1 : 0] offset_array;
        integer position; // position == position in offset array


        always @(posedge clk) begin 
            if(reset) begin
                // reset the whole vector 
                offset_array <= {I*DATA_WIDTH{1'b0}};
            end
            else begin
                //  shift array elements leftwards(towards offset[0]) 
                for (position = 0; position < (I) - 1; position++) begin 
                    offset_array[position*DATA_WIDTH +: DATA_WIDTH] <= offset_array[DATA_WIDTH*(position + 1) +: DATA_WIDTH];
                end
                offset_array[(I - 1)*DATA_WIDTH +: DATA_WIDTH] <= Matrix_A_Column[I * DATA_WIDTH  +: DATA_WIDTH];
            end
        end

        assign Matrix_A_Column_Offset[I * DATA_WIDTH +: DATA_WIDTH] = offset_array[0 +: DATA_WIDTH];
    end
end
/// Matrix_B_Row_Offset assignment
for(I= 0; I < MTRXB_COL; I++) begin
    if (I == 0) begin
        // first index doesn't need an offset for its array
        assign Matrix_B_Row_Offset[0 +: DATA_WIDTH] = Matrix_B_Row[0 +: DATA_WIDTH];
    end
    else begin : delay_handling_B
        // the way this part works is basically for each index (I), create an offset array of size I*DATA_WIDTH which serves as a delay gate into entering the Processing Element array.
        // on every clock cycle, every item in an offset array should be shifted towards zero, and  Matrix_A_Column_Offset['i'] = offset_array_i[0] (where offset_array_i is the array of size i (i is any I) )
        
        reg [I*DATA_WIDTH -1 : 0] offset_array;
        integer position; // position == position in offset array


        always @(posedge clk) begin 
            if(reset) begin
                // reset the whole vector 
                offset_array <= {I*DATA_WIDTH{1'b0}};
            end
            else begin
                //  shift array elements leftwards(towards offset[0]) 
                for (position = 0; position < (I) - 1; position++) begin 
                    offset_array[position*DATA_WIDTH +: DATA_WIDTH] <= offset_array[DATA_WIDTH*(position + 1) +: DATA_WIDTH];
                end
                offset_array[(I - 1)*DATA_WIDTH +: DATA_WIDTH] <= Matrix_B_Row[I * DATA_WIDTH  +: DATA_WIDTH];
            end
        end

        assign Matrix_B_Row_Offset[I * DATA_WIDTH +: DATA_WIDTH] = offset_array[0 +: DATA_WIDTH];
    end
end



endgenerate




// Build Array of Processing Elements ================
processing_array pe_arr(.Matrix_A_Column(Matrix_A_Column_Offset), .Matrix_B_Row(Matrix_B_Row_Offset), .clk(clk), .set_to_zero(reset), .Matrix_C_flat(result));
// ===================================================

endmodule