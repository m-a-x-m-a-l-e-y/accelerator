module processing_element#(
    parameter SUM_WIDTH = 32,
    parameter DATA_WIDTH = 8
)(
    input [7:0] input_in,
    input [7:0] weight_in,
    input clk,
    input set_to_zero,
    output reg [31:0] sum ,
    output reg [7:0] input_out, 
    output reg [7:0] weight_out
);
    // Notes : 
    // - sum is a 32 bit integer, inputs are 8 bits
    // this is because 8bit X 8bit multiplication is the best for fitting on DSP slices and the goal of this 
    // accelerator is for ML related Matrix multiplication
    // - input_in and weight_in are assigned in the processing array module on clock posedge
    wire [15:0] product;

    assign product = (input_in * weight_in);
    always @ (posedge clk) begin
        if(set_to_zero) begin
            sum <= 0;
            input_out <= 0;
            weight_out <= 0;

        end
        else begin
            sum <= sum +  {{(SUM_WIDTH - 2*DATA_WIDTH){1'b0}}, product}; // Sign extends product explicitly
            input_out <= input_in;
            weight_out <= weight_in;
        end
    end  

endmodule