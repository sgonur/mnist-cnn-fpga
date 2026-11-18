"""conv1: First layer convolution with 5x5 sliding window over a stream of image pixels. 
After ready_o and valid_i are asserted, module should take 25 cycles before valid_o is asserted. The output is two streams of pixels from each filter that should come out parallel. The output is valid for 1 cycle and then the module should wait for the next valid_i to be asserted. The module should also assert ready_o when it is ready to accept new input pixels. After pipeline stage, will be added with bias and sent through ReLU activation function. The output will be sent to the next layer of the CNN.
"""

import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset, to_signed
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, with_timeout, First
from cocotb.types import LogicArray, Range

SOURCES = ["conv1.sv", "delaybuffer.sv", "elastic.sv", "ram_1r1w_sync.sv", "ReLU.sv","MAC8_16.sv","ram_2r1w_sync.sv"]



@cocotb.test()
async def test_conv1_readyvalid(dut):
    """Test conv1 with random input data and check output against expected results."""
    clk_i = dut.clk_i
    reset_i = dut.reset_i

    await start_clock_and_reset(dut)

    await FallingEdge(reset_i)
    await FallingEdge(clk_i)
    dut.ready_i.value = 1

    # Wait for all ramdelay buffers and windows to be filled with zeros(due to icarus X's)
    for i in range(120):
      dut.data_i.value = 0
      dut.valid_i.value = 1
      await RisingEdge(clk_i)
      dut.valid_i.value = 0
      await with_timeout(RisingEdge(dut.valid_o), 1000, 'ns')
      await RisingEdge(clk_i)


    for i in range(28*28):
      dut.data_i.value = random.randint(0, 255)
      mac_sum = 0
      dut.valid_i.value = 1
      await RisingEdge(clk_i)
      dut.valid_i.value = 0
      await RisingEdge(dut.valid_o)
      await RisingEdge(clk_i)
      await Timer(100, unit="ps") #for good measure


      #reference MAC calculation for filter1
      mac_sum += int(dut.window0.value) * to_signed(0x96, 8)
      mac_sum += int(dut.window1.value) * to_signed(0x90, 8)
      mac_sum += int(dut.window2.value) * to_signed(0x97, 8)
      mac_sum += int(dut.window3.value) * to_signed(0xab, 8)
      mac_sum += int(dut.window4.value) * to_signed(0x12, 8)
      mac_sum += int(dut.window5.value) * to_signed(0xf3, 8)
      mac_sum += int(dut.window6.value) * to_signed(0xde, 8)
      mac_sum += int(dut.window7.value) * to_signed(0xe8, 8)
      mac_sum += int(dut.window8.value) * to_signed(0xe1, 8)
      mac_sum += int(dut.window9.value) * to_signed(0xfc, 8)
      mac_sum += int(dut.window10.value) * to_signed(0x32, 8)
      mac_sum += int(dut.window11.value) * to_signed(0xf6, 8)
      mac_sum += int(dut.window12.value) * to_signed(0x08, 8)
      mac_sum += int(dut.window13.value) * to_signed(0x00, 8)
      mac_sum += int(dut.window14.value) * to_signed(0x16, 8)
      mac_sum += int(dut.window15.value) * to_signed(0x43, 8)
      mac_sum += int(dut.window16.value) * to_signed(0x21, 8)
      mac_sum += int(dut.window17.value) * to_signed(0x01, 8)
      mac_sum += int(dut.window18.value) * to_signed(0x36, 8)
      mac_sum += int(dut.window19.value) * to_signed(0x58, 8)
      mac_sum += int(dut.window20.value) * to_signed(0x03, 8)
      mac_sum += int(dut.window21.value) * to_signed(0x11, 8)
      mac_sum += int(dut.window22.value) * to_signed(0x5c, 8)
      mac_sum += int(dut.window23.value) * to_signed(0x62, 8)
      mac_sum += int(dut.window24.value) * to_signed(0x4d, 8)
      mac_sum += to_signed(0x0060, 16) #bias
      print(f"mac_sum: {mac_sum}")
      if(mac_sum < 0):
        mac_sum = 0
      assert dut.data1_o.value == mac_sum, f"Output mismatch: expected {mac_sum}, got {int(dut.data1_o.value)} at time {get_sim_time('ns')} ns"





            
            
        

    


    



@pytest.mark.parametrize("linewidth_px_p", [28])
def test_conv1(linewidth_px_p):
    run_cocotb(
        "conv1",
        SOURCES,
        "test_conv1",
        {"linewidth_px_p": linewidth_px_p, "width_p": 8},
        tag=f"_L{linewidth_px_p}"
    )
