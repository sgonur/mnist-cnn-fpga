"""ram_1r1w_sync: 1 read / 1 write port, synchronous (1-cycle) read.

Checks write-then-read, read enable gating (rd_data_o holds when rd_valid_i=0),
read-during-write to the same address returns OLD data (read-first), and
writes are ignored while reset_i is high.
"""

import random

import cocotb
import pytest
from cocotb.triggers import RisingEdge, Timer

from common import param, run_cocotb, start_clock_and_reset


def idle(dut):
    dut.wr_valid_i.value = 0
    dut.rd_valid_i.value = 0
    dut.wr_addr_i.value = 0
    dut.rd_addr_i.value = 0
    dut.wr_data_i.value = 0


async def write(dut, addr, data):
    dut.wr_valid_i.value = 1
    dut.wr_addr_i.value = addr
    dut.wr_data_i.value = data
    await RisingEdge(dut.clk_i)
    dut.wr_valid_i.value = 0


async def read(dut, addr):
    dut.rd_valid_i.value = 1
    dut.rd_addr_i.value = addr
    await RisingEdge(dut.clk_i)
    dut.rd_valid_i.value = 0
    await Timer(1, unit="ns")
    return dut.rd_data_o.value


@cocotb.test()
async def test_write_read_all(dut):
    w, d = param("width_p", 8), param("depth_p", 16)
    idle(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(1)
    model = {a: rng.getrandbits(w) for a in range(d)}
    for a, v in model.items():
        await write(dut, a, v)
    for a in rng.sample(range(d), d):
        got = await read(dut, a)
        assert got.is_resolvable and int(got) == model[a], f"mem[{a}] = {got}, expected {model[a]}"


@cocotb.test()
async def test_random_traffic(dut):
    """Simultaneous random reads/writes against a model."""
    w, d = param("width_p", 8), param("depth_p", 16)
    idle(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(2)
    model = {}
    for a in range(d):  # initialise so every read is defined
        model[a] = rng.getrandbits(w)
        await write(dut, a, model[a])

    expected = None  # value rd_data_o should hold
    for _ in range(1000):
        we, re = rng.random() < 0.5, rng.random() < 0.7
        wa, ra = rng.randrange(d), rng.randrange(d)
        wd = rng.getrandbits(w)
        dut.wr_valid_i.value = int(we)
        dut.wr_addr_i.value = wa
        dut.wr_data_i.value = wd
        dut.rd_valid_i.value = int(re)
        dut.rd_addr_i.value = ra
        await RisingEdge(dut.clk_i)
        if re:
            expected = model[ra]  # read-first: old value even if wa == ra
        if we:
            model[wa] = wd
        await Timer(1, unit="ns")
        if expected is not None:
            got = dut.rd_data_o.value
            assert got.is_resolvable and int(got) == expected, (
                f"rd_data_o = {got}, expected {expected} (re={re} ra={ra} we={we} wa={wa})"
            )


@cocotb.test()
async def test_read_hold(dut):
    idle(dut)
    await start_clock_and_reset(dut)
    await write(dut, 3, 0x5A)
    await write(dut, 4, 0x11)
    assert int(await read(dut, 3)) == 0x5A
    dut.rd_addr_i.value = 4  # change address but keep rd_valid_i low
    for _ in range(3):
        await RisingEdge(dut.clk_i)
    await Timer(1, unit="ns")
    assert int(dut.rd_data_o.value) == 0x5A, "rd_data_o changed with rd_valid_i=0"


@cocotb.test()
async def test_write_ignored_in_reset(dut):
    idle(dut)
    await start_clock_and_reset(dut)
    await write(dut, 1, 0x22)
    dut.reset_i.value = 1
    await write(dut, 1, 0x99)
    dut.reset_i.value = 0
    assert int(await read(dut, 1)) == 0x22


@pytest.mark.parametrize("width_p,depth_p", [(8, 16), (16, 28), (8, 5)])
def test_ram_1r1w_sync(width_p, depth_p):
    run_cocotb(
        "ram_1r1w_sync",
        ["ram_1r1w_sync.sv"],
        "test_ram_1r1w_sync",
        {"width_p": width_p, "depth_p": depth_p},
        tag=f"_w{width_p}_d{depth_p}",
    )
