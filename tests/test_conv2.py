
import random

import cocotb
import pytest

from common import param, run_cocotb, run_stream, start_clock_and_reset, to_signed
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, with_timeout, First
from cocotb.types import LogicArray, Range

SOURCES = ["conv2.sv", "delaybuffer.sv", "elastic.sv", "ram_1r1w_sync.sv", "ReLU.sv","MAC8_21.sv","ram_2r1w_sync.sv"]


@cocotb.test()
async def test_conv2_readyvalid(dut):
    """Test conv2 with random input data and check output against expected results."""
    clk_i = dut.clk_i
    reset_i = dut.reset_i

    await start_clock_and_reset(dut)

    await FallingEdge(reset_i)
    await FallingEdge(clk_i)
    dut.ready_i.value = 1

    # Wait for all ramdelay buffers and windows to be filled with zeros(due to icarus X's)
    for i in range(40):
      dut.data1_i.value = 0
      dut.data2_i.value = 0
      dut.valid_i.value = 1
      await RisingEdge(clk_i)
      dut.valid_i.value = 0
      await with_timeout(RisingEdge(dut.valid_o), 1000, 'ns')
      await RisingEdge(clk_i)

    for i in range(14*14):
        dut.data1_i.value = random.randint(0, 255)
        dut.data2_i.value = random.randint(0, 255)
        mac_sum0A = 0
        mac_sum0B = 0
        mac_sum1A = 0
        mac_sum1B = 0
        mac_sum2A = 0
        mac_sum2B = 0
        dut.valid_i.value = 1
        await RisingEdge(clk_i)
        dut.valid_i.value = 0
        await with_timeout(FallingEdge(dut.ready_o),1000,'ns')
        await RisingEdge(dut.valid_o)
        await RisingEdge(clk_i)
        await Timer(1000, unit="ps") #for good measure

        mac_sum0A += int(dut.window1_0.value) * to_signed(0xdb, 8)
        mac_sum0B += int(dut.window2_0.value) * to_signed(0xf8, 8)

        mac_sum0A += int(dut.window1_1.value) * to_signed(0x29, 8)
        mac_sum0B += int(dut.window2_1.value) * to_signed(0xe4, 8)

        mac_sum0A += int(dut.window1_2.value) * to_signed(0x51, 8)
        mac_sum0B += int(dut.window2_2.value) * to_signed(0xe1, 8)

        mac_sum0A += int(dut.window1_3.value) * to_signed(0x0b, 8)
        mac_sum0B += int(dut.window2_3.value) * to_signed(0xcd, 8)

        mac_sum0A += int(dut.window1_4.value) * to_signed(0x0b, 8)
        mac_sum0B += int(dut.window2_4.value) * to_signed(0xce, 8)

        mac_sum0A += int(dut.window1_5.value) * to_signed(0x1b, 8)
        mac_sum0B += int(dut.window2_5.value) * to_signed(0xea, 8)

        mac_sum0A += int(dut.window1_6.value) * to_signed(0x28, 8)
        mac_sum0B += int(dut.window2_6.value) * to_signed(0xe8, 8)

        mac_sum0A += int(dut.window1_7.value) * to_signed(0x24, 8)
        mac_sum0B += int(dut.window2_7.value) * to_signed(0xf7, 8)

        mac_sum0A += int(dut.window1_8.value) * to_signed(0x08, 8)
        mac_sum0B += int(dut.window2_8.value) * to_signed(0xF9, 8)




        mac_sum1A += int(dut.window1_0.value) * to_signed(0xf2, 8)
        mac_sum1B += int(dut.window2_0.value) * to_signed(0xca, 8)

        mac_sum1A += int(dut.window1_1.value) * to_signed(0xf3, 8)
        mac_sum1B += int(dut.window2_1.value) * to_signed(0xf9, 8)

        mac_sum1A += int(dut.window1_2.value) * to_signed(0xff, 8)
        mac_sum1B += int(dut.window2_2.value) * to_signed(0x2c, 8)

        mac_sum1A += int(dut.window1_3.value) * to_signed(0x19, 8)
        mac_sum1B += int(dut.window2_3.value) * to_signed(0x07, 8)

        mac_sum1A += int(dut.window1_4.value) * to_signed(0x23, 8)
        mac_sum1B += int(dut.window2_4.value) * to_signed(0x81, 8)

        mac_sum1A += int(dut.window1_5.value) * to_signed(0xe2, 8)
        mac_sum1B += int(dut.window2_5.value) * to_signed(0xea, 8)

        mac_sum1A += int(dut.window1_6.value) * to_signed(0xf6, 8)
        mac_sum1B += int(dut.window2_6.value) * to_signed(0x4c, 8)

        mac_sum1A += int(dut.window1_7.value) * to_signed(0x1d, 8)
        mac_sum1B += int(dut.window2_7.value) * to_signed(0x22, 8)

        mac_sum1A += int(dut.window1_8.value) * to_signed(0x43, 8)
        mac_sum1B += int(dut.window2_8.value) * to_signed(0xc8, 8)



        mac_sum2A += int(dut.window1_0.value) * to_signed(0xae, 8)
        mac_sum2B += int(dut.window2_0.value) * to_signed(0x4c, 8)

        mac_sum2A += int(dut.window1_1.value) * to_signed(0xd2, 8)
        mac_sum2B += int(dut.window2_1.value) * to_signed(0x20, 8)

        mac_sum2A += int(dut.window1_2.value) * to_signed(0xd7, 8)
        mac_sum2B += int(dut.window2_2.value) * to_signed(0x45, 8)

        mac_sum2A += int(dut.window1_3.value) * to_signed(0xf2, 8)
        mac_sum2B += int(dut.window2_3.value) * to_signed(0xe1, 8)

        mac_sum2A += int(dut.window1_4.value) * to_signed(0xe9, 8)
        mac_sum2B += int(dut.window2_4.value) * to_signed(0xd8, 8)

        mac_sum2A += int(dut.window1_5.value) * to_signed(0xe9, 8)
        mac_sum2B += int(dut.window2_5.value) * to_signed(0xc4, 8)

        mac_sum2A += int(dut.window1_6.value) * to_signed(0x1f, 8)
        mac_sum2B += int(dut.window2_6.value) * to_signed(0x98, 8)

        mac_sum2A += int(dut.window1_7.value) * to_signed(0x2a, 8)
        mac_sum2B += int(dut.window2_7.value) * to_signed(0x19, 8)

        mac_sum2A += int(dut.window1_8.value) * to_signed(0x29, 8)
        mac_sum2B += int(dut.window2_8.value) * to_signed(0x0b, 8)


        
        total_mac0 = mac_sum0A + mac_sum0B
        total_mac1 = mac_sum1A + mac_sum1B
        total_mac2 = mac_sum2A + mac_sum2B

        total_mac0 += to_signed(0xfb, 21) #bias
        total_mac1 += to_signed(0xb5, 21) #bias
        total_mac2 += to_signed(0x81, 21) #bias

        if(total_mac0 < 0):
            total_mac0 = 0
        if(total_mac1 < 0):
            total_mac1 = 0
        if(total_mac2 < 0):
            total_mac2 = 0

        print(f"mac_sum0: {total_mac0}, mac0A: {mac_sum0A}, mac0B: {mac_sum0B}")
        print(f"mac_sum1: {total_mac1}, mac1A: {mac_sum1A}, mac1B: {mac_sum1B}")
        print(f"mac_sum2: {total_mac2}, mac2A: {mac_sum2A}, mac2B: {mac_sum2B}")
        await Timer(1000, unit="ps") #for good measure
        actual_val0 = to_signed(int(dut.data1_o.value), 21)
        actual_val1 = to_signed(int(dut.data2_o.value), 21)
        actual_val2 = to_signed(int(dut.data3_o.value), 21)
        assert actual_val0 == total_mac0, f"Filter 0 Output mismatch: expected {total_mac0}, got {actual_val0} at time {get_sim_time('ns')} ns"
        assert actual_val1 == total_mac1, f"Filter 1 Output mismatch: expected {total_mac1}, got {actual_val1} at time {get_sim_time('ns')} ns"
        assert actual_val2 == total_mac2, f"Filter 2 Output mismatch: expected {total_mac2}, got {actual_val2} at time {get_sim_time('ns')} ns"
        #assert actual_val2 == mac_sum2, f"Filter 1 Output mismatch: expected {mac_sum2}, got {actual_val2} at time {get_sim_time('ns')} ns"
        #print(f"Successful pass: mac_sum:{total_mac} i= {i}")



    



@pytest.mark.parametrize("linewidth_px_p", [14])
def test_conv2(linewidth_px_p):
    run_cocotb(
        "conv2",
        SOURCES,
        "test_conv2",
        {"linewidth_px_p": linewidth_px_p, "width_p": 8},
        tag=f"_L{linewidth_px_p}"
    )