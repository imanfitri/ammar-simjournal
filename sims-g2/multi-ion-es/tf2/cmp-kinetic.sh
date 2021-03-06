pgkyl -f tf2-shock_ion_10.bp -l "M" -f ../t2/t2-lbo-shock_ion_M0_10.bp dataset -i1 interp -p 2 -b ms ev -l "K" "f0 1836.2 *" dataset -i0,2 sel -c0 --c0 15.0:35.0 pl -f0 --xlabel "x" --ylabel "Density" --saveas "fluid-kin-cmp-ion.png" &

pgkyl -f tf2-shock_ion_50.bp -l "M" -f ../t2/t2-lbo-shock_ion_M0_50.bp dataset -i1 interp -p 2 -b ms ev -l "K" "f0 1836.2 *" dataset -i0,2 sel -c0 --c0 10.0:35.0 pl -f0 --xlabel "x" --ylabel "Density" --saveas "fluid-kin-cmp-ion.png" &
