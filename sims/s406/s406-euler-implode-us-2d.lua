
log = Lucee.logInfo

-- physical parameters
gasGamma = 1.4

Lx = 0.3
Ly = 0.3

-- resolution and time-stepping
NX = 400
NY = 400
cfl = 0.2
tStart = 0.0
tEnd = 2.5
nFrames = 10

-- grid spacing (for use in finding out location of point)
dx = Lx/NX
dy = Ly/NY

------------------------------------------------
-- COMPUTATIONAL DOMAIN, DATA STRUCTURE, ETC. --
------------------------------------------------
-- decomposition object
decomp = DecompRegionCalc2D.CartGeneral {}
-- computational domain
grid = Grid.RectCart2D {
   lower = {0.0, 0.0},
   upper = {Lx, Ly},
   cells = {NX, NY},
   decomposition = decomp,
   periodicDirs = {},
}

-- solution
q = DataStruct.Field2D {
   onGrid = grid,
   numComponents = 5,
   ghost = {2, 2},
}
-- solution after update along X (ds algorithm)
qX = DataStruct.Field2D {
   onGrid = grid,
   numComponents = 5,
   ghost = {2, 2},
}
-- final updated solution
qNew = DataStruct.Field2D {
   onGrid = grid,
   numComponents = 5,
   ghost = {2, 2},
}
-- duplicate copy in case we need to take the step again
qDup = DataStruct.Field2D {
   onGrid = grid,
   numComponents = 5,
   ghost = {2, 2},
}
qNewDup = DataStruct.Field2D {
   onGrid = grid,
   numComponents = 5,
   ghost = {2, 2},
}

-- aliases to various sub-systems
fluid = q:alias(0, 5)
fluidX = qX:alias(0, 5)
fluidNew = qNew:alias(0, 5)

-----------------------
-- INITIAL CONDITION --
-----------------------
function getRhoPr(x, y)
   -- Implosion problem (Liska and Wendroff, Section 4.7)
   local rhoi, pri = 0.125, 0.14
   local rho0, pr0 = 1.0, 1.0

   local rho, pr = rho0, pr0
   if (x<0.15) then
      if (y<(0.15-x)) then
	 rho, pr = rhoi, pri
      end
   end
   return rho, pr
end

-- initial conditions
function init(x,y,z)
   -- averaging is used to determine values inside a cell: this is not
   -- strictly correct, as one should look at the fraction each fluid
   -- occupies the cell and then compute the averages
   local xl, xu = x+0.5*dx, x-0.5*dx
   local yl, yu = y+0.5*dy, y-0.5*dy

   local rho1, pr1 = getRhoPr(xl, yl)
   local rho2, pr2 = getRhoPr(xl, yu)
   local rho3, pr3 = getRhoPr(xu, yl)
   local rho4, pr4 = getRhoPr(xu, yu)
   
   --local rho = (rho1+rho2+rho3+rho4)/4.0
   --local pr = (pr1+pr2+pr3+pr4)/4.0

   local rho, pr = getRhoPr(x,y)

   return rho, 0.0, 0.0, 0.0, pr/(gasGamma-1)
end

------------------------
-- Boundary Condition --
------------------------
-- boundary applicator objects for fluids and fields

bcFluidCopy = BoundaryCondition.Copy { components = {0, 4} }
bcFluidWall = BoundaryCondition.ZeroNormal { components = {1, 2, 3} }

-- create boundary condition object to apply wall BCs
function createWallBc(myDir, myEdge)
   local bc = Updater.Bc2D {
      onGrid = grid,
      -- boundary conditions to apply
      boundaryConditions = {
	 bcFluidCopy, bcFluidWall,
      },
      -- direction to apply
      dir = myDir,
      -- edge to apply on
      edge = myEdge,
   }
   return bc
end

-- walls
bcLeft = createWallBc(0, "lower")
bcRight = createWallBc(0, "upper")
bcBottom = createWallBc(1, "lower")
bcTop = createWallBc(1, "upper")

