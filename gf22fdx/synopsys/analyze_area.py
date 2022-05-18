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
NAND2_CELL_AREA = 1

# positions of data in report
RPT_INST       = 0
RPT_GLOBAL_ABS = 1
RPT_LOCAL_COMB = 3
RPT_LOCAL_SEQ  = 4
RPT_LOCAL_BBOX = 5
RPT_DESIGN     = 6

import numpy as np
def make_autopct(vs):
    def my_autopct(pct):
        total = np.sum(vs)
        v = int(round(pct*total/100.0))
        return '{p:.2f}% ({v:d}um2)'.format(p=pct,v=v)
    return my_autopct


def get_compound_local(node, key):
    if len(node['instances'].keys()) == 0:
        return float(node[key])
    else:
        local = float(node[key])
        for k in node['instances'].keys():
            inst = node['instances'][k]
            local += get_compound_local(inst, key)
        return local

def flatten_hierarchy(hierarchy, node):
    # find the node
    h = hierarchy
    for l in node:
        h = h[l]
    # create flat copy of the node
    flat = {
        'design'       : h['design'],
        'instances'  : [
            {
                'name' : 'own',
                'abs'  : float(h['global_abs']),
                'comb' : float(h['local_comb']),
                'seq'  : float(h['local_seq']),
                'bbox' : float(h['local_bbox'])
            }
        ]
    }
    for k in h['instances'].keys():
        inst = h['instances'][k]
        flat['instances'].append ({
            'name' : k,
            'abs'  : float(inst['global_abs']),
            'comb' : get_compound_local(inst, 'local_comb'),
            'seq'  : get_compound_local(inst, 'local_seq'),
            'bbox' : get_compound_local(inst, 'local_bbox')
        })
    return flat


parser = argparse.ArgumentParser(description="Analyze synthesis results.")
parser.add_argument('arearpt', metavar='area.rpt', type=str, help="file containing the area report")
parser.add_argument('--top-level-module', default=TOP_LEVEL_MODULE, type=str, help="name of the top level module to extract information from the area report")
parser.add_argument('--nand2-cell-area',  default=NAND2_CELL_AREA,  type=float, help="minimum size NAND2 cell area for gate-equivalent extraction (in um2)")
parser.add_argument('--cutoff-area',  default=5000,  type=float, help="area below which elements are clamped down to single component")
# parser.add_argument('--exclude-cells', default=r"\bcluster_SNPS_CLOCK_GATE_HIGH_.*",  type=str, help="regular expression indicating the cells to be excluded")

args = parser.parse_args()

with open(args.arearpt) as f:
    txt = f.readlines()

top_line = ""
filtered = []
preamble = True
conclusion = False
for line in txt:
    if preamble:
        try:
            # check if the first token is the top_level_module, this would end the preamble!
            if line.split()[0] == args.top_level_module:
                preamble = False
                top_line = line.split()
        except IndexError:
            # line is empty
            pass
    elif not conclusion:
        try:
            # if first char is '-', go to conclusion
            if line[0] == '-':
                conclusion = True
            else:
                filtered.append(line.split())
        except IndexError:
            # line is empty - shouldn't happen anyways
            pass
    else:
        break

# populate the hierarchy tree, starting from root (the top module)
hierarchy = {
    'design'     : top_line[RPT_DESIGN],
    'global_abs' : float(top_line[RPT_GLOBAL_ABS]) / args.nand2_cell_area,
    'local_comb' : float(top_line[RPT_LOCAL_COMB]) / args.nand2_cell_area,
    'local_seq'  : float(top_line[RPT_LOCAL_SEQ ]) / args.nand2_cell_area,
    'local_bbox' : float(top_line[RPT_LOCAL_BBOX]) / args.nand2_cell_area,
    'instances'  : {}
}
for inst in filtered:
    # decode hierarchy
    inst_name = inst[RPT_INST]
    inst_flat_hierarchy = inst_name.split('/')
    inst_name_proper = inst_flat_hierarchy[-1]
    # filter out undesired designs
    # m = re.match(args.exclude_cells, inst[RPT_DESIGN])
    m = False
    if not m:
        h = hierarchy
        # navigate the hiearchical tree
        for i in xrange(len(inst_flat_hierarchy)-1):
            try:
                h = h['instances'][inst_flat_hierarchy[i]]
            except KeyError:
                # create empty box
                h['instances'][inst_flat_hierarchy[i]] = {
                    'design'     : "RECOVERY",
                    'global_abs' : "0.0",
                    'local_comb' : "0.0",
                    'local_seq'  : "0.0",
                    'local_bbox' : "0.0",
                    'instances'  : {}
                }
                h = h['instances'][inst_flat_hierarchy[i]]
        try:
            h['instances'][inst_name_proper] = {
                'design'     : inst[RPT_DESIGN],
                'global_abs' : float(inst[RPT_GLOBAL_ABS]) / args.nand2_cell_area,
                'local_comb' : float(inst[RPT_LOCAL_COMB]) / args.nand2_cell_area,
                'local_seq'  : float(inst[RPT_LOCAL_SEQ ]) / args.nand2_cell_area,
                'local_bbox' : float(inst[RPT_LOCAL_BBOX]) / args.nand2_cell_area,
                'instances'  : {}
            }
        except IndexError:
            print inst

# save hierarchy in JSON format
with open("reports/area.json", "wb") as f:
    json.dump(hierarchy, f, indent=4, sort_keys=True)

flat = flatten_hierarchy(hierarchy, ['instances', 'soc_domain_i', 'instances', 'ulpsoc_i', 'instances', 'fc_subsystem_i'])
with open("reports/area_flat.json", "wb") as f:
    json.dump(flat, f, indent=4, sort_keys=True)

# use pandas for analysis
from pandas.io.json import json_normalize

# remove stuff < cutoff_area
top_area = json_normalize(flat, ['instances'])
other = top_area[top_area['bbox']+top_area['comb']+top_area['seq'] < args.cutoff_area].sum()
other['name'] = 'other'
top_area = top_area[top_area['bbox']+top_area['comb']+top_area['seq'] >= args.cutoff_area]
top_area = top_area.append(other, ignore_index=True)

vals = (top_area['comb']+top_area['seq']+top_area['bbox'])
print make_autopct(vals)
vals.plot(figsize=(12,12), kind='pie', labels=top_area['name'], autopct=make_autopct((vals)))
plt.savefig("reports/area.pdf", bbox_inches='tight')
plt.show()

