import os
from pathlib import Path
import warnings
import cocotb
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb.clock import Clock
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    from cocotb.runner import get_runner


async def receive_byte(dut, value):
    # Start bit
    dut.rx_i.value = 0
    await ClockCycles(dut.clk_i, 16)

    # 8 Data bits
    for i in range(8):
        dut.rx_i.value = (value >> i) & 1
        await ClockCycles(dut.clk_i, 16)
    
    # Stop bit
    dut.rx_i.value = 1
    await ClockCycles(dut.clk_i, 8)

@cocotb.test()
async def uart_rx(dut):
    cocotb.start_soon(Clock(dut.clk_i, 20, units="ns").start())
    dut.rst_ni.value = 0
    dut.rx_i.value = 1
    dut.divider_i.value = 15
    await ClockCycles(dut.clk_i, 1)
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 1)

    await receive_byte(dut, 0x55)
    await ClockCycles(dut.clk_i, 3)
    await FallingEdge(dut.clk_i)
    assert dut.ready_o.value == 1
    assert dut.data_o.value == 0x55
    await receive_byte(dut, 0xAA)
    await ClockCycles(dut.clk_i, 3)
    await FallingEdge(dut.clk_i)
    assert dut.ready_o.value == 1
    assert dut.data_o.value == 0xAA


def test_uart_rx():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent / "rtl"

    sources = [proj_path / "uart_rx.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_rx",
        always=True,
        waves=True,
    )

    runner.test(hdl_toplevel="uart_rx", test_module="test_uart_rx", waves=True)


if __name__ == "__main__":
    test_uart_rx()