-- function to apply boundary conditions to specified field
function applyBc(fld, tCurr, myDt)
   local bcList = {bcTop, bcBottom, bcLeft, bcRight}
   for i,bc in ipairs(bcList) do
      bc:setOut( {fld} )
      bc:advance(tCurr+myDt)
   end
   -- sync ghost cells
   fld:sync()
end

----------------------
-- EQUATION SOLVERS --
----------------------
-- regular Euler equations
eulerEqn = HyperEquation.Euler {
   gasGamma = gasGamma,
}
-- (Lax equations are used to fix negative pressure/density)
eulerLaxEqn = HyperEquation.Euler {
   gasGamma = gasGamma,
   numericalFlux = "lax",
}

-- ds solvers for regular Euler equations along X
fluidSlvr = Updater.WavePropagation2D {
   onGrid = grid,
   equation = eulerEqn,
   -- one of no-limiter, min-mod, superbee, 
   -- van-leer, monotonized-centered, beam-warming
   limiter = "monotonized-centered",
   cfl = cfl,
   cflm = 1.1*cfl,
}

-- ds solvers for Lax Euler equations along X
fluidLaxSlvr = Updater.WavePropagation2D {
   onGrid = grid,
   equation = eulerLaxEqn,
   limiter = "zero",
   cfl = cfl,
   cflm = 1.1*cfl,
}

-- function to update source terms
function updateSource(qIn, tCurr, t)
   -- do nothing
end

-- function to update the fluid and field using dimensional splitting
function updateFluidsAndField(tCurr, t)
   local myStatus = true
   local myDtSuggested = 1e3*math.abs(t-tCurr)
   local useLaxSolver = false

   -- update fluids
   for i,slvr in ipairs({fluidSlvr}) do
      slvr:setIn( {fluid} )
      slvr:setOut( {fluidNew} )
      slvr:setCurrTime(tCurr)
      local status, dtSuggested = slvr:advance(t)
      myStatus = status and myStatus
      myDtSuggested = math.min(myDtSuggested, dtSuggested)
   end

   if (myStatus == false) then
      return myStatus, myDtSuggested, useLaxSolver
   end

   if (eulerEqn:checkInvariantDomain(fluidNew) == false) then
      useLaxSolver = true
   end

   if ((myStatus == false) or (useLaxSolver == true)) then
      return myStatus, myDtSuggested, useLaxSolver
   end

   return myStatus, myDtSuggested, useLaxSolver
end

-- function to take one time-step with Euler solver
function solveTwoFluidSystem(tCurr, t)
   local dthalf = 0.5*(t-tCurr)

   -- update source terms
   updateSource(q, tCurr, tCurr+dthalf)
   applyBc(q, tCurr, t-tCurr)

   -- update fluids and fields
   local status, dtSuggested, useLaxSolver = updateFluidsAndField(tCurr, t)

   -- update source terms
   updateSource(qNew, tCurr, tCurr+dthalf)
   applyBc(qNew, tCurr, t-tCurr)

   return status, dtSuggested,useLaxSolver
end

-- function to update the fluid and field using dimensional splitting Lax scheme
function updateFluidsAndFieldLax(tCurr, t)
   local myStatus = true
   local myDtSuggested = 1e3*math.abs(t-tCurr)
   -- update fluids
   for i,slvr in ipairs({fluidLaxSlvr}) do
      slvr:setIn( {fluid} )
      slvr:setOut( {fluidNew} )
      slvr:setCurrTime(tCurr)
      local status, dtSuggested = slvr:advance(t)
      myStatus = status and myStatus
      myDtSuggested = math.min(myDtSuggested, dtSuggested)
   end

   return myStatus, myDtSuggested
end

-- function to take one time-step with Lax Euler solver
function solveTwoFluidLaxSystem(tCurr, t)
   local dthalf = 0.5*(t-tCurr)

   -- update source terms
   updateSource(q, tCurr, tCurr+dthalf)
   applyBc(q, tCurr, t-tCurr)

   -- update fluids and fields
   local status, dtSuggested = updateFluidsAndFieldLax(tCurr, t)

   -- update source terms
   updateSource(qNew, tCurr, tCurr+dthalf)
   applyBc(qNew, tCurr, t-tCurr)

   return status, dtSuggested
