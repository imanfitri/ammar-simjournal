-- Gkyl ------------------------------------------------------------------------
--
--    _______     ___
-- + 6 @ |||| # P ||| +
--------------------------------------------------------------------------------

local Grid = require "Grid"
local DataStruct = require "DataStruct"
local Basis = require "Basis"
local Updater = require "Updater"

-- function encoding recovery stencil
local stencilFunc = {}
stencilFunc[0] = function (dt, dx, fOut, fL, f1, fR)
   fOut[1] = f1[1]-((fR[1]-fL[1])*dt)/(2*dx) 
end

stencilFunc[1] = function (dt, dx, fOut, fL, f1, fR)
   fOut[1] = f1[1]-dt*((-(0.5773502691896258*fR[2])/dx)-(0.5773502691896258*fL[2])/dx+(1.154700538379252*f1[2])/dx+(0.5*fR[1])/dx-(0.5*fL[1])/dx) 
   fOut[2] = f1[2]-dt*((-(1.0*fR[2])/dx)+fL[2]/dx+(0.8660254037844386*fR[1])/dx+(0.8660254037844386*fL[1])/dx-(1.732050807568877*f1[1])/dx)
end

stencilFunc[2] = function (dt, dx, fOut, fL, f1, fR)
   fOut[1] = f1[1]-dt*((0.489139870078079*fR[3])/dx-(0.489139870078079*fL[3])/dx-(0.7036456405748563*fR[2])/dx-(0.7036456405748563*fL[2])/dx+(1.407291281149713*f1[2])/dx+(0.5*fR[1])/dx-(0.5*fL[1])/dx) 
   fOut[2] = f1[2]-dt*((0.8472151069828725*fR[3])/dx+(0.8472151069828725*fL[3])/dx+(1.694430213965745*f1[3])/dx-(1.21875*fR[2])/dx+(1.21875*fL[2])/dx+(0.8660254037844386*fR[1])/dx+(0.8660254037844386*fL[1])/dx-(1.732050807568877*f1[1])/dx) 
   fOut[3] = f1[3]-dt*((1.09375*fR[3])/dx-(1.09375*fL[3])/dx-(1.573399484396763*fR[2])/dx-(1.573399484396763*fL[2])/dx-(4.599167723621307*f1[2])/dx+(1.118033988749895*fR[1])/dx-(1.118033988749895*fL[1])/dx)
end

stencilFunc[3] = function (dt, dx, fOut, fL, f1, fR)
   fOut[1] = f1[1]-dt*((-(0.3779644730092272*fR[4])/dx)-(0.3779644730092272*fL[4])/dx+(0.7559289460184544*f1[4])/dx+(0.6987712429686844*fR[3])/dx-(0.6987712429686844*fL[3])/dx-(0.7577722283113838*fR[2])/dx-(0.7577722283113838*fL[2])/dx+(1.515544456622768*f1[2])/dx+(0.5*fR[1])/dx-(0.5*fL[1])/dx) 
   fOut[2] = f1[2]-dt*((-(0.6546536707079771*fR[4])/dx)+(0.6546536707079771*fL[4])/dx+(1.210307295689818*fR[3])/dx+(1.210307295689818*fL[3])/dx+(2.420614591379636*f1[3])/dx-(1.3125*fR[2])/dx+(1.3125*fL[2])/dx+(0.8660254037844386*fR[1])/dx+(0.8660254037844386*fL[1])/dx-(1.732050807568877*f1[1])/dx) 
   fOut[3] = f1[3]-dt*((-(0.8451542547285166*fR[4])/dx)-(0.8451542547285166*fL[4])/dx+(1.690308509457033*f1[4])/dx+(1.5625*fR[3])/dx-(1.5625*fL[3])/dx-(1.694430213965745*fR[2])/dx-(1.694430213965745*fL[2])/dx-(4.357106264483343*f1[2])/dx+(1.118033988749895*fR[1])/dx-(1.118033988749895*fL[1])/dx) 
   fOut[4] = f1[4]-dt*((-(1.0*fR[4])/dx)+fL[4]/dx+(1.84877493221863*fR[3])/dx+(1.84877493221863*fL[3])/dx-(8.134609701761972*f1[3])/dx-(2.00487686654318*fR[2])/dx+(2.00487686654318*fL[2])/dx+(1.322875655532295*fR[1])/dx+(1.322875655532295*fL[1])/dx-(2.645751311064591*f1[1])/dx)
