module delaybuffer
  #(parameter [31:0] width_p = 8
   ,parameter [31:0] delay_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [width_p - 1:0] data_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,output [0:0] valid_o 
  ,output [width_p - 1:0] data_o 
  ,input [0:0] ready_i
  );

  logic [$clog2(delay_p+1)-1:0] wr_ptr, rd_ptr;

  ram_1r1w_sync #(.width_p(width_p), .depth_p(delay_p+1), .filename_p("")) ram_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .wr_valid_i(valid_i & ready_o),
    .wr_data_i(data_i),
    .wr_addr_i(wr_ptr),
    .rd_addr_i(rd_ptr),
    .rd_data_o(data_o),
    .rd_valid_i(valid_i & ready_o)
   );    

  elastic elastic_ramdelay_inst
  (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .valid_o(valid_o),
    .data_o(),
    .ready_i(ready_i)
  );

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      wr_ptr <= delay_p;
      rd_ptr <= '0;
    end else begin
      if (valid_i & ready_o) begin
        if (wr_ptr == delay_p)
          wr_ptr <= 0;
        else
          wr_ptr <= wr_ptr + 1;

        if (rd_ptr == delay_p)
          rd_ptr <= 0;
        else
          rd_ptr <= rd_ptr + 1;
      end
      end
    end
  

endmodule