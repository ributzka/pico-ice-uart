YOSYS := $(shell which yosys)
NEXTPNR := $(shell which nextpnr-ice40)
ICEPACK := $(shell which icepack)
DFU_UTIL := $(shell which dfu-util)

RTL = $(wildcard rtl/*.sv)

.PHONY: all clean prog
all: gateware.bin

clean:
	$(RM) *.json *.asc *.bin
	$(RM) -r sim_build

prog: gateware.bin
	$(DFU_UTIL) -d 1209:b1c0 -a 0 -D gateware.bin -R

gateware.bin: $(RTL)
	$(YOSYS) -q -p "read_verilog -sv $(RTL); synth_ice40 -top top -json $*.json"
	$(NEXTPNR) -q --randomize-seed --up5k --package sg48 --pcf rtl/pico_ice.pcf --json $*.json --asc $*.asc
	$(ICEPACK) $*.asc $@

.SUFFIXES: .v .sv .asc .bin
