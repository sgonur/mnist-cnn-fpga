# Recreate the Vivado project from the sources in the repo.
#
#   vivado -mode batch  -source scripts/create_project.tcl   # just create it
#   vivado -mode gui    -source scripts/create_project.tcl   # create and open
#
# The project lives in build/ and is disposable: delete it any time and rerun.
# Files are referenced in place (not copied), so edits in the GUI land in src/.

source [file join [file dirname [info script]] settings.tcl]

file delete -force $PROJ_DIR
create_project $PROJ_NAME $PROJ_DIR -part $PART

set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

# --- RTL ------------------------------------------------------------------
set hdl_files [concat \
    [glob -nocomplain [file join $REPO_ROOT src *.v]] \
    [glob -nocomplain [file join $REPO_ROOT src *.sv]] \
    [glob -nocomplain [file join $REPO_ROOT src *.vhd]]]
if {[llength $hdl_files] == 0} { error "No HDL found in src/" }
add_files -norecurse -fileset sources_1 $hdl_files

# --- Constraints ----------------------------------------------------------
set xdc_files [glob -nocomplain [file join $REPO_ROOT constraints *.xdc]]
if {[llength $xdc_files]} { add_files -norecurse -fileset constrs_1 $xdc_files }

# --- Vivado IP (optional): commit only the .xci, one folder per IP --------
set xci_files [glob -nocomplain [file join $REPO_ROOT ip * *.xci]]
if {[llength $xci_files]} {
    add_files -norecurse $xci_files
    upgrade_ip [get_ips] -quiet
    generate_target all [get_ips]
}

set_property top $TOP [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: Project created at $PROJ_DIR"
