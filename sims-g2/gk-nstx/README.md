# Turbulence in NSTX-like SOL. Based on Shi thesis.

## Collisionless cases

- n1: L=4m case
- n1b: Same (just to rerun sim on Eddy)
- n2: Lower resolution version of n1; Same res in velocity space
- n3: p=2 version of n2. Slightly different resolution
- n4: Same as n2, except bigger cflFrac
- n5: n2 with positivity fixes
- n6: n5 with lower velocity resolution
- n7: n5 with even lower velocity resolution. Crashes!

## Collisional cases

- c2: Same as n2, but with LBO collisions. nuFrac = 0.1
- c3: Same as c2, but with LBO collisions. nuFrac = 0.5

## Scaling studies

- s1: Corresponds to n2. Run for 0.1 mu.s
