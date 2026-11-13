module uart_axis
  #(parameter example_p = 0) // Does nothing, just an example. You may use it, extend it, or ignore it.
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] rx_serial_i
  ,output [0:0] tx_serial_o


  ,output [5:1] led_o // For debugging
   );

   localparam [31:0] data_width_lp = 8; // Keep this constant. Treat UART as an 8-bit bus, output.

   // In my soltion, these wires are data coming from (tx), and going
   // to (rx) the UART module. You may pick your own alternate naming
   // scheme.
   wire [data_width_lp-1:0] m_axis_uart_tdata;
   wire       m_axis_uart_tvalid;
   wire       m_axis_uart_tready;

   wire [data_width_lp-1:0] s_axis_uart_tdata;
   wire       s_axis_uart_tvalid;
   wire       s_axis_uart_tready;

   // Expanded data, coming out of the adapter
   wire [31:0] m_axis_tdata;
   wire        m_axis_tvalid;
   wire [3:0]  m_axis_tkeep;
   wire        m_axis_tready;
   
   // Expanded data, going back into the adapter
   wire [31:0] s_axis_tdata;
   wire        s_axis_tvalid;
   wire [3:0]  s_axis_tkeep;
   wire        s_axis_tready;

   // Your code here

   // You'll probably want to reuse your Lab 7 code.

   logic [15:0] prescaleValue;

   // Your code here
    uart
   #(.DATA_WIDTH(data_width_lp))
   uarto
   (
    .clk(clk_i),
    .rst(reset_i),
    .s_axis_tdata(s_axis_uart_tdata),   //in
    .s_axis_tvalid(s_axis_uart_tvalid), //in
    .s_axis_tready(s_axis_uart_tready), //out

    .m_axis_tdata(m_axis_uart_tdata),   //out
    .m_axis_tvalid(m_axis_uart_tvalid), //out
    .m_axis_tready(m_axis_uart_tready), //in
    .rxd(rx_serial_i),
    .txd(tx_serial_o),
    .prescale(prescaleValue)
   );
   assign prescaleValue = (25000000)/(115200*8);
   
endmodule