end

stencilFunc[4] = function (dt, dx, fOut, fL, f1, fR)
   fOut[1] = f1[1]-dt*((0.279296875*fR[5])/dx-(0.279296875*fL[5])/dx-(0.617883327946725*fR[4])/dx-(0.617883327946725*fL[4])/dx+(1.23576665589345*f1[4])/dx+(0.8123215699510955*fR[3])/dx-(0.8123215699510955*fL[3])/dx-(0.7870907966686697*fR[2])/dx-(0.7870907966686697*fL[2])/dx+(1.574181593337339*f1[2])/dx+(0.5*fR[1])/dx-(0.5*fL[1])/dx) 
   fOut[2] = f1[2]-dt*((0.4837563778952138*fR[5])/dx+(0.4837563778952138*fL[5])/dx+(0.9675127557904275*f1[5])/dx-(1.07020531715347*fR[4])/dx+(1.07020531715347*fL[4])/dx+(1.406982231239413*fR[3])/dx+(1.406982231239413*fL[3])/dx+(2.813964462478826*f1[3])/dx-(1.36328125*fR[2])/dx+(1.36328125*fL[2])/dx+(0.8660254037844386*fR[1])/dx+(0.8660254037844386*fL[1])/dx-(1.732050807568877*f1[1])/dx) 
   fOut[3] = f1[3]-dt*((0.6245267984032616*fR[5])/dx-(0.6245267984032616*fL[5])/dx-(1.381629123452673*fR[4])/dx-(1.381629123452673*fL[4])/dx+(2.763258246905345*f1[4])/dx+(1.81640625*fR[3])/dx-(1.81640625*fL[3])/dx-(1.75998852581561*fR[2])/dx-(1.75998852581561*fL[2])/dx-(4.225989640783614*f1[2])/dx+(1.118033988749895*fR[1])/dx-(1.118033988749895*fL[1])/dx) 
   fOut[4] = f1[4]-dt*((0.7389500732074931*fR[5])/dx+(0.7389500732074931*fL[5])/dx+(1.477900146414986*f1[5])/dx-(1.634765625*fR[4])/dx+(1.634765625*fL[4])/dx+(2.149200858704158*fR[3])/dx+(2.149200858704158*fL[3])/dx-(7.533757848790918*f1[3])/dx-(2.082446507213006*fR[2])/dx+(2.082446507213006*fL[2])/dx+(1.322875655532295*fR[1])/dx+(1.322875655532295*fL[1])/dx-(2.645751311064591*f1[1])/dx) 
   fOut[5] = f1[5]-dt*((0.837890625*fR[5])/dx-(0.837890625*fL[5])/dx-(1.853649983840175*fR[4])/dx-(1.853649983840175*fL[4])/dx-(12.16720789870719*f1[4])/dx+(2.436964709853287*fR[3])/dx-(2.436964709853287*fL[3])/dx-(2.361272390006008*fR[2])/dx-(2.361272390006008*fL[2])/dx-(5.669760065401246*f1[2])/dx+(1.5*fR[1])/dx-(1.5*fL[1])/dx)
end

