module conv2
  #(
    // This is the number of pixels in each line of the image
     parameter  linewidth_px_p = 28
    ,parameter width_p = 8)
   (input [0:0] clk_i
    ,input [0:0] reset_i
    ,input [0:0] valid_i
    ,output [0:0] ready_o
    ,input [width_p - 1 : 0] data1_i
    ,input [width_p - 1 : 0] data2_i
    ,output [0:0] valid_o
    ,input [0:0] ready_i
    // Just to make our lives easy, we're going to double the output width.
    ,output [20 : 0] data1_o
    ,output [20 : 0] data2_o
    ,output [20 : 0] data3_o
    );

//*---------------------------------------------------------
// Module Name: conv2
// Designed by: Kailan Bugata
// Description: This module implements the second convlutional layer of the CNN. It takes in a stream of images pixels with each entering data_i at valid_i and ready_o. The module consists of several RAM delay buffers which all connect to a 5x5 sliding window. One data_i first enters the module, a counter starts counting from 0 to 25. For each number in the counter, a specific entry of the slding window and BRAM memory, which is holding the weight data is inputted into a MAC8_16 module. The output of the MAC8_16 module is then inputted into a enable controlled DFF. At ready_i and valid_o, the output of the DFF is then added with the bias and inputted into a ReLU module. The output of the ReLU module is then outputted to data_o. The module will output two data_o signals for both of the filters in this convolution layer. 
//*---------------------------------------------------------

//TODO: Add counter, BRAM logic(figure out if we are doing 1 or 2 BRAMs for the weights), MAC logic, DFF logic, bias addition logic, and ReLU logic. Figure out ready valid logic.

typedef enum logic [0:0] {
    IDLE  = 1'b0,
    COUNTING  = 1'b1
} state_t;

state_t state_d, state_q;

logic [$clog2(18) - 1 : 0] counter_d, counter_q;
//Counter logic for reading from Mem, handling all pixels going thru MAC
always_comb begin
  state_d = state_q;
  counter_d = counter_q;
  case(state_q)
    IDLE: begin
      if(ready_o & valid_i) begin
        counter_d = '0;
        state_d = COUNTING;
      end
    end
    COUNTING: begin
      if(counter_q == 24) begin
        counter_d = '0;
        state_d = IDLE;
      end else begin
        counter_d = counter_q + 1;
      end
    end
  endcase
end

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    state_q <= IDLE;
    counter_q <= '0;
  end else begin
    state_q <= state_d;
    counter_q <= counter_d;
  end
end

//0 and 1 for data1_i, 2 and 3 for data2_i
wire [width_p-1:0] ram0_out, ram1_out, ram2_out, ram3_out;

delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay1
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(counter_q == 8),
.data_i(data1_i),
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
.valid_i(counter_q == 8),
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
.valid_i(counter_q == 8),
.data_i(data2_i),
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
.valid_i(counter_q == 8),
.data_i(ram2_out),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram3_out)
);

//Sliding window construction (treat as a packed array so easier to iterate thru them for MAC)
logic [width_p-1:0] window1_w [8:0];
logic [width_p-1:0] window2_w [8:0];


// Make 18 individual wires
logic [width_p-1:0] window2_8;
logic [width_p-1:0] window2_7;
logic [width_p-1:0] window2_6;
logic [width_p-1:0] window2_5;
logic [width_p-1:0] window2_4;
logic [width_p-1:0] window2_3;
logic [width_p-1:0] window2_2;
logic [width_p-1:0] window2_1;
logic [width_p-1:0] window2_0;

logic [width_p-1:0] window1_8;
logic [width_p-1:0] window1_7;
logic [width_p-1:0] window1_6;
logic [width_p-1:0] window1_5;
logic [width_p-1:0] window1_4;
logic [width_p-1:0] window1_3;
logic [width_p-1:0] window1_2;
logic [width_p-1:0] window1_1;
logic [width_p-1:0] window1_0;

// Connect them to the array
assign window2_0 = window2_w[0];
assign window2_1 = window2_w[1];
assign window2_2 = window2_w[2];
assign window2_3 = window2_w[3];
assign window2_4 = window2_w[4];
assign window2_5 = window2_w[5];
assign window2_6 = window2_w[6];
assign window2_7 = window2_w[7];
assign window2_8 = window2_w[8];

assign window1_0 = window1_w[0];
assign window1_1 = window1_w[1];
assign window1_2 = window1_w[2];
assign window1_3 = window1_w[3];
assign window1_4 = window1_w[4];
assign window1_5 = window1_w[5];
assign window1_6 = window1_w[6];
assign window1_7 = window1_w[7];
assign window1_8 = window1_w[8];


// Five pixels from the "oldest" line.

