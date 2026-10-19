
`timescale 1ns/1ns

module accelerator_tb#(    
    parameter MTRXA_COL = 4,
    parameter MTRXA_ROW = 4,
    parameter MTRXB_COL = 4,
    parameter MTRXB_ROW = 4,
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH= 32,
    parameter NUM_CYCLES = 20)  // 
();

    reg [(MTRXA_ROW * MTRXA_COL * DATA_WIDTH) - 1 : 0] Matrix_A;
    reg [(MTRXB_COL * MTRXB_ROW * DATA_WIDTH) - 1 : 0] Matrix_B;
    wire [(MTRXA_ROW * MTRXB_COL)*SUM_WIDTH - 1: 0]     Matrix_C; // aka result as of first accelerator version
    reg clk = 0;

    accelerator a (.Matrix_A(Matrix_A), .Matrix_B(Matrix_B), .result(Matrix_C), .clk(clk));


    always #1 clk = ~clk;


    integer i, j, cycle;

    // Print the result matrix (assumes row-major packing, element 0 in the LSBs)
    task print_C;
        begin
            for (i = 0; i < MTRXA_ROW; i = i + 1) begin
                for (j = 0; j < MTRXB_COL; j = j + 1)
                    $write("%8d ", Matrix_C[(i*MTRXB_COL + j)*SUM_WIDTH +: SUM_WIDTH]);
                $write("\n");
            end
        end
    endtask

    initial begin
        // Fill A and B (example: A[k] = k+1, B = identity)
        

        // Case 0.0 A x Identity => Identity
        // Matrix_A = {
        //     8'd16, 8'd15, 8'd14, 8'd13,   // row 3
        //     8'd12, 8'd11, 8'd10, 8'd9,    // row 2
        //     8'd8,  8'd7,  8'd6,  8'd5,    // row 1
        //     8'd4,  8'd3,  8'd2,  8'd1     // row 0
        // };
        // Matrix_B = {
        //     8'd1, 8'd0, 8'd0, 8'd0,       // row 3
        //     8'd0, 8'd1, 8'd0, 8'd0,       // row 2
        //     8'd0, 8'd0, 8'd1, 8'd0,       // row 1
        //     8'd0, 8'd0, 8'd0, 8'd1        // row 0
        // };

        // Case 0.1 I X B
        // Matrix_A = {
        //     8'd1, 8'd0, 8'd0, 8'd0,
        //     8'd0, 8'd1, 8'd0, 8'd0,
        //     8'd0, 8'd0, 8'd1, 8'd0,
        //     8'd0, 8'd0, 8'd0, 8'd1
        // };
        // Matrix_B = {
        //     8'd16, 8'd15, 8'd14, 8'd13,
        //     8'd12, 8'd11, 8'd10, 8'd9,
        //     8'd8,  8'd7,  8'd6,  8'd5,
        //     8'd4,  8'd3,  8'd2,  8'd1
        // };

        // Case 0.2 A X B
        // Matrix_A = {
        //     8'd16, 8'd15, 8'd14, 8'd13,
        //     8'd12, 8'd11, 8'd10, 8'd9,
        //     8'd8,  8'd7,  8'd6,  8'd5,
        //     8'd4,  8'd3,  8'd2,  8'd1
        // };
        // Matrix_B = {
        //     8'd1, 8'd0, 8'd0, 8'd0,       // row 3: only col 3
        //     8'd1, 8'd1, 8'd0, 8'd0,       // row 2: cols 2-3
        //     8'd1, 8'd1, 8'd1, 8'd0,       // row 1: cols 1-3
        //     8'd1, 8'd1, 8'd1, 8'd1        // row 0: all cols
        // };

        // Case 0.3 A X A
        Matrix_A = {
            8'd16, 8'd15, 8'd14, 8'd13,
            8'd12, 8'd11, 8'd10, 8'd9,
            8'd8,  8'd7,  8'd6,  8'd5,
            8'd4,  8'd3,  8'd2,  8'd1
        };
        Matrix_B = Matrix_A;


        // Hold reset for two cycles
        repeat (2) @(posedge clk);
        // rst = 0;

        // Dump C after every clock edge
        for (cycle = 0; cycle < NUM_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            #1;  // let nonblocking assignments settle before sampling
            $display("---- cycle %0d (t=%0t) ----", cycle, $time);
            print_C;
        end

        $finish;
    end

    // Optional: waveform dump for GTKWave
    initial begin
        
        $dumpvars(0, accelerator_tb);
    end



endmodule