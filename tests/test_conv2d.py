"""conv2d: 3x3 sliding-window sum over a raster-scan pixel stream.

Reference model works on the flat pixel index n (row-major, linewidth L):
  out[n] = sum(p[n - r*L - c] for r in 0..2 for c in 0..2)
This is the raw sliding window: windows that straddle a row edge are emitted
too (downstream logic is expected to discard them). Outputs are checked once
the window is fully populated (n >= 2L + 2).
"""

import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset

SOURCES = ["conv2d.sv", "delaybuffer.sv", "elastic.sv", "ram_1r1w_sync.sv"]


def model(pixels, L, n):
    return sum(pixels[n - r * L - c] for r in range(3) for c in range(3))


async def image_case(dut, n_images, p_valid, p_ready, pixel_fn=None):
    L, w = param("linewidth_px_p", 28), param("width_p", 8)
    await start_clock_and_reset(dut)
    rng = random.Random(L * 31 + n_images)
    pixel_fn = pixel_fn or (lambda i: rng.getrandbits(w))
    n = L * L * n_images
    pixels = [pixel_fn(i) & ((1 << w) - 1) for i in range(n)]
    outs = await run_stream(dut, pixels, n, p_valid, p_ready)
    mask = (1 << (2 * w)) - 1
    for i in range(2 * L + 2, n):
        got, exp = outs[i], model(pixels, L, i) & mask
        assert got.is_resolvable and int(got) == exp, (
            f"pixel {i} (row {i // L % L}, col {i % L}): got {got}, expected {exp}"
        )


@cocotb.test()
async def test_ramp(dut):
    """Deterministic ramp image, easy to read in waveforms."""
    await image_case(dut, 1, 1.0, 1.0, pixel_fn=lambda i: i)


@cocotb.test()
async def test_max_pixels(dut):
    """All-max pixels: checks the 2*width_p output does not overflow."""
    await image_case(dut, 1, 1.0, 1.0, pixel_fn=lambda i: 0xFFFF)


@cocotb.test()
async def test_random_full_rate(dut):
    await image_case(dut, 2, 1.0, 1.0)


@cocotb.test()
async def test_random_handshake(dut):
    await image_case(dut, 2, 0.7, 0.6)


@pytest.mark.parametrize("linewidth_px_p", [28, 8])
def test_conv2d(linewidth_px_p):
    run_cocotb(
        "conv2d",
        SOURCES,
        "test_conv2d",
        {"linewidth_px_p": linewidth_px_p, "width_p": 8},
        tag=f"_L{linewidth_px_p}",
    )
