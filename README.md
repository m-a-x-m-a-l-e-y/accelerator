This is my FPGA Matrix Multiplication Accelerator

The structure is a top module which controls an array of processor elements. 

Processing Element : 
- Each of these processing elements take an input and weight ( Values from both matrices )
- They also output these input and weights to the next respective processing elements.
- The processing element multiplies the input_in and the weight_in and adds that product to the running sum, this sum stays in the processing element through the multiplication


Characteristics : 
 - Output stationary
 - systolic
