-- Gkyl ------------------------------------------------------------------------
local Euler = require "Sim.EulerOnCartGrid"

-- gas adiabatic index
gasGamma = 1.4

-- create sim
eulerSim = Euler.Sim {
   logToFile = true, -- false if no log file is desired

   -- basic parameters
   tEnd = 0.7, -- end time
   nFrame = 2, -- number of output frame
   lower = {0.0, 0.0, 0.0}, -- lower left corner
   upper = {1.5, 1.5, 1.0}, -- upper right corner
   cells = {75, 75, 50}, -- number of cells
   cfl = 0.9, -- CFL number
   limiter = "monotonized-centered", -- limiter
   gasGamma = gasGamma, -- gas adiabatic index

   -- decomposition stuff
   decompCuts = {1, 1, 1}, -- cuts in each direction
   useShared = false, -- if to use shared memory

   -- initial condition
   init = function (t, xn)
      -- See Langseth and LeVeque, section 3.2
      local rhoi, pri = 1.0, 5.0
      local rho0, pr0 = 1.0, 1.0
      local rho, pr = rho0, pr0

      local r = math.sqrt(xn[1]^2+xn[2]^2+(xn[3]-0.4)^2)
      if r<0.2 then
	 rho, pr = rhoi, pri
      end
      
      return rho, 0.0, 0.0, 0.0, pr/(gasGamma-1)
   end,
   
   -- boundary conditions
   periodicDirs = {}, -- periodic directions
   bcx = { Euler.bcWall, Euler.bcCopy }, -- boundary conditions in X
   bcy = { Euler.bcWall, Euler.bcCopy }, -- boundary conditions in Y
   bcz = { Euler.bcWall, Euler.bcWall }, -- boundary conditions in Y   

   -- diagnostics
   diagnostics = { }
}
-- run simulation
eulerSim:run()
