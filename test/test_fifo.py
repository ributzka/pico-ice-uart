import os
from pathlib import Path
import warnings
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    from cocotb.runner import get_runner


@cocotb.test()
async def fifo(dut):
    dut._log.info("Start fifo test")

    # Set the clock period to 20 ns (50 MHz)
    clock = Clock(dut.clk_i, 20, units="ns")
    cocotb.start_soon(clock.start())

    #  Reset
    dut._log.info("Reset fifo")
    dut.rst_ni.value = 0
    dut.wr_en_i.value = 0
    dut.rd_en_i.value = 0
    dut.data_i.value = 0
    await ClockCycles(dut.clk_i, 1)
    dut.rst_ni.value = 1

    # Check fifo status
    dut._log.info("Check initial fifo status")
    await ClockCycles(dut.clk_i, 1)
    assert dut.full_o.value == 0, "fifo shouldn't be full"
    assert dut.empty_o.value == 1, "fifo isn't empty"

    dut._log.info("Check fifo operation")
    # Insert 1 element
    dut.wr_en_i.value = 1
    dut.data_i.value = 0xff
    await ClockCycles(dut.clk_i, 1)
    dut.wr_en_i.value = 0
    dut.data_i.value = 0
    await ClockCycles(dut.clk_i, 1)
    assert dut.full_o.value == 0, "fifo shouldn't be full"
    assert dut.empty_o.value == 0, "fifo shouldn't be empty"
   

    # Inser 15 elements
    dut.wr_en_i.value = 1
    for i in range(16):
        dut.data_i.value = i<<4 | i
        await ClockCycles(dut.clk_i, 1)
    
    dut.wr_en_i.value = 0
    await ClockCycles(dut.clk_i, 1)
    assert dut.full_o.value == 1, "fifo should be full"
    assert dut.empty_o.value == 0, "fifo shouldn't be empty"
   
    dut.rd_en_i.value = 1
    await ClockCycles(dut.clk_i, 1)
    
    await ClockCycles(dut.clk_i, 1)
    assert dut.full_o.value == 0
    assert dut.empty_o.value == 0
    assert dut.data_o.value == 0xff

    dut.wr_en_i.value = 1
    await ClockCycles(dut.clk_i, 1)
    assert dut.data_o.value == 0x00
    dut.wr_en_i.value = 0
    dut.rd_en_i.value = 0
    await ClockCycles(dut.clk_i, 1)
    assert dut.data_o.value == 0x11


def test_fifo():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent / "rtl"

    sources = [proj_path / "fifo.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="fifo",
        always=True,
        waves=True,
    )

    runner.test(hdl_toplevel="fifo", test_module="test_fifo", waves=True)


if __name__ == "__main__":
    test_fifo()