from pylab import *

figure(1)
# energy
fe = loadtxt("fieldEnergy")
pe = loadtxt("ptclEnergy")
te = fe[:,1] + pe[:,1]
plot(fe[:,0], te)
savefig("s183-total-energy.png")
print "Relative change in energy", (te[-1]-te[0])/te[0]

figure(2)
# momentum
pm = loadtxt("ptclMomentum")
ptclMom = pm[:,1]
plot(pm[:,0], ptclMom)
savefig("s183-total-momentum.png")
print "Relative change in momentum", (ptclMom[-1]-ptclMom[0])/ptclMom[0]

figure(3)
# num density in cell
pm = loadtxt("numDensityInCell")
plot(pm[:,0], pm[:,1])
savefig("s183-numDensityInCell.png")

show()
