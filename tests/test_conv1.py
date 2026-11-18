"""conv1: First layer convolution with 5x5 sliding window over a stream of image pixels. 
After ready_o and valid_i are asserted, module should take 25 cycles before valid_o is asserted. The output is two streams of pixels from each filter that should come out parallel. The output is valid for 1 cycle and then the module should wait for the next valid_i to be asserted. The module should also assert ready_o when it is ready to accept new input pixels. After pipeline stage, will be added with bias and sent through ReLU activation function. The output will be sent to the next layer of the CNN.
"""

import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset
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

      #reference MAC calculation for filter1
      mac_sum += int(dut.window0.value) * 0x96
      print(f"window0: {hex(dut.window0.value)}")
      mac_sum += int(dut.window1.value) * 0x90
      mac_sum += int(dut.window2.value) * 0x97
      mac_sum += int(dut.window3.value) * 0xab
      mac_sum += int(dut.window4.value) * 0x12
      mac_sum += int(dut.window5.value) * 0xf3
      mac_sum += int(dut.window6.value) * 0xde
      mac_sum += int(dut.window7.value) * 0xe8
      mac_sum += int(dut.window8.value) * 0xe1
      mac_sum += int(dut.window9.value) * 0xfc
      mac_sum += int(dut.window10.value) * 0x32
      mac_sum += int(dut.window11.value) * 0xf6
      mac_sum += int(dut.window12.value) * 0x08
      mac_sum += int(dut.window13.value) * 0x00
      mac_sum += int(dut.window14.value) * 0x16
      mac_sum += int(dut.window15.value) * 0x43
      mac_sum += int(dut.window16.value) * 0x21
      mac_sum += int(dut.window17.value) * 0x01
      mac_sum += int(dut.window18.value) * 0x36
      mac_sum += int(dut.window19.value) * 0x58
      mac_sum += int(dut.window20.value) * 0x03
      mac_sum += int(dut.window21.value) * 0x11
      mac_sum += int(dut.window22.value) * 0x5c
      mac_sum += int(dut.window23.value) * 0x62
      mac_sum += int(dut.window24.value) * 0x4d
      mac_sum += 0x60 #bias
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
