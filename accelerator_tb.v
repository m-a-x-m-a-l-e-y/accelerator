
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
        for (i = 0; i < MTRXA_ROW*MTRXA_COL; i = i + 1)
            Matrix_A[i*DATA_WIDTH +: DATA_WIDTH] = i + 1;
        for (i = 0; i < MTRXB_ROW; i = i + 1)
            for (j = 0; j < MTRXB_COL; j = j + 1)
                Matrix_B[(i*MTRXB_COL + j)*DATA_WIDTH +: DATA_WIDTH] = (i == j);

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