end

----------------------------
-- DIAGNOSIS AND DATA I/O --
----------------------------

-- dynvector to store fluid energy
fluidEnergy = DataStruct.DynVector { numComponents = 1 }
fluidEnergyCalc = Updater.IntegrateField2D {
   onGrid = grid,
   -- index of cell to record
   integrand = function (rho, rhou, rhov, rhow, er)
		  return er
	       end,
}
fluidEnergyCalc:setIn( {fluid} )
fluidEnergyCalc:setOut( {fluidEnergy} )

-- compute diagnostic
function calcDiagnostics(tCurr, myDt)
   for i,diag in ipairs({fluidEnergyCalc}) do
      diag:setCurrTime(tCurr)
      diag:advance(tCurr+myDt)
   end
end

-- write data to H5 files
function writeFields(frame, t)
   qNew:write( string.format("q_%d.h5", frame), t )
   fluidEnergy:write( string.format("fluidEnergy_%d.h5", frame) )
end

----------------------------
-- TIME-STEPPING FUNCTION --
----------------------------
function runSimulation(tStart, tEnd, nFrames, initDt)

   local frame = 1
   local tFrame = (tEnd-tStart)/nFrames
   local nextIOt = tFrame
   local step = 1
   local tCurr = tStart
   local myDt = initDt
   local status, dtSuggested
   local useLaxSolver = false

   -- the grand loop 
   while true do
      -- copy q and qNew in case we need to take this step again
      qDup:copy(q)
      qNewDup:copy(qNew)

      -- if needed adjust dt to hit tEnd exactly
      if (tCurr+myDt > tEnd) then
        myDt = tEnd-tCurr
      end

      -- advance fluids and fields
      if (useLaxSolver) then
        -- call Lax solver if positivity violated
        log (string.format(" Taking step %5d at time %6g with dt %g (using Lax solvers)", step, tCurr, myDt))
        status, dtSuggested = solveTwoFluidLaxSystem(tCurr, tCurr+myDt)
        useLaxSolver = false
      else
        log (string.format(" Taking step %5d at time %6g with dt %g", step, tCurr, myDt))
        status, dtSuggested, useLaxSolver = solveTwoFluidSystem(tCurr, tCurr+myDt)
      end

      if (status == false) then
        -- time-step too large
        log (string.format(" ** Time step %g too large! Will retake with dt %g", myDt, dtSuggested))
        myDt = dtSuggested
        qNew:copy(qNewDup)
        q:copy(qDup)
      elseif (useLaxSolver == true) then
        -- negative density/pressure occured
        log (string.format(" ** Negative pressure or density at %8g! Will retake step with Lax fluxes", tCurr+myDt))
        qNew:copy(qNewDup)
        q:copy(qDup)
      else
        -- check if a nan occured
        if (qNew:hasNan()) then
           log (string.format(" ** NaN occured at %g! Stopping simulation", tCurr))
           break
        end

        -- compute diagnostics
        calcDiagnostics(tCurr, myDt)
        -- copy updated solution back
        q:copy(qNew)
     
        -- write out data
        if (tCurr+myDt > nextIOt or tCurr+myDt >= tEnd) then
           log (string.format(" Writing data at time %g (frame %d) ...\n", tCurr+myDt, frame))
           writeFields(frame, tCurr+myDt)
           frame = frame + 1
           nextIOt = nextIOt + tFrame
           step = 0
        end
     
        tCurr = tCurr + myDt
        myDt = dtSuggested
        step = step + 1

        -- check if done
        if (tCurr >= tEnd) then
           break
        end
      end 
   end -- end of time-step loop
   
   return dtSuggested
end


----------------------------
-- RUNNING THE SIMULATION --
----------------------------
-- setup initial condition
q:set(init)

-- apply BCs on initial conditions
applyBc(q, 0.0, 0.0)
qNew:copy(q)

-- write initial conditions
calcDiagnostics(0.0, 0.0)
writeFields(0, 0.0)

initDt = 1.0
runSimulation(tStart, tEnd, nFrames, initDt)


