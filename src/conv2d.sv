module conv2d
  #(
    // This is the number of pixels in each line of the image
     parameter  linewidth_px_p = 28
    // This is the width of each input pixel. You will use 8 for part 2.
    // We will only change it to help with debugging (so that 0 to 4 * 480 can be represented without overflow)
    ,parameter width_p = 8)
   (input [0:0] clk_i
    ,input [0:0] reset_i
    ,input [0:0] valid_i
    ,output [0:0] ready_o
    ,input [width_p - 1 : 0] data_i
    ,output [0:0] valid_o
    ,input [0:0] ready_i
    // Just to make our lives easy, we're going to double the output width.
    ,output [(2 * width_p) - 1 : 0] data_o
    );

   // Elastic State Machine Logic
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

   // This looks like a massive 1-D shift register, and it is.
   // But conceptually, it is implementing a 2-D line buffer:
   
   // 3-register, partial Line 2 <-- Oldest line, being shifted out.
   // Line 1
   // Line 0 <-- Newest line, being shifted in


   //my logic attempt

  logic [$clog2(linewidth_px_p)-1:0] r_cntr_q, r_cntr_d;

  always_comb begin
    r_cntr_d = r_cntr_q;

    if(enable_w) begin
      if(r_cntr_q == (linewidth_px_p-1)) begin
        r_cntr_d = '0;
      end else begin
      r_cntr_d = r_cntr_q+1;
      end
    end
  end


  always_ff @ (posedge clk_i) begin
    if(reset_i) begin
      r_cntr_q <= '0;
    end else begin
      r_cntr_q <= r_cntr_d;
    end
  end


  wire [width_p-1:0] ram0_out, ram1_out;

  delaybuffer #(
   .width_p(width_p),
   .delay_p(linewidth_px_p - 1)
  ) delay1
  (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .valid_i(enable_w),
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

   // Okay, now that the buffer is constructed, let us make the sliding window.
   logic [width_p-1:0] window_w [2:0][2:0];



   // Make 9 individual wires
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
assign window6 = window_w[0][0];
assign window7 = window_w[0][1];
assign window8 = window_w[0][2];

assign window3 = window_w[1][0];
assign window4 = window_w[1][1];
assign window5 = window_w[1][2];

assign window0 = window_w[2][0];
assign window1 = window_w[2][1];
assign window2 = window_w[2][2];



   //[0][2] , [0][1], [0][0]
   //[1][2] , [1][1], [1][0]
   //[2][2] , [2][1], [2][0]
   //window_w is the 3x3 matrix kernel

   // Three pixels from the "oldest" line.

   always_ff @(posedge clk_i) begin
    if(reset_i) begin
      // for(int i = 0; i < 3; i++) begin
      //    for(int j = 0; j < 3; j++) begin
      //       window_w[i][j] <= '0;
      //    end
      // end
    end
    if(enable_w) begin
      window_w[0][2] <= window_w[0][1];
      window_w[0][1] <= window_w[0][0];
      window_w[0][0] <= ram1_out;

    // Three pixels from the "middle" line.
      window_w[1][2] <= window_w[1][1];
      window_w[1][1] <= window_w[1][0];
      window_w[1][0] <= ram0_out;

    // Three pixels from the "newest" line.
      window_w[2][2] <= window_w[2][1];
      window_w[2][1] <= window_w[2][0];
      window_w[2][0] <= data_i;
    end
   end
    


   // For the purposes of this module, add them all together.
   assign data_o = '0 + (window_w[2][2] + window_w[2][1] + window_w[2][0]) +
                   (window_w[1][2] + window_w[1][1] + window_w[1][0]) +
                   (window_w[0][2] + window_w[0][1] + window_w[0][0]);
endmodule