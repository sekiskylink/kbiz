#!/usr/bin/env python
import os
import sys

LOWER = 1993

f = open("./toyota.txt","r")
for l in f:
    x = l.strip().split(",")
    if len(x) < 3:
        pass
    else:
        #print x
        model = x[0]
        if '#' in model: continue
        car  = x[1]
        car = car.replace(" ", "\ ")
        year_range = x[2].split('-')
        #print year_range
        start = int(year_range[0])
        end = year_range[1]
        end = 2012 if end == 'present' else int(end)
        if start < LOWER:
            start = LOWER
        #print model, car, range(start,end+1)
        sub_dirs = ','.join(['%s'%i for i in range(start, end+1)])
        if start <> end:
            cmd = "mkdir -p %s/%s/{%s}" % (model,car,sub_dirs)
        else:
            cmd = "mkdir -p %s/%s/{%s,%s}" % (model,car,start,end)
        #print cmd
        try:
            #os.popen("mkdir -p %s/%s/{%s}" % (model,car,sub_dirs))
            os.popen(cmd)
            #print cmd
        except:
            print cmd
