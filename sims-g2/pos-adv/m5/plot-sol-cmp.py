from pylab import *
import numpy
import postgkyl

style.use('../code/postgkyl.mplstyle')

# lineouts
d = postgkyl.GData("m5-2d-adv-dg_distf_0.bp")
dg = postgkyl.GInterpModal(d, 1, 'ms')
X, f0 = dg.interpolate(0)

d = postgkyl.GData("m5-2d-adv-dg_distf_1.bp")
dg = postgkyl.GInterpModal(d, 1, 'ms')
X, mf1 = dg.interpolate(0)

d = postgkyl.GData("../s5/s5-2d-adv-dg_distf_1.bp")
dg = postgkyl.GInterpModal(d, 1, 'ms')
X, sf1 = dg.interpolate(0)

figure(1)
ny = f0.shape[1]
plot(X[0], f0[:,ny/2], 'k', label='EX')
plot(X[0], mf1[:,ny/2], label='AL')
plot(X[0], sf1[:,ny/2], label='NL')
xlabel('X')
ylabel('f(X)')
legend(loc='best')
grid()

savefig('s5-m5-cmp.png', dpi=150)

# total |f0|

maf = loadtxt("m5-2d-adv-dg_absDist.txt")
saf = loadtxt("../s5/s5-2d-adv-dg_absDist.txt")

figure(2)
plot(maf[:,0], maf[:,1])
plot(saf[:,0], saf[:,1])
xlabel('Time [s]')
ylabel('sum |f_0| ')
grid()

savefig('s5-m5-f0-cmp.png', dpi=150)

# 2D plots
figure(3)

subplot(1,2,1)
pcolormesh(X[0], X[1], numpy.ma.masked_where(sf1<0, sf1))
axis('image')

subplot(1,2,2)
pcolormesh(X[0], X[1], numpy.ma.masked_where(mf1<0, mf1))
axis('image')

savefig('s5-m5-distf-cmp.png', dpi=150)

show()
