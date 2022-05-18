#!/bin/bash -e
# This script simply returns 0 if the elaboration and linking phases are OK

ROOTDIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../..")

# Attempt to analyze the sources in Synopsys DC.
cd "$ROOTDIR/gf22fdx/synopsys"
synopsys-2016.03 dc_shell-xg-t -64 -f "scripts/go_link.tcl"
exit $?
