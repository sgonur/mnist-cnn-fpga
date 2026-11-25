"""maxpool: 2x2 stride-2 max pooling on a raster-order valid/ready stream.

Input is linewidth_px_p x height_px_p pixels per frame, output is
(W//2) x (H//2) pixels per frame in raster order. Comparisons are signed.
Odd sizes drop the trailing column/row (PyTorch floor behaviour).
"""

import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset, to_signed


def maxpool_model(frame, w, h):
    """frame: flat list of h*w values in raster order."""
    out = []
    for r in range(0, 2 * (h // 2), 2):
        for c in range(0, 2 * (w // 2), 2):
            out.append(max(
                frame[r * w + c], frame[r * w + c + 1],
                frame[(r + 1) * w + c], frame[(r + 1) * w + c + 1],
            ))
    return out


async def stream_case(dut, p_valid, p_ready, frames=3, signed_vals=True, seed=0):
    w = param("linewidth_px_p", 24)
    h = param("height_px_p", w)
    bits = param("width_p", 16)
    await start_clock_and_reset(dut)

    rng = random.Random(seed)
    lo = -(1 << (bits - 1)) if signed_vals else 0
    hi = (1 << (bits - 1)) - 1
    inputs, expected = [], []
    for _ in range(frames):
        frame = [rng.randint(lo, hi) for _ in range(w * h)]
        inputs += frame
        expected += maxpool_model(frame, w, h)

    raw = [x & ((1 << bits) - 1) for x in inputs]
    outs = await run_stream(dut, raw, len(expected), p_valid, p_ready)
    for i, (got, exp) in enumerate(zip(outs, expected)):
        assert got.is_resolvable, f"output {i} is {got}"
        got = to_signed(int(got), bits)
        assert got == exp, f"output {i}: got {got}, expected {exp}"


@cocotb.test()
async def test_full_rate(dut):
    await stream_case(dut, 1.0, 1.0, seed=1)


@cocotb.test()
async def test_backpressure(dut):
    await stream_case(dut, 1.0, 0.3, seed=2)


@cocotb.test()
async def test_bubbles(dut):
    await stream_case(dut, 0.4, 1.0, seed=3)


@cocotb.test()
async def test_random(dut):
    await stream_case(dut, 0.7, 0.7, seed=4)


@cocotb.test()
async def test_relu_range(dut):
    """Non-negative inputs, as maxpool sees them after ReLU."""
    await stream_case(dut, 0.8, 0.8, signed_vals=False, seed=5)


@pytest.mark.parametrize(
    "linewidth_px_p,height_px_p,width_p",
    [(24, 24, 16), (8, 6, 8), (7, 5, 16), (2, 2, 16)],
)
def test_maxpool(linewidth_px_p, height_px_p, width_p):
    run_cocotb(
        "maxpool",
        ["maxpool.sv", "elastic.sv"],
        "test_maxpool",
        {"linewidth_px_p": linewidth_px_p, "height_px_p": height_px_p, "width_p": width_p},
        tag=f"_w{linewidth_px_p}_h{height_px_p}_b{width_p}",
    )
