import pylab
import tables
import math
import numpy

def projectOnFinerGrid(Xc, Yc, q):
    dx = Xc[1]-Xc[0]
    dy = Yc[1]-Yc[0]
    nx = Xc.shape[0]
    ny = Yc.shape[0]

    # mesh coordinates
    Xn = pylab.zeros((2*Xc.shape[0],), float)
    Xn[0:nx] = Xc-0.25*dx
    Xn[nx:] = Xc+0.25*dx
    Xn.sort()

    Yn = pylab.zeros((2*Yc.shape[0],), float)
    Yn[0:nx] = Yc-0.25*dx
    Yn[nx: ] = Yc+0.25*dx
    Yn.sort()

    qn = pylab.zeros((2*Xc.shape[0],2*Yc.shape[0]), float)

    # node 0
    for i in range(nx):
        for j in range(ny):
            qn[2*i,2*j] = 1/16.0*(9*q[i,j,0]+3*q[i,j,1]+3*q[i,j,3]+q[i,j,2])

    # node 1
    for i in range(nx):
        for j in range(ny):
            qn[2*i+1,2*j] = 1/16.0*(9*q[i,j,1]+3*q[i,j,2]+3*q[i,j,0]+q[i,j,3])

    # node 2
    for i in range(nx):
        for j in range(ny):
            qn[2*i+1,2*j+1] = 1/16.0*(9*q[i,j,2]+3*q[i,j,1]+3*q[i,j,3]+q[i,j,0])

    # node 3
    for i in range(nx):
        for j in range(ny):
            qn[2*i,2*j+1] = 1/16.0*(9*q[i,j,3]+3*q[i,j,2]+3*q[i,j,0]+q[i,j,1])

    return Xn, Yn, qn

def projectOnFinerGrid_f(Xc, Yc, q):
    dx = Xc[1]-Xc[0]
    dy = Yc[1]-Yc[0]
    nx = Xc.shape[0]
    ny = Yc.shape[0]

    # mesh coordinates
    Xn = pylab.zeros((2*Xc.shape[0],), float)
    Xn[0:nx] = Xc-0.25*dx
    Xn[nx:] = Xc+0.25*dx
    Xn.sort()

    Yn = pylab.zeros((2*Yc.shape[0],), float)
    Yn[0:nx] = Yc-0.25*dx
    Yn[nx: ] = Yc+0.25*dx
    Yn.sort()

    qn = pylab.zeros((2*Xc.shape[0],2*Yc.shape[0]), float)

    # node 0
    qn[0:2*nx:2, 0:2*ny:2] = 1/16.0*(9*q[:,:,0]+3*q[:,:,1]+3*q[:,:,3]+q[:,:,2])

    # node 1
    qn[1:2*nx:2, 0:2*ny:2] = 1/16.0*(9*q[:,:,1]+3*q[:,:,2]+3*q[:,:,0]+q[:,:,3])

    # node 2
    qn[1:2*nx:2, 1:2*ny:2] = 1/16.0*(9*q[:,:,2]+3*q[:,:,1]+3*q[:,:,3]+q[:,:,0])

    # node 3
    qn[0:2*nx:2, 1:2*ny:2] = 1/16.0*(9*q[:,:,3]+3*q[:,:,2]+3*q[:,:,0]+q[:,:,1])

    return Xn, Yn, qn

def evalSum(coeff, fields):
    res = 0.0*fields[0]
    for i in range(len(coeff)):
        res = res + coeff[i]*fields[i]
    return res

def projectOnFinerGrid_f39(Xc, Yc, q):
   dx = Xc[1]-Xc[0]
   dy = Yc[1]-Yc[0]
   nx = Xc.shape[0]
   ny = Yc.shape[0]

   # mesh coordinates
   Xn = pylab.linspace(Xc[0]-0.5*dx, Xc[-1]+0.5*dx, 3*nx+1) # one more
   Yn = pylab.linspace(Yc[0]-0.5*dy, Yc[-1]+0.5*dy, 3*ny+1) # one more
   XXn, YYn = pylab.meshgrid(Xn, Yn)

   # data
   qn = pylab.zeros((3*Xc.shape[0], 3*Yc.shape[0]), float)

   v1 = q[:,:,0]
   v2 = q[:,:,1]
   v3 = q[:,:,2]
   v4 = q[:,:,3]
   v5 = q[:,:,4]
   v6 = q[:,:,5]
   v7 = q[:,:,6]
   v8 = q[:,:,7]

   vList = [v1,v2,v3,v4,v5,v6,v7,v8]

   # node 1
   c1 = [.2314814814814815,-.1388888888888889,-.06481481481481481,-.1388888888888889,0.462962962962963,.09259259259259259,.09259259259259259,0.462962962962963]
   qn[0:3*nx:3, 0:3*ny:3] = evalSum(c1, vList)

   # node 2
   c2 = [-.1388888888888889,-.1388888888888889,-.1388888888888889,-.1388888888888889,.8333333333333334,.2777777777777778,.1666666666666667,.2777777777777778]
   qn[1:3*nx:3, 0:3*ny:3] = evalSum(c2, vList)

   # node 3
   c3 = [-.1388888888888889,.2314814814814815,-.1388888888888889,-.06481481481481481,0.462962962962963,0.462962962962963,.09259259259259259,.09259259259259259]
   qn[2:3*nx:3, 0:3*ny:3] = evalSum(c3, vList)

   # node 4
   c4 = [-.1388888888888889,-.1388888888888889,-.1388888888888889,-.1388888888888889,.2777777777777778,.1666666666666667,.2777777777777778,.8333333333333334]
   qn[0:3*nx:3, 1:3*ny:3] = evalSum(c4, vList)

   # node 5
   c5 = [-0.25,-0.25,-0.25,-0.25,0.5,0.5,0.5,0.5]
   qn[1:3*nx:3, 1:3*ny:3] = evalSum(c5, vList)

   # node 6
   c6 = [-.1388888888888889,-.1388888888888889,-.1388888888888889,-.1388888888888889,.2777777777777778,.8333333333333334,.2777777777777778,.1666666666666667]
   qn[2:3*nx:3, 1:3*ny:3] = evalSum(c6, vList)

   # node 7
   c7 = [-.1388888888888889,-.06481481481481481,-.1388888888888889,.2314814814814815,.09259259259259259,.09259259259259259,0.462962962962963,0.462962962962963]
   qn[0:3*nx:3, 2:3*ny:3] = evalSum(c7, vList)

   # node 8
   c8 = [-.1388888888888889,-.1388888888888889,-.1388888888888889,-.1388888888888889,.1666666666666667,.2777777777777778,.8333333333333334,.2777777777777778]
   qn[1:3*nx:3, 2:3*ny:3] = evalSum(c8, vList)

   # node 9
   c9 = [-.06481481481481481,-.1388888888888889,.2314814814814815,-.1388888888888889,.09259259259259259,0.462962962962963,0.462962962962963,.09259259259259259]
   qn[2:3*nx:3, 2:3*ny:3] = evalSum(c9, vList)
   
   return XXn, YYn, qn

