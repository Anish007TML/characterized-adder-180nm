* =====================================================================
* fa_mirror28.sp  --  Transistor-level cells for the characterized adder
* Draw these in S-Edit (one schematic + symbol per .subckt), or include
* this file directly in T-Spice.
*
* Model names used:  nch  (NMOS)   pch  (PMOS)
* If your model library uses other names (e.g. NMOS/PMOS), either rename
* them here or pass --nmos/--pmos to scripts/gen_char_netlist.py.
* Channel length 0.18u (180 nm). Supply is a port (vdd/gnd).
* =====================================================================

* ---------------------------------------------------------------------
* FA_CORE24 : 24-transistor mirror adder core, NO output inverters
*   cob = NOT carry_out          sb = NOT sum
* Carry stage sized up (it sits on the critical path),
* sum stage left near minimum. The 'ci' transistors sit closest to the
* output node in both carry branches because ci arrives last.
* ---------------------------------------------------------------------
.subckt FA_CORE24 a b ci cob sb vdd gnd
* ---- carry stage, pull-down:  (a.b) + ci.(a+b) ----
Mn1  cob a   n1  gnd nch W=1.0u L=0.18u
Mn2  n1  b   gnd gnd nch W=1.0u L=0.18u
Mn3  cob ci  n2  gnd nch W=1.0u L=0.18u
Mn4  n2  a   gnd gnd nch W=1.0u L=0.18u
Mn5  n2  b   gnd gnd nch W=1.0u L=0.18u
* ---- carry stage, pull-up (mirror of the pull-down) ----
Mp1  p1  a   vdd vdd pch W=2.0u L=0.18u
Mp2  cob b   p1  vdd pch W=2.0u L=0.18u
Mp3  p2  a   vdd vdd pch W=2.0u L=0.18u
Mp4  p2  b   vdd vdd pch W=2.0u L=0.18u
Mp5  cob ci  p2  vdd pch W=2.0u L=0.18u
* ---- sum stage, pull-down:  (a.b.ci) + cob.(a+b+ci) ----
Mn6  sb  ci  n3  gnd nch W=0.75u L=0.18u
Mn7  n3  a   n4  gnd nch W=0.75u L=0.18u
Mn8  n4  b   gnd gnd nch W=0.75u L=0.18u
Mn9  sb  cob n5  gnd nch W=0.5u  L=0.18u
Mn10 n5  a   gnd gnd nch W=0.5u  L=0.18u
Mn11 n5  b   gnd gnd nch W=0.5u  L=0.18u
Mn12 n5  ci  gnd gnd nch W=0.5u  L=0.18u
* ---- sum stage, pull-up (mirror) ----
Mp6  p3  a   vdd vdd pch W=1.5u L=0.18u
Mp7  p4  b   p3  vdd pch W=1.5u L=0.18u
Mp8  sb  ci  p4  vdd pch W=1.5u L=0.18u
Mp9  p5  a   vdd vdd pch W=1.0u L=0.18u
Mp10 p5  b   vdd vdd pch W=1.0u L=0.18u
Mp11 p5  ci  vdd vdd pch W=1.0u L=0.18u
Mp12 sb  cob p5  vdd pch W=1.0u L=0.18u
.ends FA_CORE24

* ---------------------------------------------------------------------
* INV : output inverter used to restore polarity
* ---------------------------------------------------------------------
.subckt INV in out vdd gnd
Mn out in gnd gnd nch W=0.5u L=0.18u
Mp out in vdd vdd pch W=1.0u L=0.18u
.ends INV

* ---------------------------------------------------------------------
* FA_MIRROR28 : full 28T cell = core + 2 inverters (true co, s)
* cob and sb are also brought out so they can be probed.
* ---------------------------------------------------------------------
.subckt FA_MIRROR28 a b ci co s cob sb vdd gnd
Xcore a b ci cob sb vdd gnd FA_CORE24
Xic   cob co vdd gnd INV
Xis   sb  s  vdd gnd INV
.ends FA_MIRROR28

* ---------------------------------------------------------------------
* MUX2_TG : transmission-gate 2:1 mux for the carry-select adder
*   y = sel ? d1 : d0
* ---------------------------------------------------------------------
.subckt MUX2_TG d0 d1 sel y vdd gnd
Mni  selb sel gnd gnd nch W=0.5u L=0.18u
Mpi  selb sel vdd vdd pch W=1.0u L=0.18u
Mn0  y selb d0 gnd nch W=1.0u L=0.18u
Mp0  y sel  d0 vdd pch W=2.0u L=0.18u
Mn1  y sel  d1 gnd nch W=1.0u L=0.18u
Mp1  y selb d1 vdd pch W=2.0u L=0.18u
.ends MUX2_TG