-- function encoding computation of L2-norm of recovery polynomial
local l2Func = {}
l2Func[1] = function(dt, dx, fOut, fL, f1, fR)
   fOut[1] = 0.0248015873015873*fR[2]^2+0.004216269841269841*fL[2]*fR[2]+0.1024305555555556*f1[2]*fR[2]-0.04123930494211613*fR[1]*fR[2]+0.003866184838323386*fL[1]*fR[2]+0.03737312010379273*f1[1]*fR[2]+0.0248015873015873*fL[2]^2+0.1024305555555556*f1[2]*fL[2]-0.003866184838323386*fR[1]*fL[2]+0.04123930494211613*fL[1]*fL[2]-0.03737312010379273*f1[1]*fL[2]+0.6950532106782107*f1[2]^2-0.0858761662573043*fR[1]*f1[2]+0.0858761662573043*fL[1]*f1[2]+0.01715367965367965*fR[1]^2-0.003503787878787879*fL[1]*fR[1]-0.03080357142857143*f1[1]*fR[1]+0.01715367965367965*fL[1]^2-0.03080357142857143*f1[1]*fL[1]+0.5308035714285714*f1[1]^2 
end

l2Func[2] = function(dt, dx, fOut, fL, f1, fR)
   fOut[1] = 0.01843599109224109*fR[3]^2+0.003749603261322011*fL[3]*fR[3]-0.1280410019667832*f1[3]*fR[3]-0.05046557566936198*fR[2]*fR[3]+0.005608998141651638*fL[2]*fR[3]-0.06164784478023241*f1[2]*fR[3]+0.03481785366282316*fR[1]*fR[3]+0.004072675218134997*fL[1]*fR[3]-0.03889052888095815*f1[1]*fR[3]+0.01843599109224109*fL[3]^2-0.1280410019667832*f1[3]*fL[3]-0.005608998141651638*fR[2]*fL[3]+0.05046557566936198*fL[2]*fL[3]+0.06164784478023241*f1[2]*fL[3]+0.004072675218134997*fR[1]*fL[3]+0.03481785366282316*fL[1]*fL[3]-0.03889052888095815*f1[1]*fL[3]+0.9046950120192307*f1[3]^2+0.1769025275364576*fR[2]*f1[3]-0.1769025275364576*fL[2]*f1[3]-0.1227552943176718*fR[1]*f1[3]-0.1227552943176718*fL[1]*f1[3]+0.2455105886353435*f1[1]*f1[3]+0.03455854041791542*fR[2]^2-0.008310211923493174*fL[2]*fR[2]+0.08365674039502165*f1[2]*fR[2]-0.04770585205757525*fR[1]*fR[2]-0.006002800196720831*fL[1]*fR[2]+0.05370865225429606*f1[1]*fR[2]+0.03455854041791542*fL[2]^2+0.08365674039502165*f1[2]*fL[2]+0.006002800196720831*fR[1]*fL[2]+0.04770585205757525*fL[1]*fL[2]-0.05370865225429606*f1[1]*fL[2]+0.6152238061417749*f1[2]^2-0.0574118685397997*fR[1]*f1[2]+0.0574118685397997*fL[1]*f1[2]+0.01646790709290709*fR[1]^2+0.004323801198801199*fL[1]*fR[1]-0.03725961538461538*f1[1]*fR[1]+0.01646790709290709*fL[1]^2-0.03725961538461538*f1[1]*fL[1]+0.5372596153846154*f1[1]^2
end

