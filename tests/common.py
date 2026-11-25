"""Shared helpers for the cocotb testbenches in this directory.

Every test_<module>.py has:
  * one or more @cocotb.test() coroutines (run inside the simulator), and
  * a plain pytest function that calls run_cocotb() to build + run them.
"""

import os
import shutil
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
SIM_BUILD = ROOT / "sim_build"

CLK_PERIOD_NS = 10


# --------------------------------------------------------------------------
# Runner (pytest side)
# --------------------------------------------------------------------------
def run_cocotb(toplevel, sources, test_module, parameters=None, tag=""):
    """Build `sources` with Icarus and run the cocotb tests in `test_module`.

    `tag` separates build dirs when the same toplevel is run with different
    parameters, so waveforms land in sim_build/<toplevel><tag>/<toplevel>.fst.
    """
    from cocotb_tools.runner import get_runner

    parameters = parameters or {}
    build_dir = SIM_BUILD / f"{toplevel}{tag}"
    build_dir.mkdir(parents=True, exist_ok=True)

    weights_src_dir = SRC / "weights"
    if weights_src_dir.exists():
        for mem_file in weights_src_dir.glob("*.mem"):
            shutil.copy(mem_file, build_dir / mem_file.name)


    runner = get_runner(os.environ.get("SIM", "icarus"))
    runner.build(
        sources=[SRC / s for s in sources],
        hdl_toplevel=toplevel,
        parameters=parameters,
        build_dir=build_dir,
        timescale=("1ns", "1ps"),
        waves=True,
        always=True,
    )
    runner.test(
        hdl_toplevel=toplevel,
        test_module=test_module,
        build_dir=build_dir,
        test_dir=build_dir,
        waves=True,
        extra_env={f"PARAM_{k}": str(v) for k, v in parameters.items()},
    )


def param(name, default):
    """Read a parameter value passed in by run_cocotb (see extra_env)."""
    return int(os.environ.get(f"PARAM_{name}", default))


# --------------------------------------------------------------------------
# Simulator-side helpers
# --------------------------------------------------------------------------
async def start_clock_and_reset(dut, cycles=3):
    """Start clk_i and hold reset_i high for `cycles` rising edges."""
    cocotb.start_soon(Clock(dut.clk_i, CLK_PERIOD_NS, unit="ns").start())
    dut.reset_i.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clk_i)
    dut.reset_i.value = 0


def to_signed(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def resolvable(sig):
    return sig.value.is_resolvable


async def run_stream(
    dut,
    inputs,
    n_outputs,
    p_valid=1.0,
    p_ready=1.0,
    timeout_cycles=None,
    data_in="data_i",
    data_out="data_o",
    check_stall_stable=True,
):
    """Push `inputs` through a valid/ready module and collect outputs.

    Uses the standard interface names (valid_i/ready_o in, valid_o/ready_i out).
    Signals are sampled at each rising edge (pre-update values), which is
    exactly what decides whether a handshake happens on that edge.

    Returns the list of raw output values (LogicArray), one per output
    handshake, so callers can decide how to treat X/Z early outputs.

    If `check_stall_stable`, asserts that while valid_o is held high and the
    sink is not ready, data_o does not change (AXI-style stability rule).
    """
    rng = random.Random(1234)
    clk = dut.clk_i
    d_in = getattr(dut, data_in)
    d_out = getattr(dut, data_out)

    outputs = []
    idx = 0
    stalled_value = None
    timeout_cycles = timeout_cycles or (len(inputs) + n_outputs) * 20 + 100

    dut.valid_i.value = 0
    dut.ready_i.value = 0
    d_in.value = 0

    for _ in range(timeout_cycles):
        await RisingEdge(clk)

        # ---- sample handshakes that occur on this edge ----
        if int(dut.valid_i.value) and int(dut.ready_o.value):
            idx += 1

        v_o = int(dut.valid_o.value)
        r_i = int(dut.ready_i.value)
        if check_stall_stable and stalled_value is not None and v_o:
            assert str(d_out.value) == str(stalled_value), (
                f"data_o changed while stalled: {stalled_value} -> {d_out.value}"
            )
        if v_o and r_i:
            outputs.append(d_out.value)
            stalled_value = None
        elif v_o and not r_i:
            stalled_value = d_out.value
        else:
            stalled_value = None

        if len(outputs) >= n_outputs:
            dut.valid_i.value = 0
            dut.ready_i.value = 0
            # Let the writes apply before returning. Ending a test with
            # writes still pending segfaults vvp on exit (cocotb 2.1-dev
            # + Icarus 14-dev from oss-cad-suite).
            await RisingEdge(clk)
            return outputs

        # ---- drive the next cycle ----
        # Keep valid high once asserted until accepted (no retraction).
        if idx < len(inputs):
            if int(dut.valid_i.value) and not int(dut.ready_o.value):
                pass  # hold current beat
            elif rng.random() < p_valid:
                dut.valid_i.value = 1
                d_in.value = inputs[idx]
            else:
                dut.valid_i.value = 0
        else:
            dut.valid_i.value = 0
        dut.ready_i.value = 1 if rng.random() < p_ready else 0

    raise AssertionError(
        f"timeout: sent {idx}/{len(inputs)} inputs, got {len(outputs)}/{n_outputs} outputs"
    )