always_ff @(posedge clk_i) begin
  if(reset_i) begin
  end
  if(valid_i & ready_o) begin //will need the same condition as valid_i in the ram delay buffer

  // Three pixels from the oldest line.
    window2_w[8] <= window2_w[7];
    window2_w[7] <= window2_w[6];
    window2_w[6] <= ram3_out;

  // Three pixels from the next line.
    window2_w[5] <= window2_w[4];
    window2_w[4] <= window2_w[3];
    window2_w[3] <= ram2_out;

  // Three pixels from the "newest" line.
    window2_w[2] <= window2_w[1];
    window2_w[1] <= window2_w[0];
    window2_w[0] <= data2_i;

  
  


  // Three pixels from the oldest line.
    window1_w[8] <= window1_w[7];
    window1_w[7] <= window1_w[6];
    window1_w[6] <= ram1_out;

  // Three pixels from the next line.
    window1_w[5] <= window1_w[4];
    window1_w[4] <= window1_w[3];
    window1_w[3] <= ram0_out;

  // Three pixels from the "newest" line.
    window1_w[2] <= window1_w[1];
    window1_w[1] <= window1_w[0];
    window1_w[0] <= data1_i;
  end
end


logic signed [width_p-1:0] filter0weight1_o, filter0weight2_o, filter1weight1_o, filter1weight2_o, filter2weight1_o, filter2weight2_o ;

//Filter 0
ram_2r1w_sync #(
.width_p(width_p),
.depth_p(18),
.filename_p("conv2_weightF0.mem"),
.init_p(1)
) WeightRam0
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(counter_d),
.rd_addr2_i(counter_d + 5'd9),
.rd_data1_o(filter0weight1_o),
.rd_data2_o(filter0weight2_o)
);

//Filter 1
ram_2r1w_sync #(
.width_p(width_p),
.depth_p(18),
.filename_p("conv2_weightF1.mem"),
.init_p(1)
) WeightRam1
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(counter_d),
.rd_addr2_i(counter_d + 5'd9),
.rd_data1_o(filter1weight1_o),
.rd_data2_o(filter1weight2_o)
);

//Filter 2
ram_2r1w_sync #(
.width_p(width_p),
.depth_p(18),
.filename_p("conv2_weightF2.mem"),
.init_p(1)
) WeightRam2
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(counter_d),
.rd_addr2_i(counter_d + 5'd9),
.rd_data1_o(filter2weight1_o),
.rd_data2_o(filter2weight2_o)
);



assign ready_o = (state_q == IDLE);
assign valid_o = (counter_q == 8);

logic signed [20 : 0] macF01_o, macF02_o, macF11_0,macF12_o,macF21_o,macF22_o;
logic signed [21 : 0] pipelineDFF1_o, pipelineDFF2_o, pipelineDFF3_o;


//Filter 0
MAC8_21 MAC1 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)), 
.data_i(window1_w[counter_q]),
.weight_i(filter0weight1_o),
.mac_o(macF01_o)
);

MAC8_21 MAC2 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)),
.data_i(window2_w[counter_q]),
.weight_i(filter0weight2_o),
.mac_o(macF02_o)
);

//Filter 1
MAC8_21 MAC3 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)), 
.data_i(window1_w[counter_q]),
.weight_i(filter1weight1_o),
.mac_o(macF11_0)
);

MAC8_21 MAC4 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)),
.data_i(window2_w[counter_q]),
.weight_i(filter1weight2_o),
.mac_o(macF12_o)
);


//Filter 2
MAC8_21 MAC5 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)), 
.data_i(window1_w[counter_q]),
.weight_i(filter2weight1_o),
.mac_o(macF21_o)
);

MAC8_21 MAC6 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)),
.data_i(window2_w[counter_q]),
.weight_i(filter2weight2_o),
.mac_o(macF22_o)
);


always_ff @(posedge clk_i) begin
  if(reset_i) begin
    pipelineDFF1_o <= '0;
    pipelineDFF2_o <= '0;
    pipelineDFF3_o <= '0;
  end else if(ready_i & valid_o) begin
    pipelineDFF1_o <= macF01_o + macF02_o;
    pipelineDFF2_o <= macF11_o + macF12_o;
    pipelineDFF3_o <= macF21_o + macF22_o;
  end
end


//for testing purposes, dont use ReLU untl mac and conv1 works (and dont add bias)
assign data1_o = pipelineDFF1_o; // + 20'h00fb
assign data2_o = pipelineDFF2_o + 20'h00b5;
assign data3_o = pipelineDFF3_o + 20'h0081;

// ReLU ReLU1 (
// .data_i(pipelineDFF1_o + 16'h0060), //adding the bias
// .data_o(data1_o)
// );

// ReLU ReLU2 (
// .data_i(pipelineDFF2_o + 16'h007F), //adding the bias
// .data_o(data2_o)
// );

// ReLU ReLU3 (
// .data_i(pipelineDFF2_o + 16'h007F), //adding the bias
// .data_o(data2_o)
// );

endmodule