l2Func[3] = function(dt, dx, fOut, fL, f1, fR)
   fOut[1] = 0.01205132757867133*fR[4]^2+0.00241121183503996*fL[4]*fR[4]+0.1289473709883866*f1[4]*fR[4]-0.04247087901024557*fR[3]*fR[4]+0.004592020944644976*fL[3]*fR[4]+0.0720643410936068*f1[3]*fR[4]+0.04428557069302497*fR[2]*fR[4]+0.005093544019969066*fL[2]*fR[4]+0.06140261764952451*f1[2]*fR[4]-0.02857774705665766*fR[1]*fR[4]+0.003402184443738929*fL[1]*fR[4]+0.02517556261291873*f1[1]*fR[4]+0.01205132757867133*fL[4]^2+0.1289473709883866*f1[4]*fL[4]-0.004592020944644976*fR[3]*fL[4]+0.04247087901024557*fL[3]*fL[4]-0.0720643410936068*f1[3]*fL[4]+0.005093544019969066*fR[2]*fL[4]+0.04428557069302497*fL[2]*fL[4]+0.06140261764952451*f1[2]*fL[4]-0.003402184443738929*fR[1]*fL[4]+0.02857774705665766*fL[1]*fL[4]-0.02517556261291873*f1[1]*fL[4]+1.13108117468469*f1[4]^2-0.2291422972503687*fR[3]*f1[4]+0.2291422972503687*fL[3]*f1[4]+0.2406464278801771*fR[2]*f1[4]+0.2406464278801771*fL[2]*f1[4]+0.5990743644847846*f1[2]*f1[4]-0.1559375763580447*fR[1]*f1[4]+0.1559375763580447*fL[1]*f1[4]+0.03743527522824398*fR[3]^2-0.008684159807206682*fL[3]*fR[3]-0.1261345804802836*f1[3]*fR[3]-0.07809926307759127*fR[2]*fR[3]-0.00958233411929634*fL[2]*fR[3]-0.1090506445693598*f1[2]*fR[3]+0.05040912400106744*fR[1]*fR[3]-0.006382582369943299*fL[1]*fR[3]-0.04402654163112413*f1[1]*fR[3]+0.03743527522824398*fL[3]^2-0.1261345804802836*f1[3]*fL[3]+0.00958233411929634*fR[2]*fL[3]+0.07809926307759127*fL[2]*fL[3]+0.1090506445693598*f1[2]*fL[3]-0.006382582369943299*fR[1]*fL[3]+0.05040912400106744*fL[1]*fL[3]-0.04402654163112413*f1[1]*fL[3]+0.741535130451146*f1[3]^2+0.130769112924392*fR[2]*f1[3]-0.130769112924392*fL[2]*f1[3]-0.08410103169444327*fR[1]*f1[3]-0.08410103169444327*fL[1]*f1[3]+0.1682020633888865*f1[1]*f1[3]+0.04074678576631702*fR[2]^2+0.01053173714306527*fL[2]*fR[2]+0.1144698563155594*f1[2]*fR[2]-0.05260992878528537*fR[1]*fR[2]+0.007000090761744347*fL[1]*fR[2]+0.04560983802354102*f1[1]*fR[2]+0.04074678576631702*fL[2]^2+0.1144698563155594*f1[2]*fL[2]-0.007000090761744347*fR[1]*fL[2]+0.05260992878528537*fL[1]*fL[2]-0.04560983802354102*f1[1]*fL[2]+0.642410470388986*f1[2]^2-0.07415496288619415*fR[1]*f1[2]+0.07415496288619415*fL[1]*f1[2]+0.01698361317501942*fR[1]^2-0.004647397957944833*fL[1]*fR[1]-0.02931982839209402*f1[1]*fR[1]+0.01698361317501942*fL[1]^2-0.02931982839209402*f1[1]*fL[1]+0.529319828392094*f1[1]^2
end

