from pylab import *
import tables

import pylab
import numpy
from matplotlib import rcParams
import matplotlib.pyplot as plt


def getMeshGrid(grid):
    xl, yl = grid._v_attrs.vsLowerBounds
    xu, yu = grid._v_attrs.vsUpperBounds
    nx, ny = grid._v_attrs.vsNumCells
    dx = (xu-xl)/nx
    dy = (yu-yl)/ny
    X = linspace(xl+0.5*dx, xu-0.5*dx, nx)
    Y = linspace(yl+0.5*dy, yu-0.5*dy, ny)

    return meshgrid(X, Y)

def getXYMid(grid):
    xl, yl = grid._v_attrs.vsLowerBounds
    xu, yu = grid._v_attrs.vsUpperBounds

    return 0.5*(xl+xu), 0.5*(yl+yu)

# read s426 data
fh = tables.openFile("../s426/s426-is-coal_q_25.h5")
q26 = fh.root.StructGridField
X26, Y26 = getMeshGrid(fh.root.StructGrid)

xmid, ymid = getXYMid(fh.root.StructGrid)

# read s427 data
fh = tables.openFile("../s427/s427-is-coal_q_25.h5")
q27 = fh.root.StructGridField
X27, Y27 = getMeshGrid(fh.root.StructGrid)

def mkFig(XX, YY, dat, nm):
    f = figure(1)
    pcolormesh(XX, YY, dat.transpose())
    axis('tight')
    gca().set_xlim([-10,10])
    gca().set_ylim([-5,5])
    colorbar()
    savefig(nm)
    close()

mkFig(X26, Y26, q26[:,:,3], 's426-Jze-cmp.png')
mkFig(X27, Y27, q27[:,:,3], 's427-Jze-cmp.png')


