import gkedgbasis
import gkedata
import gkedginterpdat
from pylab import *

import pylab
import tables
import math
import numpy
import pylab
import numpy
from matplotlib import rcParams
import matplotlib.pyplot as plt

# customization for figure
rcParams['lines.linewidth']            = 2
rcParams['font.size']                  = 18
rcParams['xtick.major.size']           = 8 # default is 4
rcParams['xtick.major.width']          = 3 # default is 0.5
rcParams['ytick.major.size']           = 8 # default is 4
rcParams['ytick.major.width']          = 3 # default is 0.5
rcParams['xtick.minor.size']           = 4 # default is 4
rcParams['xtick.minor.width']          = 0.5 # default is 0.5
rcParams['ytick.minor.size']           = 4 # default is 4
rcParams['ytick.minor.width']          = 0.5 # default is 0.5
rcParams['figure.facecolor']           = 'white'
#rcParams['figure.subplot.bottom']      = 0.125
#rcParams['figure.subplot.right']       = 0.85 # keep labels/ticks of colobar in figure
rcParams['image.interpolation']        = 'none'
rcParams['image.origin']               = 'lower'
#rcParams['contour.negative_linestyle'] = 'solid'
rcParams['savefig.bbox']               = 'tight'

# Math/LaTex fonts:
# http://matplotlib.org/users/mathtext.html
# http://matplotlib.org/users/usetex.html
# Example: xlabel(r'$t \cdot l / V_{A,bc}$')
rcParams['mathtext.default'] = 'regular' # match the font used for regular text

def getXv(Xc, Vc):
    dx = (Xc[0,-1]-Xc[0,0])/(Xc.shape[1]-1)
    dv = (Vc[-1,0]-Vc[0,0])/(Vc.shape[0]-1)

    X1 = linspace(Xc[0,0]+0.5*dx, Xc[0,-1]-0.5*dx, Xc.shape[1]-1)
    V1 = linspace(Vc[0,0]+0.5*dv, Vc[-1,0]-0.5*dv, Vc.shape[0]-1)

    return X1, V1

# density
d = gkedata.GkeData("s2-1x1v-mom_numDensity.h5")
dg1Num = gkedgbasis.GkeDgLobatto1DPolyOrder2Basis(d)
Xc, num = dg1Num.project(0)

Xhr = linspace(Xc[0], Xc[-1], 200) # for plotting

n = sin(2*pi*Xhr)
ux = 0.1*cos(2*pi*Xhr)
Txx = 0.75 + 0.25*cos(2*pi*Xhr)

# density
figure(1)
plot(Xc, num, 'ro-')
plot(Xhr, n, 'k-')
axis('tight')
xlabel('X')
ylabel('Number Density')
title('Number Density')
minorticks_on()
grid()
savefig('s2-1x1v-num.png', bbox='tight')

# momentum
d = gkedata.GkeData("s2-1x1v-mom_momDensity.h5")
dg1Mom = gkedgbasis.GkeDgLobatto1DPolyOrder2Basis(d)
Xc, mom = dg1Mom.project(0)

figure(2)
plot(Xc, mom, 'ro-')
plot(Xhr, n*ux, 'k-')
axis('tight')
xlabel('X')
ylabel('Momentum Density')
title('Momentum Density')
minorticks_on()
grid()
savefig('s2-1x1v-mom.png', bbox='tight')

# total Pxx
d = gkedata.GkeData("s2-1x1v-mom_pressureTensor.h5")
dg1Pr = gkedgbasis.GkeDgLobatto1DPolyOrder2Basis(d)
Xc, pr = dg1Pr.project(0)

figure(3)
plot(Xc, pr, 'ro-')
plot(Xhr, n*Txx + n*ux*ux, 'k-')
axis('tight')
xlabel('X')
ylabel(r'$P_{xx}$')
title(r'$P_{xx}$')
minorticks_on()
grid()
savefig('s2-1x1v-pr.png', bbox='tight')

# ptcl energy
d = gkedata.GkeData("s2-1x1v-mom_ptclEnergy.h5")
dg1Eg = gkedgbasis.GkeDgLobatto1DPolyOrder2Basis(d)
Xc, Eg = dg1Eg.project(0)

figure(4)
plot(Xc, Eg, 'ro-')
plot(Xhr, 0.5*(n*Txx + n*ux*ux), 'k-')
axis('tight')
xlabel('X')
ylabel(r'$Energy$')
title(r'Particle Energy')
minorticks_on()
grid()
savefig('s2-1x1v-Eg.png', bbox='tight')

show()
