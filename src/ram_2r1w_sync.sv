`ifndef BINPATH
 `define BINPATH "src/weights/"
`endif
module ram_2r1w_sync
  #(parameter [31:0] width_p = 8
  ,parameter [31:0] depth_p = 512
  ,parameter [0:0] init_p = 1
  ,parameter string filename_p = "memory_init_file.bin")
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] wr_valid_i
  ,input [width_p-1:0] wr_data_i
  ,input [$clog2(depth_p) - 1 : 0] wr_addr_i

  ,input [0:0] rd_valid1_i
  ,input [0:0] rd_valid2_i
  ,input [$clog2(depth_p) - 1 : 0] rd_addr1_i
  ,input [$clog2(depth_p) - 1 : 0] rd_addr2_i
  ,output logic [width_p-1:0] rd_data1_o
  ,output logic [width_p-1:0] rd_data2_o);


  logic [width_p-1:0] mem [depth_p];//the mem comp


   initial begin
      // Display depth and width (You will need to match these in your init file)
      $display("%m: depth_p is %d, width_p is %d", depth_p, width_p);
      // wire [bar:0] foo [baz:0];
      if(init_p) begin // if init_p is 1, use readmemh
         $readmemh({`HEXPATH, filename_p},mem , 0, depth_p-1);
      end
      // In order to get the memory contents in iverilog you need to run this for loop during initialization:
      for (int i = 0; i < depth_p; i++) begin
        $dumpvars(0,mem[i]);
        
      end
   end



   always_ff @(posedge clk_i) begin
    if(reset_i) begin
        //rd_data_o <= '0;
    end else begin
        if(rd_valid1_i) begin
            rd_data1_o <= mem[rd_addr1_i];
        end
        if(rd_valid2_i) begin
            rd_data2_o <= mem[rd_addr2_i];
        end

        if(wr_valid_i) begin
            mem[wr_addr_i] <= wr_data_i;
        end
    end
end

endmodule