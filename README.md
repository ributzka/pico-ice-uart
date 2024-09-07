# PICO ICE UART

UART implementation in System Verilog for the pico-ice.

This project assumes the default firmware is installed, where the UART is forwarded from the host through the RP2040 to the ICE40.

The top level implementation file combines the UART receiver and transmitter with fifos and echoes every received byte back to the host. The lower 3 bits of the last recived byte are also used to control the RGB light on the board.

The tests can be run via `pytest test`.

Run `make prog` to program the FPGA.

## Prerequisites
```
$ brew install yosys
$ brew tap ktemkin/oss-fpga
$ brew install --HEAD icestorm yosys nextpnr-ice40
$ brew install python3
$ python3 -m venv venv
$ source ./venv/bin/activate
$ pip install pytest cocotb
```

## License
This project is licensed under the terms of the MIT license.