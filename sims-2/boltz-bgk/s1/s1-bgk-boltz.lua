-- Neutral Boltzmann-BGK mode

----------------------------------
-- Problem dependent parameters --
----------------------------------

log = Lucee.logInfo

polyOrder = 2 -- polynomial order

-- problem dependent parameters
n0 = 1.0
u0 = 0.0
vThermal = 1.0

Lx = 1.0 -- domain size
mfp = 0.01*Lx -- mean-free path

-- collision frequency
nu = vThermal/mfp

tStart = 0.0 -- start time 
tEnd = 1.0
nFrames = 1

VL, VU = -6.0*vThermal, 6.0*vThermal -- velocity space extents

-- Resolution, time-stepping etc.
NX = 64
NV = 32

cfl = 0.5/(2*polyOrder+1)

-- print some diagnostics
log(string.format("tEnd = %g,  nFrames=%d", tEnd, nFrames))
log(string.format("Mean-free path = %g", nu))
log(string.format("Collision frequency = %g", nu))

------------------------------------------------
-- COMPUTATIONAL DOMAIN, DATA STRUCTURE, ETC. --
------------------------------------------------
-- decomposition object
phaseDecomp = DecompRegionCalc2D.CartProd { cuts = {1,1} }
confDecomp = DecompRegionCalc1D.SubCartProd2D {
   decomposition = phaseDecomp,
   collectDirections = {0},
}

-- phase space grid
phaseGrid = Grid.RectCart2D {
   lower = {0.0, VL},
   upper = {Lx, VU},
   cells = {NX, NV},
   periodicDirs = {0},
   decomposition = phaseDecomp,
}

-- configuration space grid
confGrid = Grid.RectCart1D {
   lower = {0.0},
   upper = {Lx},
   cells = {NX},
   periodicDirs = {0},
   decomposition = confDecomp,
}

-- phase-space basis functions
phaseBasis = NodalFiniteElement2D.SerendipityElement {
   onGrid = phaseGrid,
   polyOrder = polyOrder,
}
-- configuration-space basis functions
confBasis = NodalFiniteElement1D.LagrangeTensor {
   onGrid = confGrid,
   polyOrder = polyOrder,
   nodeLocation = "uniform",
}

-- distribution function for 
distf = DataStruct.Field2D {
   onGrid = phaseGrid,
   numComponents = phaseBasis:numNodes(),
   ghost = {1, 1},
}

-- extra fields for performing RK update
distfNew = DataStruct.Field2D {
   onGrid = phaseGrid,
   numComponents = phaseBasis:numNodes(),
   ghost = {1, 1},
}
distf1 = DataStruct.Field2D {
   onGrid = phaseGrid,
   numComponents = phaseBasis:numNodes(),
   ghost = {1, 1},
}

-- number density
numDensity = DataStruct.Field1D {
   onGrid = confGrid,
   numComponents = confBasis:numNodes(),
   ghost = {1, 1},
}
-- momentum
momentum = DataStruct.Field1D {
   onGrid = confGrid,
   numComponents = confBasis:numNodes(),
   ghost = {1, 1},
}
-- Electron particle energy
ptclEnergy = DataStruct.Field1D {
   onGrid = confGrid,
   numComponents = confBasis:numNodes(),
   ghost = {1, 1},
}

--------------------------------
-- INITIAL CONDITION UPDATERS --
--------------------------------

-- Maxwellian with number density 'n0', drift-speed 'vdrift' and
-- thermal speed 'vt' = \sqrt{T/m}, where T and m are species
-- temperature and mass respectively.
function maxwellian(n0, vdrift, vt, v)
   return n0/math.sqrt(2*Lucee.Pi*vt^2)*math.exp(-(v-vdrift)^2/(2*vt^2))
end

-- updater to initialize electron distribution function
initDistf = Updater.ProjectOnNodalBasis2D {
   onGrid = phaseGrid,
   basis = phaseBasis,
   -- are common nodes shared?
   shareCommonNodes = false, -- In DG, common nodes are not shared
   -- function to use for initialization
   evaluate = function(x,v,z,t)
      return maxwellian(n0, u0, vThermal, v)
   end
}

----------------------
-- EQUATION SOLVERS --
----------------------

-- Updater for electron Vlasov equation
vlasovSolver = Updater.NodalVlasov1X1V {
   onGrid = phaseGrid,
   phaseBasis = phaseBasis,
   confBasis = confBasis,
   cfl = cfl,
   charge = elcCharge,
   mass = elcMass,
}

-- Updater to compute electron number density
numDensityCalc = Updater.DistFuncMomentCalc1X1V {
   onGrid = phaseGrid,
   phaseBasis = phaseBasis,
   confBasis = confBasis,   
   moment = 0,
}

-- Updater to compute momentum
momentumCalc = Updater.DistFuncMomentCalc1X1V {
   onGrid = phaseGrid,
   phaseBasis = phaseBasis,
   confBasis = confBasis,
   moment = 1,
}

-------------------------
-- Boundary Conditions --
-------------------------
-- boundary applicator objects for fluids and fields

-- apply boundary conditions to distribution functions
function applyDistFuncBc(curr, dt, fld)
   for i,bc in ipairs({}) do
      runUpdater(bc, curr, dt, {}, {fld})
   end
   -- sync the distribution function across processors
   fld:sync()
end

----------------------------
-- DIAGNOSIS AND DATA I/O --
----------------------------

----------------------
-- SOLVER UTILITIES --
----------------------

