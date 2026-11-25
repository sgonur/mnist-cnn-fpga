module conv1
  #(
    // This is the number of pixels in each line of the image
     parameter  linewidth_px_p = 28
    ,parameter width_p = 8)
   ( input [0:0] clk_i
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

typedef enum logic [0:0] {
    IDLE  = 1'b0,
    COUNTING  = 1'b1
} state_t;

state_t state_d, state_q;

logic [$clog2(50) - 1 : 0] counter_d, counter_q;
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

wire [width_p-1:0] ram0_out, ram1_out, ram2_out, ram3_out;

delaybuffer #(
.width_p(width_p),
.delay_p(linewidth_px_p - 1)
) delay1
(
.clk_i(clk_i),
.reset_i(reset_i),
.valid_i(counter_q == 24),
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
.valid_i(counter_q == 24),
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
.valid_i(counter_q == 24),
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
.valid_i(counter_q == 24),
.data_i(ram2_out),
.ready_i(1'b1),
.ready_o(),
.valid_o(),
.data_o(ram3_out)
);

//Sliding window construction (treat as a packed array so easier to iterate thru them for MAC)
logic [width_p-1:0] window_w [24:0];


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
assign window20 = window_w[20];
assign window21 = window_w[21];
assign window22 = window_w[22];
assign window23 = window_w[23];
assign window24 = window_w[24];

assign window15 = window_w[15];
assign window16 = window_w[16];
assign window17 = window_w[17];
assign window18 = window_w[18];
assign window19 = window_w[19];

assign window10 = window_w[10];
assign window11 = window_w[11];
assign window12 = window_w[12];
assign window13 = window_w[13];
assign window14 = window_w[14];

assign window5 = window_w[5];
assign window6 = window_w[6];
assign window7 = window_w[7];
assign window8 = window_w[8];
assign window9 = window_w[9];

assign window0 = window_w[0];
assign window1 = window_w[1];
assign window2 = window_w[2];
assign window3 = window_w[3];
assign window4 = window_w[4];



// Five pixels from the "oldest" line.

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    for(int i = 0; i < 25; i++) begin
      window_w[i] <= '0;
    end
  end
  if(valid_i & ready_o) begin //will need the same condition as valid_i in the ram delay buffer

  // Five pixels from the oldest line.
    window_w[24] <= window_w[23];
    window_w[23] <= window_w[22];
    window_w[22] <= window_w[21];
    window_w[21] <= window_w[20];
    window_w[20] <= ram3_out;

  // Five pixels from the next line.
    window_w[19] <= window_w[18];
    window_w[18] <= window_w[17];
    window_w[17] <= window_w[16];
    window_w[16] <= window_w[15];
    window_w[15] <= ram2_out;

    window_w[14] <= window_w[13];
    window_w[13] <= window_w[12];
    window_w[12] <= window_w[11];
    window_w[11] <= window_w[10];
    window_w[10] <= ram1_out;

    window_w[9] <= window_w[8];
    window_w[8] <= window_w[7];
    window_w[7] <= window_w[6];
    window_w[6] <= window_w[5];
    window_w[5] <= ram0_out;

  // Five pixels from the "newest" line.
    window_w[4] <= window_w[3];
    window_w[3] <= window_w[2];
    window_w[2] <= window_w[1];
    window_w[1] <= window_w[0];
    window_w[0] <= data_i;
  end
end


logic signed [width_p-1:0] filterweight1_o, filterweight2_o;

//dual read port RAM
ram_2r1w_sync #(
.width_p(width_p),
.depth_p(50),
.filename_p("conv1_weight.mem"),
.init_p(1)
) WeightRam
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(counter_q),
.rd_addr2_i(counter_q + 5'd25),
.rd_data1_o(filterweight1_o),
.rd_data2_o(filterweight2_o)
);



assign ready_o = (state_q == IDLE);
assign valid_o = (counter_q == 24);

logic signed [(2 * width_p) - 1 : 0] mac1_o, mac2_o;
logic signed [(2 * width_p) - 1 : 0] pipelineDFF1_o, pipelineDFF2_o;

MAC8_16 MAC1 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)), 
.data_i(window_w[counter_q]),
.weight_i(filterweight1_o),
.mac_o(mac1_o)
);

MAC8_16 MAC2 (
.clk_i(clk_i),
.reset_i(reset_i | (ready_o & valid_i)),
.data_i(window_w[counter_q]),
.weight_i(filterweight2_o),
.mac_o(mac2_o)
);

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    pipelineDFF1_o <= '0;
    pipelineDFF2_o <= '0;
  end else if(ready_i & valid_o) begin
    pipelineDFF1_o <= mac1_o;
    pipelineDFF2_o <= mac2_o;
  end
end

ReLU ReLU1 (
.data_i(pipelineDFF1_o + 16'h0060), //adding the bias
.data_o(data1_o)
);

ReLU ReLU2 (
.data_i(pipelineDFF2_o + 16'h007F), //adding the bias
.data_o(data2_o)
);

endmodule
