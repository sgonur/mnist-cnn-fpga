HDL := $(wildcard src/hdl/*.v src/hdl/*.sv)
TOP ?= top

.PHONY: help test lint waves project bitstream clean

help:
	@echo "make test       run cocotb tests (Icarus)"
	@echo "make lint       lint RTL with Verilator"
	@echo "make project    create Vivado project in build/ and open the GUI"
	@echo "make bitstream  full Vivado build -> build/out/$(TOP).bit"
	@echo "make clean      delete generated files"

test:
	pytest tests/ -v

lint:
	verilator --lint-only -Wall -Isrc/hdl --top-module $(TOP) $(HDL)

project:
	mkdir -p build
	vivado -mode gui -source scripts/create_project.tcl -journal build/vivado.jou -log build/vivado.log

bitstream:
	mkdir -p build
	vivado -mode batch -source scripts/build.tcl -journal build/vivado.jou -log build/vivado.log

clean:
	rm -rf build sim_build .pytest_cache tests/__pycache__ results.xml test-results.xml .Xil tests/*.result.xml
