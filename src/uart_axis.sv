module uart_axis
  #(parameter example_p = 0) // Does nothing, just an example. You may use it, extend it, or ignore it.
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] rx_serial_i
  ,output [0:0] tx_serial_o


  ,output [5:1] led_o // For debugging
  ,output [3:0] an
  ,output [6:0] seg
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


   logic [15:0] prescaleValue;

   
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


   //Send one pixel at a time from uart. No need for an adapter since only sending uint8 grayscaled value for each pixel.

//CONVOLUTION LAYER 1
//---------------------------------------------------------------------------------------------------------------------------------------------
  wire signed [20:0] conv1filter0_W, conv1filter1_w;

  //first layer convolution includes adding bias and relu
   conv1 conv1stlayer
   (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.valid_i(m_axis_uart_tvalid)
    ,.ready_o(m_axis_uart_tready)
    ,.data_i(m_axis_uart_tdata)
    ,.valid_o()
    ,.ready_i()
    ,.data1_o(conv1filter0_W)
    ,.data2_o(conv1filter1_w)
   );

   //Test if elastic pipeline is needed here or just straight to max pool layer


  wire [7:0] conv1requantize0_w, conv1requantize1_w;

  Requantize #(.SCALE_M(180))
  conv1requantize0
  (
  .data_i(conv1filter0_W),
  .data_o(conv1requantize0_w)
  );

  Requantize #(.SCALE_M(180))
  conv1requantize1
  (
  .data_i(conv1filter1_w),
  .data_o(conv1requantize1_w)
  );
  

  
//MAXPOOLING LAYER 1
//---------------------------------------------------------------------------------------------------------------------------------------------
  




//CONVOLUTION LAYER 2
//---------------------------------------------------------------------------------------------------------------------------------------------
  wire signed [20:0] conv2filter0_W, conv2filter1_w, conv2filter2_w;
  conv2 conv2ndlayer
  (
  .clk_i(clk_i),
  .reset_i(reset_i),
  .valid_i(),
  .ready_o(),
  .data1_i(),
  .data2_i(),
  .valid_o(),
  .ready_i(),
  .data1_o(conv2filter0_W),
  .data2_o(conv2filter1_w),
  .data3_o(conv2filter2_w)
  );


  wire [7:0] conv2requantize0_w, conv2requantize1_w,conv2requantize2_w;

  Requantize #(.SCALE_M(104))
  conv2requantize0
  (
  .data_i(conv2filter0_W),
  .data_o(conv2requantize0_w)
  );

  Requantize #(.SCALE_M(104))
  conv2requantize1
  (
  .data_i(conv2filter1_w),
  .data_o(conv2filter1_w)
  );

  Requantize #(.SCALE_M(104))
  conv2requantize2
  (
  .data_i(conv2filter2_w),
  .data_o(conv2requantize2_w)
  );


  
  
//MAXPOOLING LAYER 2
//---------------------------------------------------------------------------------------------------------------------------------------------
  //SIGNALS GO INTO MAX POOLING







//FC LAYER 
//---------------------------------------------------------------------------------------------------------------------------------------------
  //Signals Coming from max pool 2
  wire [3:0] sign_o;
  wire valid_digit;
  flatten_fc finalstep
  (
  .clk_i(clk_i),
  .reset_i(reset_i),
  .data1_i(),
  .data2_i(),
  .data3_i(),
  .ready_o(),
  .valid_i(),
  .sign_o(sign_o),
  .valid_digit(valid_digit)
  );

  hex7seg segment
  (
    .n(sign_o),
    .seg(seg)
  );


  assign an[0] = ~valid_digit; //only display if valid digit
  assign an[3:1] = 3'b111;













   
endmodule