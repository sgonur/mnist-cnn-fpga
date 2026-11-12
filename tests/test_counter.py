"""cocotb tests for src/hdl/counter.v.

Run with `pytest tests/` (or `make test`). Each pytest function at the bottom
builds the HDL with the chosen simulator and runs the cocotb tests above it.
"""

import os
from pathlib import Path

import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, ReadOnly
from cocotb_tools.runner import get_runner

REPO = Path(__file__).resolve().parents[1]
HDL = REPO / "src" / "hdl"
SIM = os.getenv("SIM", "icarus")


async def reset(dut, cycles=2):
    dut.rst.value = 1
    dut.en.value = 0
    await ClockCycles(dut.clk, cycles)
    dut.rst.value = 0


# --------------------------------------------------------------------------
# cocotb tests (run inside the simulator)
# --------------------------------------------------------------------------

@cocotb.test()
async def test_reset_clears_count(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)
    await ReadOnly()
    assert dut.count.value == 0


@cocotb.test()
async def test_counts_when_enabled(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)
    dut.en.value = 1
    await ClockCycles(dut.clk, 5)
    await ReadOnly()
    assert dut.count.value == 5


@cocotb.test()
async def test_holds_when_disabled(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)
    dut.en.value = 1
    await ClockCycles(dut.clk, 3)
    dut.en.value = 0
    await ClockCycles(dut.clk, 10)
    await ReadOnly()
    assert dut.count.value == 3


@cocotb.test()
async def test_wraps_and_flags(dut):
    width = len(dut.count)
    max_val = (1 << width) - 1
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)
    dut.en.value = 1
    await ClockCycles(dut.clk, max_val)
    await ReadOnly()
    assert dut.count.value == max_val
    assert dut.wrap.value == 1
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert dut.count.value == 0
    assert dut.wrap.value == 0


# --------------------------------------------------------------------------
# pytest entry point (builds + runs the simulation)
# --------------------------------------------------------------------------

@pytest.mark.parametrize("width", [4, 8])
def test_counter(width):
    runner = get_runner(SIM)
    build_dir = REPO / "sim_build" / f"counter_w{width}"
    runner.build(
        sources=[HDL / "counter.v"],
        hdl_toplevel="counter",
        parameters={"WIDTH": width},
        build_dir=build_dir,
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel="counter",
        test_module="test_counter",
        test_dir=Path(__file__).parent,
        build_dir=build_dir,
        waves=True,
    )
