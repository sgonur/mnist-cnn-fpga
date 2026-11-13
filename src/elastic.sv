module elastic
  #(parameter [31:0] width_p = 8
     /* verilator lint_off WIDTHTRUNC */
   ,parameter [0:0] datapath_gate_p = 0
   ,parameter [0:0] datapath_reset_p = 0
    /* verilator lint_on WIDTHTRUNC */
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

  logic [width_p - 1:0] data_o_reg;
  //data o
  always_ff @(posedge clk_i) begin
    if (datapath_reset_p & reset_i) begin
      data_o_reg <= 0;
    end else if (ready_o) begin
      data_o_reg <= data_i;
    end
  end

  logic [0:0] valid_o_reg;
  //valid o
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_o_reg <= 0;
    end else if (ready_o) begin
      valid_o_reg <= ready_o & valid_i;
    end
  end

  assign ready_o = ~valid_o | ready_i;
  assign valid_o = valid_o_reg;
  assign data_o = data_o_reg;



endmodule