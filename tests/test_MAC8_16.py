"""MAC8_16: acc <= acc + $unsigned(data_i) * $signed(weight_i) each cycle.

mac_o is expected to show the registered accumulator (16-bit signed, wraps).
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, Timer

from common import run_cocotb, start_clock_and_reset, to_signed


async def read_mac(dut):
    await Timer(1, unit="ns")  # let the post-edge register value settle
    v = dut.mac_o.value
    assert v.is_resolvable, f"mac_o is not driven / unresolved: {v}"
    return to_signed(int(v), 16)


async def drive_and_check(dut, pairs):
    acc = 0
    for data, weight in pairs:
        dut.data_i.value = data
        dut.weight_i.value = weight & 0xFF
        await RisingEdge(dut.clk_i)
        acc = to_signed(acc + data * weight, 16)
        got = await read_mac(dut)
        assert got == acc, f"after data={data} weight={weight}: mac_o={got}, expected {acc}"
    return acc


@cocotb.test()
async def test_reset_clears(dut):
    dut.data_i.value = 0
    dut.weight_i.value = 0
    await start_clock_and_reset(dut)
    assert await read_mac(dut) == 0


@cocotb.test()
async def test_single_products(dut):
    """Single extreme products: unsigned data must not be sign-extended."""
    for data, weight in [(255, 127), (255, -128), (128, 1), (200, -1), (0, -128), (1, 1)]:
        dut.data_i.value = 0
        dut.weight_i.value = 0
        await start_clock_and_reset(dut)
        await drive_and_check(dut, [(data, weight)])


@cocotb.test()
async def test_random_accumulate(dut):
    """Random accumulation, model wraps at 16 bits like the RTL."""
    rng = random.Random(7)
    dut.data_i.value = 0
    dut.weight_i.value = 0
    await start_clock_and_reset(dut)
    pairs = [(rng.randint(0, 255), rng.randint(-128, 127)) for _ in range(500)]
    await drive_and_check(dut, pairs)


def test_MAC8_16():
    run_cocotb("MAC8_16", ["MAC8_16.sv"], "test_MAC8_16")
