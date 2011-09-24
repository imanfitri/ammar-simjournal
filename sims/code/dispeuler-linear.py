import numpy
import pylab
import tables
import optparse
import math

charge = 10.0
mass = 1.0
gasGamma = 2.0
Bz = 1.0
Lambda = charge/mass

rho0 = 1.0
p0 = 1.0
U0 = 1e-8
nModes = 9
cs0 = math.sqrt(gasGamma*p0/rho0)
wc = Lambda*Bz

def exactSol(X, t):
    u1 = 0*X
    U0 = 1e-8
    for n in range(10):
        kn = 2*math.pi*(2*n+1)
        wn = math.sqrt(kn*kn*cs0*cs0 + wc*wc)

        u1 = u1 - U0/(2*n+1)*numpy.sin(kn*X + wn*t)

    return u1

def main():
    parser = optparse.OptionParser()
    parser.add_option("-i", "--input", dest="input", help="Base name of Lua program")

    options, args = parser.parse_args()
    fileNm = options.input + "_q_1.h5"

    # open HDF5 file for reading
    fh = tables.openFile(fileNm)

    # create grid
    gridGrp = fh.root.StructGrid
    xlo = gridGrp._v_attrs.vsLowerBounds[0]
    xup = gridGrp._v_attrs.vsUpperBounds[0]
    nx = gridGrp._v_attrs.vsNumCells[0]
    dx = (xup-xlo)/nx
    X = pylab.linspace(xlo+0.5*dx, xup-0.5*dx, nx)

    dxExact = (xup-xlo)/1000
    Xex = pylab.linspace(xlo+0.5*dxExact, xup-0.5*dxExact, 1000)
    uEx = exactSol(Xex, 3.0)

    # make plots
    q = fh.root.StructGridField
    pylab.plot(X, q[:,1]/q[:,0], 'r-')
    pylab.plot(Xex, uEx, '-k')

    pylab.show()

if __name__ == '__main__': main()

