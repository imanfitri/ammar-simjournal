-- Input file to solve 2D Poisson equations using FEM

-- polynomial order
polyOrder = 1

-- Determine number of global nodes per cell for use in creating
-- fields. Note that this looks a bit odd as this not the number of
-- *local* nodes but the number of nodes in each cell to give the
-- correct number of global nodes in fields.
if (polyOrder == 1) then
   numNodesPerCell = 1
elseif (polyOrder == 2) then
   numNodesPerCell = 3
end

grid = Grid.RectCart2D {
   lower = {0.0, 0.0},
   upper = {2*Lucee.Pi, 2*Lucee.Pi},
   cells = {128, 128},
}

-- create FEM nodal basis
basis = NodalFiniteElement2D.Serendipity {
   -- grid on which elements should be constructured
   onGrid = grid,
   -- polynomial order in each cell. One of 1, or 2. Corresponding
   -- number of nodes are 4 and 8.
   polyOrder = polyOrder,
}

-- source term
src = DataStruct.Field2D {
   onGrid = grid,
   location = "vertex", -- this will not work in general for polyOrder > 1
   -- numNodesPerCell is number of global nodes stored in each cell
   numComponents = 1*numNodesPerCell,
   ghost = {1, 1},
   -- ghost cells to write
   writeGhost = {0, 1} -- write extra layer on right to get nodes
}

-- function to initialize source
-- create updater to initialize source
initSrc = Updater.EvalOnNodes2D {
   onGrid = grid,
   -- basis functions to use
   basis = basis,
   -- are common nodes shared?
   shareCommonNodes = true,
   -- function to use for initialization
   evaluate = function (x,y,z,t)
		 local amn = {{0,10,0}, {10,0,0}, {10,0,0}}
		 local bmn = {{0,10,0}, {10,0,0}, {10,0,0}}
		 local t1, t2 = 0.0, 0.0
		 local f = 0.0
		 for m = 0,2 do
		    for n = 0,2 do
		       t1 = amn[m+1][n+1]*math.cos(m*x)*math.cos(n*y)
		       t2 = bmn[m+1][n+1]*math.sin(m*x)*math.sin(n*y)
		       f = f + -(m*m+n*n)*(t1+t2)
		    end
		 end
		 return f/50.0
	      end
}
initSrc:setOut( {src} )
-- initialize potential
initSrc:advance(0.0) -- time is irrelevant
-- write it to disk
src:write("src.h5")

-- field to store potential
phi = DataStruct.Field2D {
   onGrid = grid,
   location = "vertex", -- this will not work in general for polyOrder > 1
   -- numNodesPerCell is number of global nodes stored in each cell
   numComponents = 1*numNodesPerCell,
   ghost = {1, 1},
   -- ghost cells to write
   writeGhost = {0, 1} -- write extra layer on right to get nodes
}
-- clear out contents
phi:clear(0.0)

-- create updater to solve Poisson equation
poissonSlvr = Updater.FemPoisson2D {
   onGrid = grid,
   -- basis functions to use
   basis = basis,
   -- periodic directions
   periodicDirs = {0, 1},
}

-- set input output fields
poissonSlvr:setIn( {src} )
poissonSlvr:setOut( {phi} )

-- solve for potential (time is irrelevant here)
status, dtSuggested = poissonSlvr:advance(0.0)
-- check if solver converged
if (status == false) then
   Lucee.logError("Poisson solver failed to converge!")
end

-- output solution
phi:write("phi.h5")