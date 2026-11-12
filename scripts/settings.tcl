# Single source of truth for project settings. Edit these, nothing else.

set VIVADO_VERSION "2025.1"            ;# everyone must use exactly this version
set PROJ_NAME      "fpga_project"
set PART           "xc7a35tcpg236-1"   ;# Basys 3 placeholder, change to your board
set TOP            "top"

set REPO_ROOT  [file normalize [file join [file dirname [info script]] ..]]
set BUILD_DIR  [file join $REPO_ROOT build]
set PROJ_DIR   [file join $BUILD_DIR $PROJ_NAME]

if {[version -short] ne $VIVADO_VERSION} {
    error "This repo targets Vivado $VIVADO_VERSION, but you are running [version -short]. \
Install the matching version (or update VIVADO_VERSION in scripts/settings.tcl as a team)."
}
