#!/usr/bin/env python3
 
import matplotlib.pyplot as plt
import math
import sys

markers = ['^', 'o', 'x']
colors = ['#377eb8', '#ff7f00', '#e41a1c', '#f781bf', '#a65628', '#4daf4a', '#984ea3', '#999999', '#dede00', '#377eb8']

lim = 3600
out = 4000
border_lo = 0.001
border_hi = 5000

msize = 6
pltxsize = 5
pltysize = 5
xmin = None
xmax = None
ymin = None
ymax = None
y2 = None

files = []
runtime_maps = []
labels = []
xlabel = None
ylabel = None
max_id = -1
min_val = lim
heading = ""
outfile = None
sat = []
unsat = []

for arg in sys.argv[1:]:
    if arg.startswith("-l="):
        labels += [arg[3:]]
    elif arg.startswith("-h="):
        heading = arg[3:]
    elif arg.startswith("-size="):
        pltxsize = float(arg[6:])
        pltysize = float(arg[6:])
    elif arg.startswith("-xsize="):
        pltxsize = float(arg[7:])
    elif arg.startswith("-ysize="):
        pltysize = float(arg[7:])
    elif arg.startswith("-min="):
        border_lo = float(arg[5:])
    elif arg.startswith("-max="):
        border_hi = float(arg[5:])
    elif arg.startswith("-xlabel="):
        xlabel = arg[8:]
    elif arg.startswith("-ylabel="):
        ylabel = arg[8:]
    elif arg.startswith("-T="):
        lim = float(arg[3:])
        out = lim * 1.35
        border_hi = lim * 1.8
        min_val = lim
    elif arg.startswith("-y2="):
        y2 = float(arg[4:])
    elif arg.startswith("-o="):
        outfile = arg[3:]
    else:
        files += [arg]

if len(files) !=  2:
    print("Need exactly 2 files to compare")
    exit(1)

catagory_dict = dict()
catagory_dict["sat"] = dict() # contains map between formular id and values in x and y for sat instance
catagory_dict["unsat"] = dict() # same but for unsat instance
mallob_timeout = 300


for file_idx, file in enumerate(files):
    for line in open(file, 'r').readlines():
        words = line.rstrip().split(" ")
        id = int(words[0])
        val = float(words[1])
        cat = words[2]
        if cat == "sat" or cat == "unsat":
            if id in catagory_dict[cat]:
                catagory_dict[cat][id][file_idx] = val
            else:
                catagory_dict[cat][id] = [300, 300]
                catagory_dict[cat][id][file_idx] = val

print(catagory_dict)

marker_idx = 0
for cat in catagory_dict.keys():
    x_values = []
    y_values = []
    id_values = []
    for id, values in catagory_dict[cat].items():
        id_values += [id]
        x_values += [values[0]]
        y_values += [values[1]]
    
    plt.scatter(x_values, y_values, marker=markers[marker_idx])
    marker_idx += 1

plt.show()

