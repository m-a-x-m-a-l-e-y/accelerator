module processor_element(
    input [7:0] input_val,
    input [7:0] weight,
    output [31:0] sum ,
    output [7:0] input_right, 
    output [7:0] weight_down
);
    // Notes : 
    // sum is a 32 bit integer, inputs are 8 bits
    // this is because 8bit X 8bit multiplication is the best for fitting on DSP slices and the goal of this 
    // accelerator is for ML related Matrix multiplication
    // 
    wire [15:0] product;

    assign product = (input_val * weight);
    
    always @ (posedge clk) begin
        sum <= sum + product
    end  


endmodule