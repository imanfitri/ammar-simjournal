import os

for i in range(61):
    cmd = "/Users/ahakim/research/gkeyll-project/gkeyllall/gkeyll/scripts/gkeplot.py -p s240-gemguide-5m_q_%d.h5 -c 3 -t 'Electron out-of-plane current at t=%g' --dont-show --save -o s240-gemguide-5m_c3_%05d" % (i, i, i)
    print cmd
    os.system(cmd)