fh = tables.openFile("s215-hw_chi_0.h5")
grid = fh.root.StructGrid
lower = grid._v_attrs.vsLowerBounds
upper = grid._v_attrs.vsUpperBounds
cells = grid._v_attrs.vsNumCells

xlo, ylo = lower[0], lower[1]
xup, yup = upper[0], upper[1]
nx, ny = cells[0], cells[1]

dx = (xup-xlo)/nx
dy = (yup-ylo)/ny

Xc = pylab.linspace(xlo+0.5*dx, xup-0.5*dx, nx)
Yc = pylab.linspace(ylo+0.5*dy, yup-0.5*dy, ny)

tEnd = 200.0
nFrame = 101

T = pylab.linspace(0, tEnd, nFrame)

vmax = []
vmin = []
for i in range(nFrame):
    fh = tables.openFile("s215-hw_chi_%d.h5" % i)
    q = fh.root.StructGridField.read()
    vmin.append(q.min())
    vmax.append(q.max())
    fh.close()

vmin.sort()
vmax.sort()
vvmin = vmin[0]
vvmax = vmax[len(vmax)-1]

for i in range(nFrame):
    print "Working on ", i
    fh = tables.openFile("s215-hw_chi_%d.h5" % i)
    q = fh.root.StructGridField

    Xn, Yn, qn = projectOnFinerGrid_f39(Xc, Yc, q) # projectOnFinerGrid_f(Xc, Yc, q)

    fig = pylab.figure(1)
    pylab.pcolormesh(Xn, Yn, pylab.transpose(qn))#, vmin=vvmin, vmax=vvmax)
    pylab.colorbar()
    vmin.append(qn.min())
    vmax.append(qn.max())
    pylab.axis('image')
    pylab.title('T=%f' % T[i])
    
    pylab.savefig('s215-hw_chi_%05d.png' % i)
    pylab.close()

    fh.close()

vmax = []
vmin = []
for i in range(nFrame):
    fh = tables.openFile("s215-hw_numDens_%d.h5" % i)
    q = fh.root.StructGridField.read()
    vmin.append(q.min())
    vmax.append(q.max())
    fh.close()

vmin.sort()
vmax.sort()
vvmin = vmin[0]
vvmax = vmax[len(vmax)-1]

for i in range(nFrame):
    print "Working on ", i
    fh = tables.openFile("s215-hw_numDens_%d.h5" % i)
    q = fh.root.StructGridField

    Xn, Yn, qn = projectOnFinerGrid_f39(Xc, Yc, q)

    fig = pylab.figure(1)
    pylab.pcolormesh(Xn, Yn, pylab.transpose(qn))#, vmin=vvmin, vmax=vvmax)
    pylab.colorbar()
    vmin.append(qn.min())
    vmax.append(qn.max())
    pylab.axis('image')
    pylab.title('T=%f' % T[i])
    
    pylab.savefig('s215-hw_numDens_%05d.png' % i)
    pylab.close()

    fh.close()

vmax = []
vmin = []
for i in range(nFrame):
    fh = tables.openFile("s215-hw_phi_%d.h5" % i)
    q = fh.root.StructGridField.read()
    vmin.append(q.min())
    vmax.append(q.max())
    fh.close()

vmin.sort()
vmax.sort()
vvmin = vmin[0]
vvmax = vmax[len(vmax)-1]

for i in range(nFrame):
    print "Working on ", i
    fh = tables.openFile("s215-hw_phi_%d.h5" % i)
    q = fh.root.StructGridField

    Xn, Yn, qn = projectOnFinerGrid_f39(Xc, Yc, q) # projectOnFinerGrid_f(Xc, Yc, q)

    fig = pylab.figure(1)
    pylab.pcolormesh(Xn, Yn, pylab.transpose(qn))#, vmin=vvmin, vmax=vvmax)
    pylab.colorbar()
    vmin.append(qn.min())
    vmax.append(qn.max())
    pylab.axis('image')
    pylab.title('T=%f' % T[i])
    
    pylab.savefig('s215-hw_phi_%05d.png' % i)
    pylab.close()

    fh.close()    
