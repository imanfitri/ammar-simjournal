from pylab import *
import gkedata
import gkedgbasis

for i in range(40,41):
    d = gkedata.GkeData("s4-em-shock_distfElc_%d.h5" % i)
    dg = gkedgbasis.GkeDgSerendipNorm3DPolyOrder2Basis(d)
    X, Y, Z, fv = dg.project(0)
    pcolormesh(transpose(fv[:,24,:]))
    axis('tight')
    colorbar()
    savefig('s4-em-shock_distfElc_X_VX_%05d.png' % i)
    close()
    d.close()
