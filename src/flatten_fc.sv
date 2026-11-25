module flatten_fc
(
  input clk_i,
  input reset_i,
  input [7:0] data1_i,
  input [7:0] data2_i,
  input [7:0] data3_i,
  output logic ready_o,
  input valid_i,
  output logic [3:0] sign_o,
  output logic valid_digit
);

logic [7:0] data_o;

typedef enum logic [1:0] {
    IDLE  = 2'd0,
    ACCUMULATING  = 2'd1,
    MAC = 2'd2
} state_t;

state_t [1:0] state_d,state_q;

logic [7:0] fc_buffer [0:146]; //buffer to hold and organize data by (000000..011111..112222.22)

logic [$clog2(49)-1:0] accum_counter_q, accum_counter_d;
logic [$clog2(294)-1:0] mac_counter_q, mac_counter_d;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    accum_counter_q <= '0;
    mac_counter_q <= '0;
    state_q <= '0;
  end else begin
    if(ready_o & valid_i) begin
      fc_buffer[accum_counter_q]       <= data1_i; // Indices 0..48
      fc_buffer[accum_counter_q + 49]  <= data2_i; // Indices 49..97
      fc_buffer[accum_counter_q + 98]  <= data3_i; // Indices 98..146
    end

    accum_counter_q <= accum_counter_d;
    mac_counter_q <= mac_counter_d;
    state_q <= state_d;
  end
end

logic valid_o_middle;
logic valid_o;

always_comb begin
  valid_o = 0;
  state_d = state_q;
  ready_o = 1;
  valid_o_middle = 0;
  accum_counter_d = accum_counter_q;
  mac_counter_d = mac_counter_q;
  data_o = 0;

  case(state_q)
    IDLE: begin
      if(ready_o & valid_i) begin //first data transmission(should be the first pixel frome each filter)
        accum_counter_d = '0;
        // mac_counter_d = 0;
        state_d = ACCUMULATING;
      end
    end
    ACCUMULATING: begin
      if(accum_counter_q == 49) begin
        mac_counter_d = '0;
        state_d = MAC; //buffer is filled now time for MAC
      end else if(valid_i) begin 
        accum_counter_d = accum_counter_q + 1; // Increment counter!
      end
    end
    MAC: begin
      valid_o_middle = 1;//let consumer know the buffer is complete
      ready_o = 0; //not ready, we are holding the buffer
      //accum_counter_d = '0; // Reset counter for next use
      if(mac_counter_q == 147) begin
        valid_o_middle = 0;
        mac_counter_d = '0;
        valid_o = 1;
        state_d = IDLE;
      end else begin //consumer is ready to take
        mac_counter_d = mac_counter_q + 1; // Increment MAC counter
        data_o = fc_buffer[mac_counter_q];
      end 
      
    end
  endcase
end

wire signed [20:0] mac_accum_out [0:9];

logic signed [7:0] weight0,weight1,weight2,weight3,weight4,weight5,weight6,weight7,weight8,weight9;

ram_2r1w_sync #(
.width_p(8),
.depth_p(294),
.filename_p("fc_weight01.mem"),
.init_p(1)
) WeightRam01
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(mac_counter_d),
.rd_addr2_i(mac_counter_d + 8'd147),
.rd_data1_o(weight0),
.rd_data2_o(weight1)
);

MAC8_21 MAC0 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight0),
.mac_o(mac_accum_out[0])
);

MAC8_21 MAC1 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight1),
.mac_o(mac_accum_out[1])
);


ram_2r1w_sync #(
.width_p(8),
.depth_p(294),
.filename_p("fc_weight23.mem"),
.init_p(1)
) WeightRam23
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(mac_counter_d),
.rd_addr2_i(mac_counter_d + 8'd147),
.rd_data1_o(weight2),
.rd_data2_o(weight3)
);

MAC8_21 MAC2 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight2),
.mac_o(mac_accum_out[2])
);

MAC8_21 MAC3 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight3),
.mac_o(mac_accum_out[3])
);

ram_2r1w_sync #(
.width_p(8),
.depth_p(294),
.filename_p("fc_weight45.mem"),
.init_p(1)
) WeightRam45
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(mac_counter_d),
.rd_addr2_i(mac_counter_d + 8'd147),
.rd_data1_o(weight4),
.rd_data2_o(weight5)
);

MAC8_21 MAC4 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight4),
.mac_o(mac_accum_out[4])
);

MAC8_21 MAC5 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight5),
.mac_o(mac_accum_out[5])
);

ram_2r1w_sync #(
.width_p(8),
.depth_p(294),
.filename_p("fc_weight67.mem"),
.init_p(1)
) WeightRam67
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(mac_counter_d),
.rd_addr2_i(mac_counter_d + 8'd147),
.rd_data1_o(weight6),
.rd_data2_o(weight7)
);

MAC8_21 MAC6 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight6),
.mac_o(mac_accum_out[6])
);

MAC8_21 MAC7 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight7),
.mac_o(mac_accum_out[7])
);

ram_2r1w_sync #(
.width_p(8),
.depth_p(294),
.filename_p("fc_weight89.mem"),
.init_p(1)
) WeightRam89
(
.clk_i(clk_i),
.reset_i(reset_i),
.wr_valid_i(1'b0),
.wr_data_i('0),
.wr_addr_i('0),
.rd_valid1_i(1'b1),
.rd_valid2_i(1'b1),
.rd_addr1_i(mac_counter_d),
.rd_addr2_i(mac_counter_d + 8'd147),
.rd_data1_o(weight8),
.rd_data2_o(weight9)
);

MAC8_21 MAC8 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight8),
.mac_o(mac_accum_out[8])
);

MAC8_21 MAC9 (
.clk_i(clk_i),
.reset_i(reset_i | (state_q == IDLE)), 
.data_i(data_o),
.weight_i(weight9),
.mac_o(mac_accum_out[9])
);

wire [3:0] digit;
Argmax greatPerformace (
  .scores(mac_accum_out),
  .winning_digit(digit)
);

always_ff @(posedge clk_i) begin
  if(reset_i) begin
      sign_o <= 4'b0;
      valid_digit <= 0;
    end else begin
      if(valid_o) begin
        sign_o <= digit;
        valid_digit <= 1;
      end
  end
end




initial begin
  for (int i = 0; i < 147; i++) begin
    $dumpvars(0,fc_buffer[i]);  
  end

end



endmodule