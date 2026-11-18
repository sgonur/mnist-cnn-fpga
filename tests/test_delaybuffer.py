"""delaybuffer: valid/ready stream whose output n is input n - delay_p.

The RAM read port only advances on an input handshake, so the delay is
counted in accepted beats, not cycles. The first delay_p outputs come from
uninitialised RAM and are not checked.
"""

import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset

SOURCES = ["delaybuffer.sv", "elastic.sv", "ram_1r1w_sync.sv"]


async def stream_case(dut, p_valid, p_ready, n=300):
    w, d = param("width_p", 8), param("delay_p", 8)
    await start_clock_and_reset(dut)
    rng = random.Random(int(p_valid * 10 + p_ready * 100))
    inputs = [rng.getrandbits(w) for _ in range(n)]
    outs = await run_stream(dut, inputs, n, p_valid, p_ready)
    for i in range(d, n):
        got = outs[i]
        assert got.is_resolvable and int(got) == inputs[i - d], (
            f"output {i}: got {got}, expected input {i - d} = {inputs[i - d]}"
        )


@cocotb.test()
async def test_full_rate(dut):
    await stream_case(dut, 1.0, 1.0)


@cocotb.test()
async def test_backpressure(dut):
    await stream_case(dut, 1.0, 0.4)


@cocotb.test()
async def test_bubbles(dut):
    await stream_case(dut, 0.4, 1.0)


@cocotb.test()
async def test_random(dut):
    await stream_case(dut, 0.7, 0.7)


@pytest.mark.parametrize("width_p,delay_p", [(8, 8), (8, 27), (16, 3), (8, 1)])
def test_delaybuffer(width_p, delay_p):
    run_cocotb(
        "delaybuffer",
        SOURCES,
        "test_delaybuffer",
        {"width_p": width_p, "delay_p": delay_p},
        tag=f"_w{width_p}_d{delay_p}",
    )
