-- Gkyl ------------------------------------------------------------------------
--
-- See http://gkyl.readthedocs.io/en/latest/gkyl/VlasovOnCartGrid.html
-- 
local Vlasov = require "App.VlasovOnCartGrid"

vlasovApp = Vlasov.App {
   logToFile = true,

   tEnd = 10.0, -- end time
   nFrame = 2, -- number of frames to write
   lower = {0.0}, -- configuration space lower left
   upper = {2*math.pi}, -- configuration space upper right
   cells = {32}, -- configuration space cells
   basis = "serendipity", -- one of "serendipity" or "maximal-order"
   polyOrder = 1, -- polynomial order
   timeStepper = "rk3", -- one of "rk2", "rk3" or "rk3s4"   

   -- decomposition for configuration space
   decompCuts = {1}, -- cuts in each configuration direction
   useShared = false, -- if to use shared memory

   -- boundary conditions for configuration space
   periodicDirs = {1}, -- periodic directions
   bcx = { }, -- boundary conditions in X

   -- electrons
   elc = Vlasov.Species {
      charge = -1.0, mass = 1.0,
      -- velocity space grid
      lower = {-6.0},
      upper = {6.0},
      cells = {16},
      decompCuts = {1},
      -- initial conditions
      init = function (t, xn)
	 local x, v = xn[1], xn[2]
	 return 1/math.sqrt(2*math.pi)*math.exp(-v^2/2)*math.cos(x)
      end,
      evolve = true, -- evolve species?

      -- diagnostics
      diagnosticMoments = {"M0", "M2"}
   },
}
-- run application
vlasovApp:run()
