"""elastic: one-entry valid/ready pipeline register.

Checks: every accepted input comes out exactly once, in order; data is stable
while stalled; ready_o == ~valid_o | ready_i; reset clears valid_o.

How this file runs
------------------
There are two "sides" in this file:

  1. The pytest side (test_elastic at the bottom). pytest calls it once per
     width_p value. It compiles elastic.sv with Icarus and launches the
     simulator, which then runs every @cocotb.test() in this module.

  2. The cocotb side (the async @cocotb.test() functions). These run *inside*
     the simulator. `dut` is a handle to the top-level module; dut.<port>.value
     reads or drives a port. `await RisingEdge(...)` / `await Timer(...)`
     advance simulation time.

A handshake happens on a rising edge when valid and ready are both 1:
  - input side:  valid_i & ready_o  -> elastic captures data_i
  - output side: valid_o & ready_i  -> the consumer takes data_o
"""

import random

import cocotb
import pytest
from cocotb.triggers import RisingEdge, Timer

from common import param, run_cocotb, run_stream, start_clock_and_reset


@cocotb.test()
async def test_reset(dut):
    """After reset the register is empty: valid_o=0, so ready_o=1."""
    # Drive valid_i=1 during reset on purpose: reset must win and not let
    # this beat get captured.
    dut.valid_i.value = 1
    dut.ready_i.value = 0
    dut.data_i.value = 0
    await start_clock_and_reset(dut)
    # Wait 1 ns past the edge so the register outputs have settled before
    # reading them.
    await Timer(1, unit="ns")
    assert int(dut.valid_o.value) == 0, "valid_o must be 0 after reset"
    # Empty register -> it can always accept, regardless of ready_i.
    assert int(dut.ready_o.value) == 1


@cocotb.test()
async def test_ready_comb(dut):
    """ready_o = ~valid_o | ready_i, checked over random traffic.

    ready_o is combinational: elastic can accept a new beat if it is empty
    (~valid_o) or if the current beat is leaving this cycle (ready_i).
    """
    await start_clock_and_reset(dut)
    rng = random.Random(3)  # fixed seed -> the same sequence every run
    for _ in range(300):
        # Randomise all inputs for this cycle.
        dut.valid_i.value = rng.randint(0, 1)
        dut.ready_i.value = rng.randint(0, 1)
        dut.data_i.value = rng.getrandbits(param("width_p", 8))
        # Let the combinational logic settle, then compare against the formula.
        await Timer(1, unit="ns")
        exp = (not int(dut.valid_o.value)) or int(dut.ready_i.value)
        assert int(dut.ready_o.value) == int(exp)
        # Clock edge: valid_o may change, which changes the next ready_o.
        await RisingEdge(dut.clk_i)


async def stream_case(dut, p_valid, p_ready, n=400):
    """Send n random values through elastic and check they all come out in order.

    p_valid: chance per cycle that the source offers a beat (1.0 = every cycle).
    p_ready: chance per cycle that the sink accepts a beat (1.0 = never stalls).

    run_stream (tests/common.py) acts as both source and sink. It also checks
    that data_o stays stable while valid_o=1 and ready_i=0. elastic is a
    register, not a transformation, so the expected output is the input
    list itself: no lost, duplicated or reordered beats.
    """
    w = param("width_p", 8)  # width_p that pytest built this simulation with
    await start_clock_and_reset(dut)
    # Seed from the probabilities so each test case gets different data
    # but is still reproducible.
    rng = random.Random(int(p_valid * 100 + p_ready))
    inputs = [rng.getrandbits(w) for _ in range(n)]
    outs = await run_stream(dut, inputs, n, p_valid, p_ready)
    assert [int(o) for o in outs] == inputs


# The four stream tests cover the four basic traffic patterns.


@cocotb.test()
async def test_stream_full_rate(dut):
    """Source and sink always ready: one beat per cycle, no stalls."""
    await stream_case(dut, 1.0, 1.0)


@cocotb.test()
async def test_stream_backpressure(dut):
    """Sink is ready only 30% of the time: elastic must hold data and push back via ready_o."""
    await stream_case(dut, 1.0, 0.3)


@cocotb.test()
async def test_stream_bubbles(dut):
    """Source offers data only 30% of the time: gaps must not create or repeat beats."""
    await stream_case(dut, 0.3, 1.0)


@cocotb.test()
async def test_stream_random(dut):
    """Both sides random: mix of stalls and bubbles."""
    await stream_case(dut, 0.6, 0.6)


# pytest entry point: builds and runs the whole cocotb module above once
# per width. Waveforms: sim_build/elastic_w8/ and sim_build/elastic_w16/.
@pytest.mark.parametrize("width_p", [8, 16])
def test_elastic(width_p):
    run_cocotb("elastic", ["elastic.sv"], "test_elastic", {"width_p": width_p}, tag=f"_w{width_p}")
