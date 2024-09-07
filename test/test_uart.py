import os
from pathlib import Path
import warnings
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    from cocotb.runner import get_runner


async def receive_byte(dut, value, divider):
    # Start bit
    dut.rx_i.value = 0
    await ClockCycles(dut.clk_i, divider)

    # 8 Data bits
    for i in range(8):
        dut.rx_i.value = (value >> i) & 1
        await ClockCycles(dut.clk_i, divider)
    
    # Stop bit
    dut.rx_i.value = 1
    await ClockCycles(dut.clk_i, int(divider/2))


@cocotb.test()
async def uart(dut):
    divider = 50_000_000 // 115200
    cocotb.start_soon(Clock(dut.clk_i, 20, units="ns").start())
    dut.rst_ni.value = 0
    dut.rx_i.value = 1
    dut.data_i.value = 0
    dut.ready_i.value = 0
    dut.divider_i.value = divider
    await ClockCycles(dut.clk_i, 1)
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 1)

    await receive_byte(dut, 0x55, divider)
    await RisingEdge(dut.ready_o)
    await ClockCycles(dut.clk_i, 1)
    assert dut.data_o.value == 0x55

    dut.data_i.value = 0x55
    dut.ready_i.value = 1
    await ClockCycles(dut.clk_i, 1)
    dut.ready_i.value = 0
    await ClockCycles(dut.clk_i, divider)

    await receive_byte(dut, 0xaa, divider)
    await RisingEdge(dut.ready_o)
    await ClockCycles(dut.clk_i, 1)
    assert dut.data_o.value == 0xaa


def test_uart():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent / "rtl"

    sources = [proj_path / "uart.sv",
               proj_path / "uart_rx.sv",
               proj_path / "uart_tx.sv",
               proj_path / "fifo.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart",
        always=True,
        waves=True,
    )

    runner.test(hdl_toplevel="uart", test_module="test_uart", waves=True)


if __name__ == "__main__":
    test_uart()