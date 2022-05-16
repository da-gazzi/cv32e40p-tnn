###########################################################################
#  Title      : insert core filler cells
#  Project    : gf 22 dz flow
##########################################################################
#  File       : fillcore-insert.tcl 
#  Author     : Beat Muheim  <muheim@ee.ethz.ch>
#  Company    : Microelectronics Design Center (DZ), ETH Zurich
##########################################################################
#  Description : Insert the io filler cells, the _H types left/right and 
#                the _V types top/bottom.
#  Inputs      : 
#  Outputs     :
#  Resources   :
##########################################################################
#  Copyright (c) 2016 Microelectronics Design Center, ETH Zurich
##########################################################################
# v0.1  - <muheim@ee.ethz.ch> - Wed Feb 26 17:02:44 CET 2020
#  - copy from the V04R40 are name 10M3S30P -> 10M3S40PI
##########################################################################

addIoFiller -cell {IN22FDX_GPIO18_10M3S40PI_FILL20_H IN22FDX_GPIO18_10M3S40PI_FILL10_H IN22FDX_GPIO18_10M3S40PI_FILL5_H IN22FDX_GPIO18_10M3S40PI_FILL1_H} -side left   -prefix fillperi
addIoFiller -cell {IN22FDX_GPIO18_10M3S40PI_FILL20_H IN22FDX_GPIO18_10M3S40PI_FILL10_H IN22FDX_GPIO18_10M3S40PI_FILL5_H IN22FDX_GPIO18_10M3S40PI_FILL1_H} -side right  -prefix fillperi
addIoFiller -cell {IN22FDX_GPIO18_10M3S40PI_FILL20_V IN22FDX_GPIO18_10M3S40PI_FILL10_V IN22FDX_GPIO18_10M3S40PI_FILL5_V IN22FDX_GPIO18_10M3S40PI_FILL1_V} -side top    -prefix fillperi
addIoFiller -cell {IN22FDX_GPIO18_10M3S40PI_FILL20_V IN22FDX_GPIO18_10M3S40PI_FILL10_V IN22FDX_GPIO18_10M3S40PI_FILL5_V IN22FDX_GPIO18_10M3S40PI_FILL1_V} -side bottom -prefix fillperi
redraw
