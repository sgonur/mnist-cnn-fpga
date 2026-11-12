# Full build: recreate project, synthesize, implement, write bitstream.
#
#   vivado -mode batch -source scripts/build.tcl
#
# Outputs land in build/out/: top.bit, reports, and an .xsa if needed later.

source [file join [file dirname [info script]] create_project.tcl]

set OUT_DIR [file join $BUILD_DIR out]
file mkdir $OUT_DIR

set jobs [expr {[info exists ::env(JOBS)] ? $::env(JOBS) : 4}]

launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { error "Synthesis failed" }

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "Implementation failed" }

open_run impl_1
report_timing_summary    -file [file join $OUT_DIR timing_summary.rpt]
report_utilization       -file [file join $OUT_DIR utilization.rpt]

# Fail the build on timing violations so nobody ships a bad bitstream.
set wns [get_property STATS.WNS [get_runs impl_1]]
if {$wns < 0} { error "Timing not met: WNS = $wns ns (see build/out/timing_summary.rpt)" }

set bit [lindex [glob [file join $PROJ_DIR $PROJ_NAME.runs impl_1 *.bit]] 0]
file copy -force $bit [file join $OUT_DIR $TOP.bit]

puts "INFO: Bitstream written to [file join $OUT_DIR $TOP.bit] (WNS = $wns ns)"