local App = function(tbl)
   -- read in stuff from input table
   local polyOrder = tbl.polyOrder
   local cflFrac = tbl.cflFrac and tbl.cflFrac or 1.0
   local tEnd = tbl.tEnd
   
   -- cfl number
   local cfl = cflFrac/(2*polyOrder+1)
   
   local grid = Grid.RectCart {
      lower = {tbl.extents[1]},
      upper = {tbl.extents[2]},
      cells = {tbl.nCell},
      periodicDirs = {1},
   }
   local basis = Basis.CartModalSerendipity { ndim = grid:ndim(), polyOrder = polyOrder }

   -- fields
   local fInit = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local fDiff = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local fL2 = DataStruct.Field {
      onGrid = grid,
      numComponents = 1,
      ghost = {1, 1},
   }   
   local f = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local fe = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local f1 = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local f2 = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }
   local fNew = DataStruct.Field {
      onGrid = grid,
      numComponents = basis:numBasis(),
      ghost = {1, 1},
   }

   -- to store integrate density
   local density = DataStruct.DynVector { numComponents = 1 }
   local fSquare = DataStruct.DynVector { numComponents = 1 }

   --------------
   -- Updaters --
   --------------

   local function writeData(frame, tm)
      f:write(string.format("f_%d.bp", frame), tm)
      density:write(string.format("density_%d.bp", frame), tm)
      fSquare:write(string.format("fSquare_%d.bp", frame), tm)
      fL2:write(string.format("fDiffL2_%d.bp", frame), tm)
   end

   local function applyBc(fld)
      fld:sync()
   end

   local initDist = Updater.ProjectOnBasis {
      onGrid = grid,
      basis = basis,
      evaluate = function (t, xn)
	 return tbl.init(t, xn)
      end
   }

   -- integrated density
   local densityCalc = Updater.CartFieldIntegratedQuantCalc {
      onGrid = grid,
      basis = basis,
      numComponents = 1,
      quantity = "V"
   }
   local fSquareCalc = Updater.CartFieldIntegratedQuantCalc {
      onGrid = grid,
      basis = basis,
      numComponents = 1,
      quantity = "V2"
   }

   -- meta-func
   local function makeStencilUpdateFunc(stencilFunc)
      return function(dt, fIn, fOut)
	 local dx = grid:dx(1)

	 local localRange = fIn:localRange()
	 local indexer = fIn:indexer()
      
	 -- loop over each cell, accumulating contributions
	 for i = localRange:lower(1), localRange:upper(1) do
	    local fInPtr1 = fIn:get(indexer(i))
	    local fInPtrL, fInPtrR = fIn:get(indexer(i-1)), fIn:get(indexer(i+1))
	    local fOutPtr = fOut:get(indexer(i))
	    -- just call stencil function to update solution
	    stencilFunc[polyOrder](dt, dx, fOutPtr, fInPtrL, fInPtr1, fInPtrR)
	 end
      end
   end   

   -- function to take a single forward Euler step
   local forwardEuler = makeStencilUpdateFunc(stencilFunc)
   -- function to compute L2 norm of solution
   local calcL2 = makeStencilUpdateFunc(l2Func)

   local function calcDiag(tm, fld)
      densityCalc:advance(tm, { fld }, { density })
      fSquareCalc:advance(tm, { fld }, { fSquare })
      fDiff:combine(1.0, fld, -1.0, fInit)
      calcL2(0.0, fDiff, fL2) 
   end

   -- apply ICs
   initDist:advance(0.0, {}, {f})
   applyBc(f)
   fInit:copy(f)
   calcDiag(0.0, f)
   writeData(0, 0.0)

   -- take a single time-step with RK3 method
   local function rk3(tCurr, dt, fIn, fOut)
      -- Stage 1
      forwardEuler(dt, fIn, f1)
      applyBc(f1)

      -- Stage 2
      forwardEuler(dt, f1, fe)
      f2:combine(3.0/4.0, fIn, 1.0/4.0, fe)
      applyBc(f2)

      -- Stage 3
      forwardEuler(dt, f2, fe)
      fOut:combine(1.0/3.0, fIn, 2.0/3.0, fe)
      applyBc(fOut)
   end

   -- run simulation with RK3
   return function ()
      local tCurr = 0.0
      local step = 1
      local dt = cfl*grid:dx(1)
      local isDone = false
      
      while not isDone do
	 if (tCurr+dt >= tEnd) then
	    isDone = true
	    dt = tEnd-tCurr
	 end
	 print(string.format("Step %d at time %g with dt %g ...", step, tCurr, dt))
	 rk3(tCurr, dt, f, fNew)
	 f:copy(fNew)
	 calcDiag(tCurr+dt, f) -- compute diagnostics
	 step = step+1
	 tCurr = tCurr+dt
      end
      writeData(1, tEnd)
   end
end

return App
