from pylab import *
import tables

import pylab
from matplotlib import rcParams
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# customization for figure
#rcParams['lines.linewidth']            = 2
rcParams['font.size']                  = 18
#rcParams['xtick.major.size']           = 8 # default is 4
#rcParams['xtick.major.width']          = 3 # default is 0.5
#rcParams['ytick.major.size']           = 8 # default is 4
#rcParams['ytick.major.width']          = 3 # default is 0.5
rcParams['figure.facecolor']           = 'white'
#rcParams['figure.subplot.bottom']      = 0.125
#rcParams['figure.subplot.right']       = 0.85 # keep labels/ticks of colobar in figure
rcParams['image.interpolation']        = 'none'
rcParams['image.origin']               = 'lower'
rcParams['contour.negative_linestyle'] = 'solid'
#rcParams['savefig.bbox']               = 'tight'

# Math/LaTex fonts:
# http://matplotlib.org/users/mathtext.html
# http://matplotlib.org/users/usetex.html
# Example: xlabel(r'$t \cdot l / V_{A,bc}$')
rcParams['mathtext.default'] = 'regular' # match the font used for regular text

def colorbar_adj(obj, mode=1, redraw=False, _fig_=None, _ax_=None, aspect=None):
    '''
    Add a colorbar adjacent to obj, with a matching height
    For use of aspect, see http://matplotlib.org/api/axes_api.html#matplotlib.axes.Axes.set_aspect ; E.g., to fill the rectangle, try "auto"
    '''
    from mpl_toolkits.axes_grid1 import make_axes_locatable
    if mode == 1:
        _fig_ = obj.figure; _ax_ = obj.axes
    elif mode == 2: # assume obj is in the current figure/axis instance
        _fig_ = plt.gcf(); _ax_ = plt.gca()
    _divider_ = make_axes_locatable(_ax_)
    _cax_ = _divider_.append_axes("right", size="5%", pad=0.05)
    _cbar_ =  _fig_.colorbar(obj, cax=_cax_)
    if aspect != None:
        _ax_.set_aspect(aspect)
    if redraw:
        _fig_.canvas.draw()
    return _cbar_

from optparse import OptionParser
parser = OptionParser()
parser.add_option('-p', '--plot', action = 'store',
                  dest = 'fileName',
                  help = 'Hdf5 file to plot')

(options, args) = parser.parse_args()
fileName = options.fileName

gasGamma = 1.4

fh = tables.openFile(fileName)
grid = fh.root.StructGrid
nx, ny, nz = grid._v_attrs.vsNumCells[0], grid._v_attrs.vsNumCells[1], grid._v_attrs.vsNumCells[2]
lx, ly, lz = grid._v_attrs.vsUpperBounds[0], grid._v_attrs.vsUpperBounds[1], grid._v_attrs.vsUpperBounds[2]
dx = lx/nx
dz = lz/nz
Xe = linspace(0.0, lx, nx+1)
Ze = linspace(0.0, lz, nz+1)

Xc = linspace(0.5*dx, lx-0.5*dx, nx)
Zc = linspace(0.5*dz, lz-0.5*dz, nz)

q = fh.root.StructGridField
rho = q[:,:,:,0]
u = q[:,:,:,1]/rho
v = q[:,:,:,2]/rho
pr = (q[:,:,:,4] - 0.5*rho*(u**2+v**2))*(gasGamma-1)

# plot it
figure(1)
im = pcolormesh(Xe, Ze, transpose(pr[:,0,:]))
contour(Xc, Zc, transpose(pr[:,0,:]), 30, colors='k')
axis('image')
colorbar_adj(im)

show()
