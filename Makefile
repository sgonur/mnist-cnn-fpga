HDL := $(wildcard src/hdl/*.v src/hdl/*.sv)
TOP ?= top

.PHONY: help test lint waves project bitstream clean

help:
	@echo "make test       run cocotb tests (Icarus)"
	@echo "make lint       lint RTL with Verilator"
	@echo "make project    create Vivado project in build/ and open the GUI"
	@echo "make bitstream  full Vivado build -> build/out/$(TOP).bit"
	@echo "make clean      delete generated files"

# pytest exits 5 when it finds no tests; treat that as a pass for an empty repo.
test:
	pytest tests/ -v $(PYTEST_ARGS); rc=$$?; [ $$rc -eq 5 ] && echo "No tests yet." && exit 0; exit $$rc

lint:
ifeq ($(strip $(HDL)),)
	@echo "No HDL in src/hdl yet, nothing to lint."
else
	verilator --lint-only -Wall -Isrc/hdl --top-module $(TOP) $(HDL)
endif

project:
	mkdir -p build
	vivado -mode gui -source scripts/create_project.tcl -journal build/vivado.jou -log build/vivado.log

bitstream:
	mkdir -p build
	vivado -mode batch -source scripts/build.tcl -journal build/vivado.jou -log build/vivado.log

clean:
	rm -rf build sim_build .pytest_cache tests/__pycache__ results.xml test-results.xml .Xil tests/*.result.xml
