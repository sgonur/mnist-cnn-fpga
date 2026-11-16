module conv1
  #(
    // This is the number of pixels in each line of the image
     parameter  linewidth_px_p = 28
    ,parameter width_p = 8)
   (input [0:0] clk_i
    ,input [0:0] reset_i
    ,input [0:0] valid_i
    ,output [0:0] ready_o
    ,input [width_p - 1 : 0] data_i
    ,output [0:0] valid_o
    ,input [0:0] ready_i
    // Just to make our lives easy, we're going to double the output width.
    ,output [(2 * width_p) - 1 : 0] data1_o
    ,output [(2 * width_p) - 1 : 0] data2_o
    );

//*---------------------------------------------------------
// Module Name: conv1
// Designed by: Kailan Bugata
// Description: This module implements the first convlutional layer of the CNN. It takes in a stream of images pixels with each entering data_i at valid_i and ready_o. The module consists of several RAM delay buffers which all connect to a 5x5 sliding window. One data_i first enters the module, a counter starts counting from 0 to 25. For each number in the counter, a specific entry of the slding window and BRAM memory, which is holding the weight data is inputted into a MAC8_16 module. The output of the MAC8_16 module is then inputted into a enable controlled DFF. At ready_i and valid_o, the output of the DFF is then added with the bias and inputted into a ReLU module. The output of the ReLU module is then outputted to data_o. The module will output two data_o signals for both of the filters in this convolution layer. 
//*---------------------------------------------------------

//TODO: Add counter, BRAM logic(figure out if we are doing 1 or 2 BRAMs for the weights), MAC logic, DFF logic, bias addition logic, and ReLU logic. Figure out ready valid logic.



// Elastic State Machine Logic
//REPLACE LATER, JUST A PLACEHOLDER FOR NOW!!!!
logic                        valid_r;
wire                         enable_w;
assign enable_w = valid_i & ready_o;

assign ready_o = ~valid_o | ready_i;

always_ff @(posedge clk_i) begin
  if (reset_i) begin
      valid_r <= 1'b0;
  end else if (ready_o) begin
      valid_r <= enable_w;
  end
end
assign valid_o = valid_r;

wire [width_p-1:0] ram0_out, ram1_out, ram2_out, ram3_out;

delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay1
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(enable_w), //valid_i condition will change. We dont want to enable the delay buffer until the MAC is ready to output data. This is because the MAC will output data every 25 cycles and we don't want to fuck up the window.
.data_i(data_i),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram0_out)
);


delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay2
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(enable_w),
.data_i(ram0_out),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram1_out)
);

delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay3
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(enable_w),
.data_i(ram1_out),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram2_out)
);

delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay4
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(enable_w),
.data_i(ram2_out),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram3_out)
);

//Sliding window construction
logic [width_p-1:0] window_w [4:0][4:0];


// Make 25 individual wires
logic [width_p-1:0] window24;
logic [width_p-1:0] window23;
logic [width_p-1:0] window22;
logic [width_p-1:0] window21;
logic [width_p-1:0] window20;

logic [width_p-1:0] window19;
logic [width_p-1:0] window18;
logic [width_p-1:0] window17;
logic [width_p-1:0] window16;
logic [width_p-1:0] window15;

logic [width_p-1:0] window14;
logic [width_p-1:0] window13;
logic [width_p-1:0] window12;
logic [width_p-1:0] window11;
logic [width_p-1:0] window10;

logic [width_p-1:0] window9;
logic [width_p-1:0] window8;
logic [width_p-1:0] window7;
logic [width_p-1:0] window6;
logic [width_p-1:0] window5;

logic [width_p-1:0] window4;
logic [width_p-1:0] window3;
logic [width_p-1:0] window2;
logic [width_p-1:0] window1;
logic [width_p-1:0] window0;

// Connect them to the array
assign window20 = window_w[0][0];
assign window21 = window_w[0][1];
assign window22 = window_w[0][2];
assign window23 = window_w[0][3];
assign window24 = window_w[0][4];

assign window15 = window_w[1][0];
assign window16 = window_w[1][1];
assign window17 = window_w[1][2];
assign window18 = window_w[1][3];
assign window19 = window_w[1][4];

assign window10 = window_w[2][0];
assign window11 = window_w[2][1];
assign window12 = window_w[2][2];
assign window13 = window_w[2][3];
assign window14 = window_w[2][4];

assign window5 = window_w[3][0];
assign window6 = window_w[3][1];
assign window7 = window_w[3][2];
assign window8 = window_w[3][3];
assign window9 = window_w[3][4];

assign window0 = window_w[4][0];
assign window1 = window_w[4][1];
assign window2 = window_w[4][2];
assign window3 = window_w[4][3];
assign window4 = window_w[4][4];


//oldest data
//[0][4] , [0][3], [0][2], [0][1], [0][0]
//[1][4] , [1][3], [1][2], [1][1], [1][0]
//[2][4] , [2][3], [2][2], [2][1], [2][0]
//[3][4] , [3][3], [3][2], [3][1], [3][0]
//[4][4] , [4][3], [4][2], [4][1], [4][0]
//                                 newest data
//window_w is the 5x5 matrix kernel

// Five pixels from the "oldest" line.

always_ff @(posedge clk_i) begin
  if(reset_i) begin
  end
  if(enable_w) begin //will need the same condition as valid_i in the ram delay buffer
    window_w[0][4] <= window_w[0][3];
    window_w[0][3] <= window_w[0][2];
    window_w[0][2] <= window_w[0][1];
    window_w[0][1] <= window_w[0][0];
    window_w[0][0] <= ram4_out;

  // Five pixels from the "middle" line.
    window_w[1][4] <= window_w[1][3];
    window_w[1][3] <= window_w[1][2];
    window_w[1][2] <= window_w[1][1];
    window_w[1][1] <= window_w[1][0];
    window_w[1][0] <= ram3_out;

  // Five pixels from the "newest" line.
    window_w[2][4] <= window_w[2][3];
    window_w[2][3] <= window_w[2][2];
    window_w[2][2] <= window_w[2][1];
    window_w[2][1] <= window_w[2][0];
    window_w[2][0] <= ram2_out;

    window_w[3][4] <= window_w[3][3];
    window_w[3][3] <= window_w[3][2];
    window_w[3][2] <= window_w[3][1];
    window_w[3][1] <= window_w[3][0];
    window_w[3][0] <= ram1_out;

    window_w[4][4] <= window_w[4][3];
    window_w[4][3] <= window_w[4][2];
    window_w[4][2] <= window_w[4][1];
    window_w[4][1] <= window_w[4][0];
    window_w[4][0] <= data_i;
  end
end

endmodule