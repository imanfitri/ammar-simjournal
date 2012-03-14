import pylab
import tables
import math
import numpy

def exactSol(a, b, X, Y):
    c1, d0 = 0, 0
    c0 = a/12.0 - 1.0/2.0
    d1 = b/12.0 - 1.0/2.0

    XX, YY = pylab.meshgrid(X, Y)
    return (XX**2/2 - a*XX**4/12 + c0*XX + c1)*(YY**2/2 - b*YY**4/12 + d0*YY + d1)

fh = tables.openFile("s85-poisson-2d_phi.h5")
q = fh.root.StructGridField
nx, ny, nc = q.shape
Xf = pylab.linspace(0, 1, nx)
Yf = pylab.linspace(0, 1, ny)

dx = Xf[1]-Xf[0]
dy = Yf[1]-Yf[0]
hsize = math.sqrt(dx*dy)

Xhr = pylab.linspace(0, 1, 101)
Yhr = pylab.linspace(0, 1, 101)
fhr = exactSol(2, 5, Xhr, Yhr)

# make plots
pylab.figure(1)
pylab.pcolormesh(Xf, Yf, pylab.transpose(q[:,:,0]))
pylab.axis('image')
pylab.colorbar()

pylab.figure(2)
pylab.pcolormesh(Xhr, Yhr, fhr)
pylab.axis('image')
pylab.colorbar()

pylab.show()
