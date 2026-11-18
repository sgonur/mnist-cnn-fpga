"""ReLU: data_o = max(data_i, 0) for a signed width_p-bit input (combinational)."""

import random

import cocotb
import pytest
from cocotb.triggers import Timer

from common import param, run_cocotb, to_signed


def relu_model(x):
    return x if x > 0 else 0


async def check(dut, x, width):
    dut.data_i.value = x & ((1 << width) - 1)
    await Timer(1, unit="ns")
    got = dut.data_o.value
    assert got.is_resolvable, f"data_o is {got} for data_i={x}"
    got = to_signed(int(got), width)
    assert got == relu_model(x), f"ReLU({x}) = {got}, expected {relu_model(x)}"


@cocotb.test()
async def test_relu_corners(dut):
    w = param("width_p", 16)
    lo, hi = -(1 << (w - 1)), (1 << (w - 1)) - 1
    for x in [0, 1, -1, hi, lo, hi - 1, lo + 1]:
        await check(dut, x, w)


@cocotb.test()
async def test_relu_sweep(dut):
    """Exhaustive for small widths, 5000 random values otherwise."""
    w = param("width_p", 16)
    lo, hi = -(1 << (w - 1)), (1 << (w - 1)) - 1
    values = range(lo, hi + 1) if w <= 10 else [random.randint(lo, hi) for _ in range(5000)]
    for x in values:
        await check(dut, x, w)


@pytest.mark.parametrize("width_p", [16, 8, 24])
def test_ReLU(width_p):
    run_cocotb("ReLU", ["ReLU.sv"], "test_ReLU", {"width_p": width_p}, tag=f"_w{width_p}")