-- generic function to run an updater
function runUpdater(updater, currTime, timeStep, inpFlds, outFlds)
   updater:setCurrTime(currTime)
   if inpFlds then
      updater:setIn(inpFlds)
   end
   if outFlds then
      updater:setOut(outFlds)
   end
   return updater:advance(currTime+timeStep)
end

-- function to calculate number density
function calcNumDensity(calculator, curr, dt, distfIn, numDensOut)
   return runUpdater(calculator, curr, dt, {distfIn}, {numDensOut})
end
-- function to calculate momentum density
function calcMomentum(calculator, curr, dt, distfIn, momentumOut)
   return runUpdater(calculator, curr, dt, {distfIn}, {momentumOut})
end

-- function to compute moments from distribution function
function calcMoments(curr, dt, distfIn, distfIonIn)
   -- number density
   calcNumDensity(numDensityCalc, curr, dt, distfIn, numDensity)
end

-- function to update Vlasov equation
function updateVlasovEqn(vlasovSlvr, curr, dt, distfIn, emIn, distfOut)
   return runUpdater(vlasovSlvr, curr, dt, {distfIn, emIn}, {distfOut})
end


-- function to compute diagnostics
function calcDiagnostics(tCurr, myDt)
   for i,diag in ipairs({}) do
      diag:setCurrTime(tCurr)
      diag:advance(tCurr+myDt)
   end
end

----------------------------
-- Time-stepping routines --
----------------------------

-- take single RK step
function rkStage(tCurr, dt, elcIn, ionIn, emIn, elcOut, ionOut, emOut)
   -- update distribution functions and homogenous Maxwell equations
   local st, dt = updateVlasovEqn(vlasovSolver, tCurr, dt, elcIn, emIn, elcOut)
   -- add contribution from BGK operator
   
   return st, dt
end

function rk3(tCurr, myDt)
   local myStatus, myDtSuggested
   -- RK stage 1
   myStatus, myDtSuggested = rkStage(tCurr, myDt, distf, distfIon, em, distf1, distf1Ion, em1)
   if (myStatus == false)  then
      return false, myDtSuggested
   end
   -- apply BC
   applyDistFuncBc(tCurr, dt, distf1)

   -- RK stage 2
   myStatus, myDtSuggested = rkStage(tCurr, myDt, distf1, distf1Ion, em1, distfNew, distfNewIon, emNew)
   if (myStatus == false)  then
      return false, myDtSuggested
   end
   distf1:combine(3.0/4.0, distf, 1.0/4.0, distfNew)
   -- apply BC
   applyDistFuncBc(tCurr, dt, distf1)

   -- RK stage 3
   myStatus, myDtSuggested = rkStage(tCurr, myDt, distf1, distf1Ion, em1, distfNew, distfNewIon, emNew)
   if (myStatus == false)  then
      return false, myDtSuggested
   end
   distf1:combine(1.0/3.0, distf, 2.0/3.0, distfNew)
   -- apply BC
   applyDistFuncBc(tCurr, dt, distf1)

   distf:copy(distf1)

   return true, myDtSuggested
end

-- make duplicates in case we need them
distfDup = distf:duplicate()

-- function to advance solution from tStart to tEnd
function runSimulation(tStart, tEnd, nFrames, initDt)
   local frame = 1
   local tFrame = (tEnd-tStart)/nFrames
   local nextIOt = tFrame
   local step = 1
   local tCurr = tStart
   local myDt = initDt
   local status, dtSuggested

   -- the grand loop 
   while true do
      distfDup:copy(distf)
      -- if needed adjust dt to hit tEnd exactly
      if (tCurr+myDt > tEnd) then
	 myDt = tEnd-tCurr
      end

      -- advance particles and fields
      log (string.format(" Taking step %5d at time %6g with dt %g", step, tCurr, myDt))
      status, dtSuggested = rk3(tCurr, myDt)
      if (status == false) then
	 -- time-step too large
	 log (string.format(" ** Time step %g too large! Will retake with dt %g", myDt, dtSuggested))
	 myDt = dtSuggested
	 distf:copy(distfDup)
      else
	 -- compute diagnostics
	 calcDiagnostics(tCurr, myDt)
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

-- Write out data frame 'frameNum' with at specified time 'tCurr'
function writeFields(frameNum, tCurr)
   -- distribution functions
   distf:write(string.format("distf_%d.h5", frameNum), tCurr)
   numDensity:write(string.format("numDensity_%d.h5", frameNum), tCurr)
   momentum:write(string.format("momentum_%d.h5", frameNum), tCurr)
   ptclEnergy:write(string.format("ptclEnergy_%d.h5", frameNum), tCurr)
end

----------------------------
-- RUNNING THE SIMULATION --
----------------------------

-- apply initial conditions for  and ion
runUpdater(initDistf, 0.0, 0.0, {}, {distf})

-- apply BCs
applyDistFuncBc(0.0, 0.0, distf)
-- compute initial diagnostics
calcDiagnostics(0.0, 0.0)
-- write out initial fields
writeFields(0, 0.0)

-- run the whole thing
initDt = tEnd
--runSimulation(tStart, tEnd, nFrames, initDt)

-- print some timing information
log(string.format("Total time in vlasov solver for electrons = %g", vlasovSolver:totalAdvanceTime()))
log(string.format("Total time moment computations = %g", momentumCalc:totalAdvanceTime()+numDensityCalc:totalAdvanceTime()))
