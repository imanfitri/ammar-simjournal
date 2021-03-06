import pylab
import math

def convergence(dx, err):
    for i in range(1, dx.shape[0]):
        od = (pylab.log(err[i]) - pylab.log(err[i-1]))/(pylab.log(dx[i]) - pylab.log(dx[i-1]))
        print od

def convergenceDt(dx, err):
    for i in range(2, dx.shape[0]):
        od = pylab.log(err[i-1]/err[i])/pylab.log(dx[i-1]/dx[i])
        print od 


print "Momentum convergence DG2 order with dx"
dat = pylab.loadtxt("momentum-error-dx.txt")
convergence(dat[:,0], dat[:,1])

print "Momentum convergence DG3 order with dx"
dat = pylab.loadtxt("momentum-error-o3-dx.txt")
convergence(dat[:,0], dat[:,1])

print "Energy convergence DG2 order with dt"
dat = pylab.loadtxt("energy-error-dt.txt")
convergence(dat[:,0], dat[:,1])

print "Energy convergence DG3 order with dt"
dat = pylab.loadtxt("energy-error-o3-dt.txt")
convergence(dat[:,0], dat[:,1])
