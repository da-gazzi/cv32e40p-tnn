#!/usr/bin/env python

import json
import sys, os, glob
import subprocess
import re
import argparse
import matplotlib
import matplotlib.pyplot as plt
matplotlib.style.use('ggplot')

# this is the name of the top level module to extract information from the area report
TOP_LEVEL_MODULE = "pulpissimo"

# minimum size NAND2 cell area for gate-equivalent extraction (in um2)
NAND2_CELL_AREA = 0.199

# positions of data in report
RPT_INST       = 0
RPT_GLOBAL_ABS = 1
RPT_LOCAL_COMB = 3
RPT_LOCAL_SEQ  = 4
RPT_LOCAL_BBOX = 5

parser = argparse.ArgumentParser(description="Analyze synthesis timing results.")
parser.add_argument('timingrpt', metavar='timing.rpt', type=str, help="file containing the timing report")
parser.add_argument('--clock-period', default=2000, type=str, help="name of the top level module to extract information from the area report")
# parser.add_argument('--nand2-cell-area',  default=NAND2_CELL_AREA,  type=float, help="minimum size NAND2 cell area for gate-equivalent extraction (in um2)")
# parser.add_argument('--cutoff-area',  default=1000,  type=float, help="area below which elements are clamped down to single component")
# parser.add_argument('--exclude-cells', default=r"\bcluster_SNPS_CLOCK_GATE_HIGH_.*",  type=str, help="regular expression indicating the cells to be excluded")

args = parser.parse_args()

with open(args.timingrpt) as f:
    txt = f.readlines()

paths = []
curr = 0
for line in txt:
    try:
        if line.split()[0] == "Startpoint:":
            paths.append({})
            paths[curr]['start'] = line.split()[1]
        if line.split()[0] == "Endpoint:":
            paths[curr]['end'] = line.split()[1]
        if line.split()[0] == "Path" and line.split()[1] == "Group:":
            paths[curr]['group'] = line.split()[2]
        if line.split()[0] == "slack":
            if line.split()[1] == "(MET)":
                paths[curr]['met'] = True
            else:
                paths[curr]['met'] = False
            paths[curr]['slack'] = float(line.split()[-1])
            curr += 1
    except IndexError:
        pass

# save timing in JSON format
with open("reports/timing.json", "wb") as f:
    json.dump(paths, f, indent=4, sort_keys=True)

# use pandas for analysis
from pandas.io.json import json_normalize

# remove stuff < cutoff_area
timing = json_normalize(paths)
timing.plot(y='slack', x='group', kind='barh')
plt.show()
