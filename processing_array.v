module processing_array#(
    parameter PE_ROW = 4,
    parameter PE_COL = 4,
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH = 32
)(
    input [PE_ROW* DATA_WIDTH - 1: 0] Matrix_A_Column, // passed through inputs
    input [PE_COL * DATA_WIDTH- 1: 0] Matrix_B_Row,    // passed through weights
    input clk, // just a clock
    input set_to_zero, // used as a signal to reset array element sums to 0s
    output [(PE_COL * PE_ROW)* SUM_WIDTH - 1: 0] Matrix_C_flat // This is the answer matrix, or at least a part of the answer matrix, as if the input matrices are bigger than 4x4 x 32bit, they will need to be done in parts
    
);


// Pseudo code:
// at every clock posedge, inputs should be loaded from the appropriate column in matrix A to the leftmost processing elements input 
// Additionally, at every clock posedge, pass weights (inputs from matrix B) into the weights input of the top most processing elements of the array
// 
// Handling which elements go where : 
// matrix A inputs should be handled as columns, so column 0 == inputs of PE array leftside, and each clock tick increments by 1
// While the previously described logic could be done here, instead the only logic that will be handled here is passing the inputs to the correct
// locations. Changing the inputs will be handled in the top level module accelerator, which will change on clock to the next up inputs from matrix A and matrix B



// Wire 2d grid

wire [(PE_ROW * PE_COL)*DATA_WIDTH - 1 : 0] positional_matrix_flat; // represents the size of the PE matrix so routing can be done though it
wire [(PE_ROW * PE_COL)* SUM_WIDTH - 1 : 0] sum_matrix_flat; // represents the size of the PE matrix so routing can be done though it


wire [(PE_ROW * PE_COL)* DATA_WIDTH - 1 : 0] input_out_matrix_flat; // represents the size of the PE matrix so routing can be done though it
wire [(PE_ROW * PE_COL)* DATA_WIDTH - 1 : 0] weight_out_matrix_flat; // represents the size of the PE matrix so routing can be done though it
wire [(PE_ROW * DATA_WIDTH) - 1               : 0] temp_holding_right;
wire [(PE_COL * DATA_WIDTH) - 1               : 0] temp_holding_bottom;

// Construct array of processing elements:
genvar i;
genvar j;
generate
    for( i = 0; i < PE_ROW; i++) begin : PE_ARRAY_ROW
        for( j = 0; j < PE_COL; j++) begin : PE_ARRAY_COL
            // this_index = (PE_COL * i) + j
            localparam this_element = (PE_COL * i) + j; // multiply by 8 to get index in out matrices
            localparam left_element = (PE_COL * i) + j - 1;
            localparam top_element = (PE_COL * i) + j - PE_COL;    

            wire [7:0] pe_input_out; 
            wire [7:0] pe_weight_out; 

            processing_element piece(  .input_in(j == 0 ? Matrix_A_Column[DATA_WIDTH*i +: DATA_WIDTH] : input_out_matrix_flat[DATA_WIDTH * left_element +: DATA_WIDTH]),
                                        .weight_in(i == 0 ? Matrix_B_Row[DATA_WIDTH*j +: DATA_WIDTH] : weight_out_matrix_flat[DATA_WIDTH * top_element +: DATA_WIDTH]),
                                        .input_out(pe_input_out), 
                                        .weight_out(pe_weight_out), 
                                        .sum(sum_matrix_flat[ ((PE_COL * i) + j)*SUM_WIDTH +: SUM_WIDTH]),
                                        .clk(clk),
                                        .set_to_zero(set_to_zero)
                                    );
            // Garbage pile : 
            // {{(SUM_WIDTH - 2*DATA_WIDTH){1'b0}},

            // pe_input_out and pe_weight out above are currently not wired to anything, so this if block says which 
            // wires these temp connections actually connect to
            // This is needed because outputs can't be assigned to ternary operations 

            if (j == (PE_COL - 1))  begin : handle_pe_input_out
                assign temp_holding_right[i * DATA_WIDTH +: DATA_WIDTH] = pe_input_out;
            end else begin 
                assign input_out_matrix_flat[this_element * DATA_WIDTH +: DATA_WIDTH] = pe_input_out;
            end
            if (i == (PE_ROW - 1))  begin : handle_pe_weight_out
                assign temp_holding_bottom[j * DATA_WIDTH +: DATA_WIDTH] = pe_weight_out;
            end else begin
                assign weight_out_matrix_flat[this_element * DATA_WIDTH +: DATA_WIDTH] = pe_weight_out;
            end    
        
        end 
    end
endgenerate

assign Matrix_C_flat = sum_matrix_flat;

// Logic handling:
always @(posedge clk) begin
    // need to drive input_in and weight_in with non blacking assignments to work with the reg variables in procesing_element

end




endmodule