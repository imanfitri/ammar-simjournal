-- Gkyl ------------------------------------------------------------------------
local Vlasov = require "App.VlasovOnCartGrid"

-- electron parameters
vDriftElc = 0.159
vtElc = 0.02
-- ion parameters
vDriftIon = 0.0
vtIon = 0.001
-- mass ratio
massRatio = 50.0

knumber = 1.0 -- wave-number
perturbation = 1.0e-6 -- distribution function perturbation

local function maxwellian1v(v, vDrift, vt)
   return 1/math.sqrt(2*math.pi*vt^2)*math.exp(-(v-vDrift)^2/(2*vt^2))
end

vlasovApp = Vlasov.App {
   logToFile = true,

   tEnd = 80.0, -- end time
   nFrame = 20, -- number of output frames
   lower = {0.0}, -- configuration space lower left
   upper = {1.0}, -- configuration space upper right
   cells = {16}, -- configuration space cells
   basis = "serendipity", -- one of "serendipity" or "maximal-order"
   polyOrder = 2, -- polynomial order
   timeStepper = "rk3", -- one of "rk2" or "rk3"

   -- decomposition for configuration space
   decompCuts = {1}, -- cuts in each configuration direction
   useShared = false, -- if to use shared memory

   -- boundary conditions for configuration space
   periodicDirs = {1}, -- periodic directions

   -- electrons
   elc = Vlasov.Species {
      charge = -1.0, mass = 1.0,
      -- velocity space grid
      lower = {-6.0*vDriftElc},
      upper = {6.0*vDriftElc},
      cells = {64},
      decompCuts = {1},
      -- initial conditions
      init = function (t, xn)
	 local x, v = xn[1], xn[2]
	 local fv = maxwellian1v(v, vDriftElc, vtElc)
	 return fv*(1+perturbation*math.cos(2*math.pi*knumber*x))
      end,
      evolve = true, -- evolve species?

      diagnosticMoments = { "M0", "M1i", "M2" }
   },

   -- ghost electrons
   elcGhost = Vlasov.Species {
      charge = -1.0, mass = 1.0,
      -- velocity space grid
      lower = {-6.0*vDriftElc},
      upper = {6.0*vDriftElc},
      cells = {64},
      decompCuts = {1},
      -- initial conditions
      init = function (t, xn)
	 local x, v = xn[1], xn[2]
	 local fv = maxwellian1v(v, -vDriftElc, vtElc)
	 return fv
      end,
      evolve = false, -- evolve species?

      diagnosticMoments = { "M0", "M1i", "M2" }
   },   

   -- electrons
   ion = Vlasov.Species {
      charge = 1.0, mass = massRatio,
      -- velocity space grid
      lower = {-32.0*vtIon},
      upper = {32.0*vtIon},
      cells = {64},
      decompCuts = {1},
      -- initial conditions
      init = function (t, xn)
	 local x, v = xn[1], xn[2]
	 return maxwellian1v(v, vDriftIon, vtIon)
      end,
      evolve = true, -- evolve species?

      diagnosticMoments = { "M0", "M1i", "M2" }
   },   

   -- field solver
   field = Vlasov.EmField {
      epsilon0 = 1.0, mu0 = 1.0,
      init = function (t, xn)
	 local Ex = -perturbation*math.sin(2*math.pi*knumber*xn[1])/(2*math.pi*knumber)
	 return 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
      end,
      evolve = true, -- evolve field?
   },
}
-- run application
vlasovApp:run()
