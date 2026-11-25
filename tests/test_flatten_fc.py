
import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset, to_signed
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, with_timeout, First
from cocotb.types import LogicArray, Range

SOURCES = ["flatten_fc.sv","Argmax.sv","MAC8_21.sv","ram_2r1w_sync.sv"]


@cocotb.test()
async def test_flatten_stream(dut):
    clk_i = dut.clk_i
    reset_i = dut.reset_i

    await start_clock_and_reset(dut)

    await FallingEdge(reset_i)
    await FallingEdge(clk_i)
    

    # Wait for all ramdelay buffers and windows to be filled with zeros(due to icarus X's)
    for i in range(130):
      dut.data1_i.value = random.randint(0, 30)
      dut.data2_i.value = random.randint(50, 100)
      dut.data3_i.value = random.randint(150, 200)
      dut.valid_i.value = 1
      await RisingEdge(clk_i)
      dut.valid_i.value = 0
      #await with_timeout(RisingEdge(dut.valid_o), 1000, 'ns')
      await RisingEdge(clk_i)
      await FallingEdge(clk_i)


def test_flatten_fc():
    run_cocotb(
        "flatten_fc",
        SOURCES,
        "test_flatten_fc",
    )
