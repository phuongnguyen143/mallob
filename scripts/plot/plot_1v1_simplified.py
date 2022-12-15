#!/usr/bin/env python3
 
import matplotlib.pyplot as plt
import math
import sys


markers = ['o','x', '^']
colors = ['#377eb8', '#ff7f00', '#e41a1c', '#f781bf', '#a65628', '#4daf4a', '#984ea3', '#999999', '#dede00', '#377eb8']


labels = []
files = []
outfile = None
catagory_dict = dict()
catagory_dict["sat"] = dict() # contains map between formular id and values in x and y for sat instance
catagory_dict["unsat"] = dict() # same but for unsat instance
mallob_timeout = 300

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
                catagory_dict[cat][id] = [mallob_timeout, mallob_timeout]
                catagory_dict[cat][id][file_idx] = val


marker_idx = 0
for cat in catagory_dict.keys():
    x_values = []
    y_values = []
    id_values = []
    for id, values in catagory_dict[cat].items():
        id_values += [id]
        x_values += [values[0]]
        y_values += [values[1]]
    
    plt.scatter(x_values, y_values, color= colors[marker_idx], marker=markers[marker_idx], label = cat)
    for i,id in enumerate(id_values):
        text = plt.annotate(id, (x_values[i], y_values[i]))
        text.set_alpha(.6)
    marker_idx += 1

plt.plot(range(305), range(305), color='#dede00')

if heading:
    plt.title(heading)
if xlabel:
    plt.xlabel(xlabel)
if ylabel:
    plt.ylabel(ylabel)
plt.xlim(0, 305)
plt.ylim(0, 305)
plt.legend()
plt.grid(color='#dddddd', linestyle='-', linewidth=1)
plt.gca().set_aspect('equal')
if outfile:
    plt.savefig(outfile)
else:
    plt.show() 


